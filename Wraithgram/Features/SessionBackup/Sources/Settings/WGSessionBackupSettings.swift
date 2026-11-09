import Foundation
import WGCore

enum WGSessionBackupSettings {
    /// Back an account up whenever it signs in or its backup data changes. Off by default. Global:
    /// the Keychain copy is not tied to one account.
    static let auto = WGSetting<Bool>("sessionBackup.auto", default: false)

    static func declare() {
        let _ = WGSessionBackupSettings.auto
    }
}
