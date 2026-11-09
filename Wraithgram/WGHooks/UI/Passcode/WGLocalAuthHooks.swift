// The common «ask for the code» check of Wraithgram (Face ID / Touch ID / Telegram's passcode).
// The check itself lives in WGSecurity; features below it ask through this point.

import Foundation
import AccountContext
import WGCore

public enum WGLocalAuthHooks {
    /// Provider: runs the check for `reason` (`passcodeOnly`: only when a Telegram passcode is set, otherwise
    /// access is granted without any prompt) and calls the completion exactly once on the main thread,
    /// `true` once access is granted, `false` when it was refused or cancelled. The first handler wins.
    /// Main thread.
    public static let requestCheck = WGHookPoint<(AccountContext, String, Bool, @escaping (Bool) -> Void) -> Void>("localAuth.requestCheck")

    /// Asks the check; with no handler registered nothing can be checked, so access is refused.
    public static func authenticate(context: AccountContext, reason: String, passcodeOnly: Bool = false, completion: @escaping (Bool) -> Void) {
        guard let handler = WGLocalAuthHooks.requestCheck.handlers.first else {
            completion(false)
            return
        }
        handler(context, reason, passcodeOnly, completion)
    }
}
