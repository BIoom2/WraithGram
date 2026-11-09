// Compiled into TelegramUI (filegroup //Wraithgram/WGHooks:TelegramUIHookSources).

import Foundation
import UIKit
import TelegramCore

/// The re-sign build installs over the old Ghostgram (same bundle ID, see WGBuildResign.sh), which selected its
/// own alternate icon «Ghost». iOS keeps that choice and the old picture although the icon no longer exists in
/// this bundle, so the home screen and the notifications still show Ghostgram's ghost. Once the app is active
/// (iOS refuses the change before), an alternate icon this bundle does not declare is reset to the primary one.
enum WGAppIconRepair {
    private static var observer: NSObjectProtocol?

    /// Main thread, at launch.
    static func install() {
        guard WGAppIconRepair.observer == nil else {
            return
        }
        WGAppIconRepair.observer = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main, using: { _ in
            if let observer = WGAppIconRepair.observer {
                NotificationCenter.default.removeObserver(observer)
                WGAppIconRepair.observer = nil
            }
            WGAppIconRepair.resetUnknownAlternateIcon()
        })
    }

    private static func resetUnknownAlternateIcon() {
        let application = UIApplication.shared
        // Logged once per launch: the push badge showed Ghostgram's ghost on build 12 (2026-11-09).
        Logger.shared.log("WGAppIcon", "alternate icon: \(application.alternateIconName ?? "none (primary)"), supported \(application.supportsAlternateIcons)")
        guard application.supportsAlternateIcons, let current = application.alternateIconName else {
            return
        }
        let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any]
        let declared = (icons?["CFBundleAlternateIcons"] as? [String: Any]).map { Set($0.keys) } ?? []
        if declared.contains(current) {
            return
        }
        application.setAlternateIconName(nil, completionHandler: { error in
            Logger.shared.log("WGAppIcon", "reset of «\(current)» to the primary icon: \(error.map { "\($0)" } ?? "done")")
        })
    }
}
