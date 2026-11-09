import Foundation

/// Entry point of WGSessionBackup, «Бэкап аккаунтов» (Swiftgram Pro's "Session backup"): the signed-in
/// accounts are copied to the iOS Keychain and restored later without a login code. The Keychain
/// format is Swiftgram's, so copies written by the old client are read here.
public enum WGSessionBackupModule {
    /// Declares the setting, the menu row and the auto backup. Called once on the main thread from
    /// `WGFeatures.registerAll()`, before `WGHookRegistry.freeze()`.
    public static func register() {
        WGSessionBackupSettings.declare()
        WGSwiftgramRows.register()
        WGSessionBackupAuto.register()
    }
}
