import Foundation
import WGCore
import WGSettingsUI

/// The row in «Swiftgram › Pro» (`.swiftgramPro`): opens the backup screen after the passcode check.
enum WGSwiftgramRows {
    static func register() {
        WGMenuRegistry.register(WGMenuRow(
            id: "sessionBackup.open",
            section: .main(of: .swiftgramPro),
            order: 100,
            title: { WGStrings.SessionBackup.Menu.title },
            subtitle: { WGStrings.SessionBackup.Menu.subtitle },
            icon: .bundle("Chat/Context Menu/Lock"),
            kind: .action({ menuContext in
                WGSessionBackupAccess.open(context: menuContext.context, proceed: {
                    menuContext.push(wgMakeSessionBackupScreen(context: menuContext.context))
                })
            }),
            searchKeywords: { [WGStrings.SessionBackup.Menu.keywords] }
        ))
    }
}
