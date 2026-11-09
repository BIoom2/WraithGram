import Foundation
import WGCore
import WGSettingsUI
import WGAppearanceSettings

/// Rows of the «Swiftgram» → «Chat» tab that belong to the appearance feature.
enum WGSwiftgramRows {
    static func register() {
        // Applies to messages laid out after the change (reopen the chat); the scale is read in
        // ReactionButtonListComponent once per layout pass.
        WGMenuRegistry.register(WGMenuRow(
            id: "appearance.messages.smallReactions",
            section: .main(of: .swiftgramChat),
            order: 150,
            title: { WGStrings.Appearance.Messages.smallReactions },
            kind: .toggle(.global(WGAppearanceSettings.smallReactions)),
            searchKeywords: { [WGStrings.Appearance.Messages.smallReactionsKeywords] }
        ))
    }
}
