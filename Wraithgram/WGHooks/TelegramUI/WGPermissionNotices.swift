// Compiled into TelegramUI (filegroup //Wraithgram/WGHooks:TelegramUIHookSources).

import Foundation
import Contacts
import UserNotifications
import SwiftSignalKit
import TelegramCore
import TelegramNotices
import TelegramPermissions

/// Telegram asks for contacts and notifications access in a splash after sign-in, and records in the
/// account manager that it did (`ApplicationSpecificNotice.permissionWarning`, 0 = handled). The account
/// manager lives in the App Group, but access is granted per app: an install that reuses another app's
/// data (a re-signed build that got the same App Group, e.g. Wraithgram next to the old Ghostgram) reads
/// "handled" and never asks, so iOS never shows the prompt. Once per install, a permission iOS has not
/// asked about yet gets its notice set back to "pending", and Telegram's own splash shows it.
enum WGPermissionNotices {
    private static let checkedKey = "wg.permissionNotices.checkedThisInstall"

    /// Main thread, once the account context exists.
    static func resetForThisInstallIfNeeded(accountManager: AccountManager<TelegramAccountManagerTypes>) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: WGPermissionNotices.checkedKey) {
            return
        }
        // UserDefaults.standard is per app, so this runs once per install, whatever the shared data says.
        defaults.set(true, forKey: WGPermissionNotices.checkedKey)

        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            WGPermissionNotices.markPending(.contacts, accountManager: accountManager)
        }
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            if settings.authorizationStatus == .notDetermined {
                WGPermissionNotices.markPending(.notifications, accountManager: accountManager)
            }
        })
    }

    /// 1 is what Telegram itself writes for a permission it is about to ask for (ApplicationContext).
    private static func markPending(_ permission: PermissionKind, accountManager: AccountManager<TelegramAccountManagerTypes>) {
        guard let key = ApplicationSpecificNotice.permissionWarningKey(permission: permission) else {
            return
        }
        let _ = (accountManager.noticeEntry(key: key)
        |> take(1)).start(next: { entry in
            if let value = entry.value.flatMap({ ApplicationSpecificNotice.getTimestampValue($0) }), value == 0 {
                ApplicationSpecificNotice.setPermissionWarning(accountManager: accountManager, permission: permission, value: 1)
            }
        })
    }
}
