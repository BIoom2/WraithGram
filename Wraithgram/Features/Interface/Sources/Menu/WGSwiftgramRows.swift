import Foundation
import WGCore
import WGSettingsUI

/// Rows of the «Swiftgram» → «Список чатов» tab that belong to the interface feature.
enum WGInterfaceSwiftgramRows {
    static func register() {
        // Only meaningful while the strip is at the bottom; applies at once (the folder key of the theme changes).
        WGMenuRegistry.register(WGMenuRow(
            id: "interface.folders.bottomStyle",
            section: .main(of: .swiftgramChatList),
            order: 250,
            title: { WGStrings.Interface.Menu.foldersStyle },
            kind: .choice(.global(InterfaceSettings.foldersBottomStyle), options: [
                WGMenuChoiceOption(value: "glass", title: { WGStrings.Interface.Menu.foldersStyleGlass }),
                WGMenuChoiceOption(value: "flat", title: { WGStrings.Interface.Menu.foldersStyleFlat })
            ]),
            isVisible: { _ in InterfaceSettings.foldersAtBottom.value }
        ))
    }
}
