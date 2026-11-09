import Foundation
import WGCore
import WGHooks
import AccountContext

/// The passcode gate of the backup screen: with a Telegram passcode set the screen opens only after
/// the passcode (or Face ID / Touch ID, as Telegram itself unlocks); with none it opens directly.
/// The check is the common one of «Безопасность», reached through `WGLocalAuthHooks`.
enum WGSessionBackupAccess {
    static func open(context: AccountContext, proceed: @escaping () -> Void) {
        WGLocalAuthHooks.authenticate(context: context, reason: WGStrings.SessionBackup.Auth.reason, passcodeOnly: true, completion: { granted in
            if granted {
                proceed()
            }
        })
    }
}
