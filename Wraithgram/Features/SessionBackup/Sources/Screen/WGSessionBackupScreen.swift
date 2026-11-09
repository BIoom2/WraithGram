import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import ItemListUI
import PresentationDataUtils
import AlertUI
import UndoUI
import WGCore

private enum WGSessionBackupEntry: ItemListNodeEntry {
    case autoToggle(Bool, String, String)
    case autoInfo(String)
    case sessionsHeader(String)
    case session(Int, WGSessionBackupSession, String, String)
    case empty(String)
    case backup(String)
    case restore(String)
    case deleteAll(String, Bool)
    case notice(String)

    var section: ItemListSectionId {
        switch self {
        case .autoToggle, .autoInfo:
            return 0
        case .sessionsHeader, .session, .empty:
            return 1
        case .backup, .restore, .deleteAll:
            return 2
        case .notice:
            return 3
        }
    }

    var stableId: Int {
        switch self {
        case .autoToggle:
            return 0
        case .autoInfo:
            return 1
        case .sessionsHeader:
            return 2
        case let .session(index, _, _, _):
            return 100 + index
        case .empty:
            return 99
        case .backup:
            return 1000
        case .restore:
            return 1001
        case .deleteAll:
            return 1002
        case .notice:
            return 1003
        }
    }

    static func <(lhs: WGSessionBackupEntry, rhs: WGSessionBackupEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WGSessionBackupArguments
        switch self {
        case let .autoToggle(value, title, _):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.setAuto(value)
            })
        case let .autoInfo(text), let .notice(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .sessionsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .session(_, session, title, state):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: state, additionalDetailLabel: WGSessionBackupEntry.dateText(session.date), sectionId: self.section, style: .blocks, disclosureStyle: .none, action: {
                arguments.openSession(session)
            })
        case let .empty(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .backup(title):
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: title, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.backup()
            })
        case let .restore(title):
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: title, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.restore()
            })
        case let .deleteAll(title, enabled):
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: title, kind: enabled ? .destructive : .disabled, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.deleteAll()
            })
        }
    }

    static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return WGStrings.SessionBackup.lastBackup(date: formatter.string(from: date))
    }
}

private final class WGSessionBackupArguments {
    let setAuto: (Bool) -> Void
    let openSession: (WGSessionBackupSession) -> Void
    let backup: () -> Void
    let restore: () -> Void
    let deleteAll: () -> Void

    init(setAuto: @escaping (Bool) -> Void, openSession: @escaping (WGSessionBackupSession) -> Void, backup: @escaping () -> Void, restore: @escaping () -> Void, deleteAll: @escaping () -> Void) {
        self.setAuto = setAuto
        self.openSession = openSession
        self.backup = backup
        self.restore = restore
        self.deleteAll = deleteAll
    }
}

/// «Бэкап аккаунтов»: the auto switch, the sessions in the Keychain and the actions on them. The
/// list is rebuilt from the account records (the signed-in state), the setting and a refresh
/// counter that every Keychain write bumps. Nothing from the Keychain is kept in the screen.
func wgMakeSessionBackupScreen(context: AccountContext) -> ViewController {
    let sharedContext = context.sharedContext
    let refresh = ValuePromise<Int>(0, ignoreRepeated: false)
    let refreshCounter = Atomic<Int>(value: 0)
    let bump: () -> Void = {
        refresh.set(refreshCounter.modify { $0 + 1 })
    }

    var presentController: ((ViewController) -> Void)?
    let toast: (String) -> Void = { text in
        let presentationData = sharedContext.currentPresentationData.with { $0 }
        sharedContext.mainWindow?.present(UndoOverlayController(presentationData: presentationData, content: .info(title: nil, text: text, timeout: nil, customUndoText: nil), elevatedLayout: false, action: { _ in
            return false
        }), on: .root)
    }
    let confirm: (String?, String, String, @escaping () -> Void) -> Void = { title, text, confirmTitle, action in
        let presentationData = sharedContext.currentPresentationData.with { $0 }
        presentController?(textAlertController(context: context, title: title, text: text, actions: [
            TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {}),
            TextAlertAction(type: .destructiveAction, title: confirmTitle, action: action)
        ]))
    }

    let arguments = WGSessionBackupArguments(setAuto: { value in
        WGSessionBackupSettings.auto.set(value)
    }, openSession: { session in
        let presentationData = sharedContext.currentPresentationData.with { $0 }
        let name = session.name ?? WGStrings.SessionBackup.Sessions.unnamed
        let actionSheet = ActionSheetController(presentationData: presentationData)
        var items: [ActionSheetItem] = [ActionSheetTextItem(title: name, parseMarkdown: false)]
        items.append(ActionSheetButtonItem(title: WGStrings.SessionBackup.Actions.deleteOne, color: .destructive, action: { [weak actionSheet] in
            actionSheet?.dismissAnimated()
            confirm(WGStrings.SessionBackup.DeleteOne.title, WGStrings.SessionBackup.DeleteOne.text(name: name), WGStrings.SessionBackup.Actions.deleteOne, {
                WGSessionBackupService.delete(peerId: session.peerId, completion: {
                    bump()
                })
            })
        }))
        if session.isLoggedIn {
            items.append(ActionSheetButtonItem(title: WGStrings.SessionBackup.Actions.removeFromApp, color: .destructive, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
                confirm(WGStrings.SessionBackup.RemoveFromApp.title, WGStrings.SessionBackup.RemoveFromApp.text(name: name), WGStrings.SessionBackup.RemoveFromApp.confirm, {
                    WGSessionBackupService.removeFromApp(sharedContext: sharedContext, peerId: session.peerId, completion: { success in
                        if !success {
                            toast(WGStrings.SessionBackup.Result.failed)
                        }
                        bump()
                    })
                })
            }))
        }
        actionSheet.setItemGroups([
            ActionSheetItemGroup(items: items),
            ActionSheetItemGroup(items: [
                ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                    actionSheet?.dismissAnimated()
                })
            ])
        ])
        presentController?(actionSheet)
    }, backup: {
        WGSessionBackupService.backupAll(sharedContext: sharedContext, completion: { count, allWritten in
            toast(allWritten ? WGStrings.SessionBackup.Result.backedUp(count: count) : WGStrings.SessionBackup.Result.failed)
            bump()
        })
    }, restore: {
        WGSessionBackupService.restore(accountManager: sharedContext.accountManager, completion: { count in
            toast(count > 0 ? WGStrings.SessionBackup.Result.restored(count: count) : WGStrings.SessionBackup.Result.nothingToRestore)
            bump()
        })
    }, deleteAll: {
        confirm(WGStrings.SessionBackup.DeleteAll.title, WGStrings.SessionBackup.DeleteAll.text, WGStrings.SessionBackup.DeleteAll.confirm, {
            WGSessionBackupService.deleteAll(completion: {
                bump()
            })
        })
    })

    let sessions: Signal<[WGSessionBackupSession], NoError> = combineLatest(queue: .mainQueue(), sharedContext.accountManager.accountRecords(), refresh.get())
    |> mapToSignal { view, _ -> Signal<[WGSessionBackupSession], NoError> in
        return WGSessionBackupService.sessions(records: view.records)
    }

    let signal = combineLatest(queue: .mainQueue(), sharedContext.presentationData, WGSettingsStore.shared.revision, WGLocalization.shared.languageCodeSignal, sessions)
    |> map { presentationData, _, _, sessions -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var entries: [WGSessionBackupEntry] = []
        entries.append(.autoToggle(WGSessionBackupSettings.auto.value, WGStrings.SessionBackup.Auto.title, WGStrings.SessionBackup.Auto.info))
        entries.append(.autoInfo(WGStrings.SessionBackup.Auto.info))
        entries.append(.sessionsHeader(WGStrings.SessionBackup.Sessions.header))
        if sessions.isEmpty {
            entries.append(.empty(WGStrings.SessionBackup.Sessions.empty))
        }
        for (index, session) in sessions.enumerated() {
            let state = session.isLoggedIn ? WGStrings.SessionBackup.State.loggedIn : WGStrings.SessionBackup.State.loggedOut
            entries.append(.session(index, session, session.name ?? WGStrings.SessionBackup.Sessions.unnamed, state))
        }
        entries.append(.backup(WGStrings.SessionBackup.Actions.backup))
        entries.append(.restore(WGStrings.SessionBackup.Actions.restore))
        entries.append(.deleteAll(WGStrings.SessionBackup.Actions.deleteAll, !sessions.isEmpty))
        entries.append(.notice(WGStrings.SessionBackup.notice))

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(WGStrings.SessionBackup.Screen.title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentController = { [weak controller] value in
        controller?.present(value, in: .window(.root))
    }
    return controller
}
