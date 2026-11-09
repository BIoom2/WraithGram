import Foundation
import WGCore
import WGSettingsUI
import WGFeaturesShared

/// Rows of the «Swiftgram › Сеть» tab that belong to this module.
enum WGNetworkSpoofSwiftgramRows {
    static func register() {
        WGMenuRegistry.register(WGMenuRow(
            id: "networkSpoof.noGoogleDns",
            section: .main(of: .swiftgramNetwork),
            order: 300,
            title: { WGStrings.NetworkSpoof.Menu.noGoogleDns },
            subtitle: { WGStrings.NetworkSpoof.Menu.noGoogleDnsInfo },
            kind: .toggle(.global(WGNetworkSpoofSharedSettings.noGoogleDns))
        ))
    }
}
