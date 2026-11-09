import Foundation
import SwiftSignalKit
import AccountContext
import WGCore
import WGHooks

/// «Автобэкап»: while the switch is on, every change of the account records is checked. The record
/// of an account gets its backup data at sign-in and whenever `SharedAccountContext
/// .updateAccountBackupData` refreshes it, so one observer of the records covers both; an account
/// is written only when it has no copy yet or its backup data differs from the stored one.
/// A copy is never deleted here: a normal logout leaves it in the Keychain for a later restore.
enum WGSessionBackupAuto {
    private static var started = false
    private static var disposable: Disposable?

    static func register() {
        WGLifecycleHooks.rootControllersDidLoad.register({ context, _ in
            WGSessionBackupAuto.start(sharedContext: context.sharedContext)
        })
    }

    /// Once, from the first account's root controllers (main thread).
    private static func start(sharedContext: SharedAccountContext) {
        if WGSessionBackupAuto.started {
            return
        }
        WGSessionBackupAuto.started = true
        WGSessionBackupAuto.disposable = (combineLatest(queue: .mainQueue(), WGSessionBackupSettings.auto.signal, sharedContext.accountManager.accountRecords())
        |> deliverOnMainQueue).start(next: { isOn, view in
            if isOn {
                WGSessionBackupService.autoBackup(records: view.records, sharedContext: sharedContext)
            }
        })
    }
}
