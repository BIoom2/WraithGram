import Foundation
import WGCore

// The fixed part of the menu (PLAN §2, FOUNDATION_SPEC §5.1): six categories, every tab with its
// «кнопка с подписью», and the sections features register their rows into. Each tab gets two
// sections: `<tab>.preview` (order 100) and `<tab>.main` (order 200); features add more as needed.

extension WGMenuCategory {
    public var title: String {
        switch self {
        case .privacy:
            return WGStrings.Menu.Category.privacy
        case .messages:
            return WGStrings.Menu.Category.messages
        case .media:
            return WGStrings.Menu.Category.media
        case .appearance:
            return WGStrings.Menu.Category.appearance
        case .security:
            return WGStrings.Menu.Category.security
        case .swiftgram:
            return WGStrings.Menu.Category.swiftgram
        case .more:
            return WGStrings.Menu.Category.more
        }
    }

    public var subtitle: String {
        switch self {
        case .privacy:
            return WGStrings.Menu.Category.privacyInfo
        case .messages:
            return WGStrings.Menu.Category.messagesInfo
        case .media:
            return WGStrings.Menu.Category.mediaInfo
        case .appearance:
            return WGStrings.Menu.Category.appearanceInfo
        case .security:
            return WGStrings.Menu.Category.securityInfo
        case .swiftgram:
            return WGStrings.Menu.Category.swiftgramInfo
        case .more:
            return WGStrings.Menu.Category.moreInfo
        }
    }

    public var icon: WGMenuIcon {
        switch self {
        case .privacy:
            return .ghost
        case .messages:
            return .bundle("Chat/Context Menu/Message")
        case .media:
            return .bundle("Chat/Context Menu/Image")
        case .appearance:
            return .bundle("Chat/Context Menu/Customize")
        case .security:
            return .bundle("Chat/Context Menu/Lock")
        case .swiftgram:
            return .bundle("Chat/Context Menu/Stars")
        case .more:
            return .bundle("Chat/Context Menu/More")
        }
    }
}

extension WGMenuTabID {
    // Privacy
    public static let privacyGhostExceptions = WGMenuTabID("privacy.ghostExceptions")
    public static let privacySendDelay = WGMenuTabID("privacy.sendDelay")
    public static let privacySpoofing = WGMenuTabID("privacy.spoofing")
    public static let privacyAnonymousMode = WGMenuTabID("privacy.anonymousMode")
    // Messages
    public static let messagesAntiDelete = WGMenuTabID("messages.antiDelete")
    public static let messagesRestrictions = WGMenuTabID("messages.restrictions")
    public static let messagesSending = WGMenuTabID("messages.sending")
    public static let messagesTranslation = WGMenuTabID("messages.translation")
    public static let messagesMenuGestures = WGMenuTabID("messages.menuGestures")
    public static let messagesExport = WGMenuTabID("messages.export")
    // Media and calls
    public static let mediaVoice = WGMenuTabID("media.voice")
    public static let mediaCameraVideoMessages = WGMenuTabID("media.cameraVideoMessages")
    public static let mediaCalls = WGMenuTabID("media.calls")
    public static let mediaDownloads = WGMenuTabID("media.downloads")
    // Appearance
    public static let appearanceMessages = WGMenuTabID("appearance.messages")
    public static let appearanceChatList = WGMenuTabID("appearance.chatList")
    public static let appearancePanels = WGMenuTabID("appearance.panels")
    public static let appearanceThemeBackground = WGMenuTabID("appearance.themeBackground")
    public static let appearanceIcons = WGMenuTabID("appearance.icons")
    public static let appearanceProfileSettings = WGMenuTabID("appearance.profileSettings")
    // Security
    public static let securityChatProtection = WGMenuTabID("security.chatProtection")
    public static let securityPasscode = WGMenuTabID("security.passcode")
    public static let securityAccounts = WGMenuTabID("security.accounts")
    // Swiftgram: every feature that came from Swiftgram, grouped as Swiftgram grouped them
    public static let swiftgramChatList = WGMenuTabID("swiftgram.chatList")
    public static let swiftgramTabs = WGMenuTabID("swiftgram.tabs")
    public static let swiftgramChat = WGMenuTabID("swiftgram.chat")
    public static let swiftgramMedia = WGMenuTabID("swiftgram.media")
    public static let swiftgramStories = WGMenuTabID("swiftgram.stories")
    public static let swiftgramProfiles = WGMenuTabID("swiftgram.profiles")
    public static let swiftgramNetwork = WGMenuTabID("swiftgram.network")
    public static let swiftgramPro = WGMenuTabID("swiftgram.pro")
    // More
    public static let moreVpn = WGMenuTabID("more.vpn")
    public static let moreFakeGifts = WGMenuTabID("more.fakeGifts")
    public static let moreWraithgramSettings = WGMenuTabID("more.wraithgramSettings")
    public static let moreAbout = WGMenuTabID("more.about")
}

extension WGMenuSectionID {
    // Category screens
    public static let privacyPreview = WGMenuSectionID("privacy.preview")
    public static let privacyGhostMode = WGMenuSectionID("privacy.ghostMode")
    public static let privacyTabs = WGMenuSectionID("privacy.tabs")
    public static let privacyTraces = WGMenuSectionID("privacy.traces")
    public static let messagesPreview = WGMenuSectionID("messages.preview")
    public static let messagesTabs = WGMenuSectionID("messages.tabs")
    public static let messagesChats = WGMenuSectionID("messages.chats")
    public static let mediaTabs = WGMenuSectionID("media.tabs")
    public static let appearanceTabs = WGMenuSectionID("appearance.tabs")
    public static let securityTabs = WGMenuSectionID("security.tabs")
    public static let swiftgramTabs = WGMenuSectionID("swiftgram.tabs")
    public static let moreTabs = WGMenuSectionID("more.tabs")
    // «Настройки Wraithgram» and «О приложении»
    public static let wraithgramSettingsLanguage = WGMenuSectionID("more.wraithgramSettings.language")
    public static let wraithgramSettingsData = WGMenuSectionID("more.wraithgramSettings.data")
    public static let aboutInfo = WGMenuSectionID("more.about.info")
    public static let aboutLicense = WGMenuSectionID("more.about.license")

    /// `<tab>.preview`, order 100 on the tab screen.
    public static func preview(of tab: WGMenuTabID) -> WGMenuSectionID {
        return WGMenuSectionID(tab.rawValue + ".preview")
    }

    /// `<tab>.main`, order 200 on the tab screen.
    public static func main(of tab: WGMenuTabID) -> WGMenuSectionID {
        return WGMenuSectionID(tab.rawValue + ".main")
    }
}

private struct WGSkeletonTab {
    let id: WGMenuTabID
    /// The section that links to the tab; nil — the tab opens from Telegram's Settings (its parent is the root).
    let section: WGMenuSectionID?
    let order: Int
    let title: () -> String
    let info: () -> String
    let icon: WGMenuIcon
    let emoji: String
}

private func wgSkeletonTabs() -> [WGSkeletonTab] {
    return [
        WGSkeletonTab(id: .privacyGhostExceptions, section: .privacyTabs, order: 100, title: { WGStrings.Menu.Tab.Privacy.ghostExceptions }, info: { WGStrings.Menu.Tab.Privacy.ghostExceptionsInfo }, icon: .bundle("Chat/Context Menu/Eye"), emoji: "👥"),
        WGSkeletonTab(id: .privacySendDelay, section: .privacyTabs, order: 200, title: { WGStrings.Menu.Tab.Privacy.sendDelay }, info: { WGStrings.Menu.Tab.Privacy.sendDelayInfo }, icon: .bundle("Chat/Context Menu/Schedule"), emoji: "⏳"),
        WGSkeletonTab(id: .privacySpoofing, section: .privacyTabs, order: 300, title: { WGStrings.Menu.Tab.Privacy.spoofing }, info: { WGStrings.Menu.Tab.Privacy.spoofingInfo }, icon: .bundle("Chat/Context Menu/Replace"), emoji: "🎭"),
        WGSkeletonTab(id: .privacyAnonymousMode, section: .privacyTabs, order: 400, title: { WGStrings.Menu.Tab.Privacy.anonymousMode }, info: { WGStrings.Menu.Tab.Privacy.anonymousModeInfo }, icon: .bundle("Chat/Context Menu/EyeLocked"), emoji: "🕶"),

        WGSkeletonTab(id: .messagesAntiDelete, section: .messagesTabs, order: 100, title: { WGStrings.Menu.Tab.Messages.antiDelete }, info: { WGStrings.Menu.Tab.Messages.antiDeleteInfo }, icon: .bundle("Chat/Context Menu/Delete"), emoji: "🗑"),
        WGSkeletonTab(id: .messagesRestrictions, section: .messagesTabs, order: 200, title: { WGStrings.Menu.Tab.Messages.restrictions }, info: { WGStrings.Menu.Tab.Messages.restrictionsInfo }, icon: .bundle("Chat/Context Menu/Copy"), emoji: "🔓"),
        WGSkeletonTab(id: .messagesSending, section: .messagesTabs, order: 300, title: { WGStrings.Menu.Tab.Messages.sending }, info: { WGStrings.Menu.Tab.Messages.sendingInfo }, icon: .bundle("Chat/Context Menu/FormatText"), emoji: "✉️"),
        WGSkeletonTab(id: .messagesTranslation, section: .messagesTabs, order: 400, title: { WGStrings.Menu.Tab.Messages.translation }, info: { WGStrings.Menu.Tab.Messages.translationInfo }, icon: .bundle("Chat/Context Menu/Translate"), emoji: "🌐"),
        WGSkeletonTab(id: .messagesMenuGestures, section: .messagesTabs, order: 500, title: { WGStrings.Menu.Tab.Messages.menuGestures }, info: { WGStrings.Menu.Tab.Messages.menuGesturesInfo }, icon: .bundle("Chat/Context Menu/List"), emoji: "👆"),
        WGSkeletonTab(id: .messagesExport, section: .messagesTabs, order: 600, title: { WGStrings.Menu.Tab.Messages.export }, info: { WGStrings.Menu.Tab.Messages.exportInfo }, icon: .bundle("Chat/Context Menu/Share"), emoji: "📦"),

        WGSkeletonTab(id: .mediaVoice, section: .mediaTabs, order: 100, title: { WGStrings.Menu.Tab.Media.voice }, info: { WGStrings.Menu.Tab.Media.voiceInfo }, icon: .bundle("Chat/Context Menu/VoiceChat"), emoji: "🎙"),
        WGSkeletonTab(id: .mediaCameraVideoMessages, section: .mediaTabs, order: 200, title: { WGStrings.Menu.Tab.Media.cameraVideoMessages }, info: { WGStrings.Menu.Tab.Media.cameraVideoMessagesInfo }, icon: .bundle("Chat/Context Menu/Camera"), emoji: "📹"),
        WGSkeletonTab(id: .mediaCalls, section: .mediaTabs, order: 300, title: { WGStrings.Menu.Tab.Media.calls }, info: { WGStrings.Menu.Tab.Media.callsInfo }, icon: .bundle("Chat/Context Menu/PhoneCall"), emoji: "📞"),
        WGSkeletonTab(id: .mediaDownloads, section: .mediaTabs, order: 400, title: { WGStrings.Menu.Tab.Media.downloads }, info: { WGStrings.Menu.Tab.Media.downloadsInfo }, icon: .bundle("Chat/Context Menu/Download"), emoji: "⚡️"),

        WGSkeletonTab(id: .appearanceMessages, section: .appearanceTabs, order: 100, title: { WGStrings.Menu.Tab.Appearance.messages }, info: { WGStrings.Menu.Tab.Appearance.messagesInfo }, icon: .bundle("Chat/Context Menu/MessageBubble"), emoji: "💬"),
        WGSkeletonTab(id: .appearanceChatList, section: .appearanceTabs, order: 200, title: { WGStrings.Menu.Tab.Appearance.chatList }, info: { WGStrings.Menu.Tab.Appearance.chatListInfo }, icon: .bundle("Chat/Context Menu/Chats"), emoji: "📋"),
        WGSkeletonTab(id: .appearancePanels, section: .appearanceTabs, order: 300, title: { WGStrings.Menu.Tab.Appearance.panels }, info: { WGStrings.Menu.Tab.Appearance.panelsInfo }, icon: .bundle("Chat/Context Menu/AlignBottom"), emoji: "🧩"),
        WGSkeletonTab(id: .appearanceThemeBackground, section: .appearanceTabs, order: 400, title: { WGStrings.Menu.Tab.Appearance.themeBackground }, info: { WGStrings.Menu.Tab.Appearance.themeBackgroundInfo }, icon: .bundle("Chat/Context Menu/ApplyTheme"), emoji: "🎨"),
        WGSkeletonTab(id: .appearanceIcons, section: .appearanceTabs, order: 500, title: { WGStrings.Menu.Tab.Appearance.icons }, info: { WGStrings.Menu.Tab.Appearance.iconsInfo }, icon: .bundle("Chat/Context Menu/Apps"), emoji: "🖼"),
        WGSkeletonTab(id: .appearanceProfileSettings, section: .appearanceTabs, order: 600, title: { WGStrings.Menu.Tab.Appearance.profileSettings }, info: { WGStrings.Menu.Tab.Appearance.profileSettingsInfo }, icon: .bundle("Chat/Context Menu/User"), emoji: "🪪"),

        WGSkeletonTab(id: .securityChatProtection, section: .securityTabs, order: 100, title: { WGStrings.Menu.Tab.Security.chatProtection }, info: { WGStrings.Menu.Tab.Security.chatProtectionInfo }, icon: .bundle("Chat/Context Menu/Lock"), emoji: "🔐"),
        WGSkeletonTab(id: .securityPasscode, section: .securityTabs, order: 300, title: { WGStrings.Menu.Tab.Security.passcode }, info: { WGStrings.Menu.Tab.Security.passcodeInfo }, icon: .bundle("Chat/Context Menu/FaceId"), emoji: "🔢"),
        WGSkeletonTab(id: .securityAccounts, section: .securityTabs, order: 400, title: { WGStrings.Menu.Tab.Security.accounts }, info: { WGStrings.Menu.Tab.Security.accountsInfo }, icon: .bundle("Chat/Context Menu/AddUser"), emoji: "👤"),

        WGSkeletonTab(id: .swiftgramChatList, section: .swiftgramTabs, order: 100, title: { WGStrings.Menu.Tab.Swiftgram.chatList }, info: { WGStrings.Menu.Tab.Swiftgram.chatListInfo }, icon: .bundle("Chat/Context Menu/Chats"), emoji: "📋"),
        WGSkeletonTab(id: .swiftgramTabs, section: .swiftgramTabs, order: 200, title: { WGStrings.Menu.Tab.Swiftgram.tabs }, info: { WGStrings.Menu.Tab.Swiftgram.tabsInfo }, icon: .bundle("Chat/Context Menu/AlignBottom"), emoji: "🗂"),
        WGSkeletonTab(id: .swiftgramChat, section: .swiftgramTabs, order: 300, title: { WGStrings.Menu.Tab.Swiftgram.chat }, info: { WGStrings.Menu.Tab.Swiftgram.chatInfo }, icon: .bundle("Chat/Context Menu/MessageBubble"), emoji: "💬"),
        WGSkeletonTab(id: .swiftgramMedia, section: .swiftgramTabs, order: 400, title: { WGStrings.Menu.Tab.Swiftgram.media }, info: { WGStrings.Menu.Tab.Swiftgram.mediaInfo }, icon: .bundle("Chat/Context Menu/Image"), emoji: "🖼"),
        WGSkeletonTab(id: .swiftgramStories, section: .swiftgramTabs, order: 500, title: { WGStrings.Menu.Tab.Swiftgram.stories }, info: { WGStrings.Menu.Tab.Swiftgram.storiesInfo }, icon: .bundle("Chat/Context Menu/Stories"), emoji: "⭕️"),
        WGSkeletonTab(id: .swiftgramProfiles, section: .swiftgramTabs, order: 600, title: { WGStrings.Menu.Tab.Swiftgram.profiles }, info: { WGStrings.Menu.Tab.Swiftgram.profilesInfo }, icon: .bundle("Chat/Context Menu/User"), emoji: "🪪"),
        WGSkeletonTab(id: .swiftgramNetwork, section: .swiftgramTabs, order: 700, title: { WGStrings.Menu.Tab.Swiftgram.network }, info: { WGStrings.Menu.Tab.Swiftgram.networkInfo }, icon: .bundle("Chat/Context Menu/Globe"), emoji: "🌐"),
        WGSkeletonTab(id: .swiftgramPro, section: nil, order: 800, title: { WGStrings.Menu.Tab.Swiftgram.pro }, info: { WGStrings.Menu.Tab.Swiftgram.proInfo }, icon: .bundle("Chat/Context Menu/Stars"), emoji: "⭐️"),

        WGSkeletonTab(id: .moreVpn, section: .moreTabs, order: 100, title: { WGStrings.Menu.Tab.More.vpn }, info: { WGStrings.Menu.Tab.More.vpnInfo }, icon: .bundle("Chat/Context Menu/Globe"), emoji: "🛡"),
        WGSkeletonTab(id: .moreFakeGifts, section: .moreTabs, order: 300, title: { WGStrings.Menu.Tab.More.fakeGifts }, info: { WGStrings.Menu.Tab.More.fakeGiftsInfo }, icon: .bundle("Chat/Context Menu/Gift"), emoji: "🎁"),
        WGSkeletonTab(id: .moreWraithgramSettings, section: .moreTabs, order: 400, title: { WGStrings.Menu.Tab.More.wraithgramSettings }, info: { WGStrings.Menu.Tab.More.wraithgramSettingsInfo }, icon: .bundle("Chat/Context Menu/Settings"), emoji: "⚙️"),
        WGSkeletonTab(id: .moreAbout, section: .moreTabs, order: 500, title: { WGStrings.Menu.Tab.More.about }, info: { WGStrings.Menu.Tab.More.aboutInfo }, icon: .bundle("Chat/Context Menu/Info"), emoji: "👻")
    ]
}

func wgRegisterMenuSkeleton() {
    // Category screens.
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .privacyPreview, screen: .category(.privacy), order: 100))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .privacyGhostMode, screen: .category(.privacy), order: 200, header: { WGStrings.Menu.Section.Privacy.ghostMode }))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .privacyTabs, screen: .category(.privacy), order: 300))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .privacyTraces, screen: .category(.privacy), order: 400, header: { WGStrings.Menu.Section.Privacy.traces }))

    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .messagesPreview, screen: .category(.messages), order: 100))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .messagesTabs, screen: .category(.messages), order: 200))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .messagesChats, screen: .category(.messages), order: 300, header: { WGStrings.Menu.Section.Messages.chats }))

    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .mediaTabs, screen: .category(.media), order: 100))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .appearanceTabs, screen: .category(.appearance), order: 100))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .securityTabs, screen: .category(.security), order: 100))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .swiftgramTabs, screen: .category(.swiftgram), order: 100))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .moreTabs, screen: .category(.more), order: 100))

    // Tabs, their links and their default sections.
    for tab in wgSkeletonTabs() {
        let emoji = tab.emoji
        let info = tab.info
        let descriptor = WGMenuTabDescriptor(
            id: tab.id,
            parent: tab.section.flatMap { WGMenuStorage.shared.sectionsById[$0]?.screen } ?? .root,
            title: tab.title,
            topView: WGMenuTopView(content: .emoji(emoji), text: info),
            searchKeywords: { [info()] }
        )
        if let section = tab.section {
            WGMenuRegistry.register(tab: descriptor, linkIn: section, order: tab.order, subtitle: info, icon: tab.icon)
        } else {
            WGMenuRegistry.register(tab: descriptor)
        }
        WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .preview(of: tab.id), screen: .tab(tab.id), order: 100))
        WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .main(of: tab.id), screen: .tab(tab.id), order: 200))
    }

    // «Настройки Wraithgram» and «О приложении» carry W1-3's own rows (see WGSettingsDataScreens.swift).
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .wraithgramSettingsLanguage, screen: .tab(.moreWraithgramSettings), order: 300, header: { WGStrings.Menu.Settings.languageHeader }, footer: { _ in WGStrings.Menu.Settings.languageFooter }))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .wraithgramSettingsData, screen: .tab(.moreWraithgramSettings), order: 400, header: { WGStrings.Menu.Settings.dataHeader }, footer: { _ in WGStrings.Menu.Settings.dataFooter }))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .aboutInfo, screen: .tab(.moreAbout), order: 300))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .aboutLicense, screen: .tab(.moreAbout), order: 500, header: { WGStrings.Menu.About.licenseHeader }, footer: { _ in WGStrings.Menu.About.licenseFooter }))

    // Sections the Swiftgram tabs get from the features that moved their rows there.
    wgRegisterSwiftgramSections()
}
