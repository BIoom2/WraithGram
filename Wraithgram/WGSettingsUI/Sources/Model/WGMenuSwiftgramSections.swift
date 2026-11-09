import Foundation
import WGCore

/// Sections of the «Swiftgram» category. Every feature that came from Swiftgram keeps its setting key
/// and registers its row here; the sections (with their orders on the tab screens) live in one place so
/// that features never have to agree on orders with each other. Sections that moved together with
/// their rows (folders, tab bar, badge, stickers, snow, boost, photos, notifications) keep the
/// descriptors of their feature and are only pointed at a Swiftgram tab.
///
/// Orders on a tab screen: preview 100, main 200, then 240…1000 as listed below.
extension WGMenuSectionID {
    // «Сообщения и чат»
    public static let swiftgramChatMessages = WGMenuSectionID("swiftgram.chat.messages")
    public static let swiftgramChatInput = WGMenuSectionID("swiftgram.chat.input")
    public static let swiftgramChatActions = WGMenuSectionID("swiftgram.chat.actions")
    public static let swiftgramChatMenu = WGMenuSectionID("swiftgram.chat.menu")
    public static let swiftgramChatCalls = WGMenuSectionID("swiftgram.chat.calls")
    // «Медиа и загрузки»
    public static let swiftgramMediaCamera = WGMenuSectionID("swiftgram.media.camera")
    public static let swiftgramMediaVideo = WGMenuSectionID("swiftgram.media.video")
    // «Профили»
    public static let swiftgramProfilesInfo = WGMenuSectionID("swiftgram.profiles.info")
    // «Pro»
    public static let swiftgramProFilter = WGMenuSectionID("swiftgram.pro.filter")
    public static let swiftgramProFormatting = WGMenuSectionID("swiftgram.pro.formatting")
    public static let swiftgramProSecurity = WGMenuSectionID("swiftgram.pro.security")
}

/// Screen orders of the sections that features move onto the Swiftgram tabs (see the table above).
public enum WGSwiftgramOrder {
    // swiftgramChatList: preview 100, main 200
    public static let chatListFolders = 300
    // swiftgramTabs: preview 100, main 200
    public static let tabsBarPreview = 240
    public static let tabsBar = 250
    public static let tabsBadge = 300
    // swiftgramChat: preview 100, main 200
    public static let chatMessages = 300
    public static let chatStickers = 400
    public static let chatInput = 500
    public static let chatActions = 600
    public static let chatMenu = 700
    public static let chatSnow = 800
    public static let chatTranslation = 900
    public static let chatCalls = 1000
    // swiftgramMedia: preview 100, main 200
    public static let mediaBoost = 300
    public static let mediaPhotos = 400
    public static let mediaCamera = 500
    public static let mediaVideo = 600
    // swiftgramProfiles: preview 100, main 200
    public static let profilesInfo = 300
    // swiftgramPro: preview 100, main 200
    public static let proFilter = 300
    public static let proFormatting = 400
    public static let proNotifications = 500
    public static let proSecurity = 600
}

func wgRegisterSwiftgramSections() {
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .swiftgramChatMessages, screen: .tab(.swiftgramChat), order: WGSwiftgramOrder.chatMessages, header: { WGStrings.Menu.Section.Swiftgram.chatMessages }))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .swiftgramChatInput, screen: .tab(.swiftgramChat), order: WGSwiftgramOrder.chatInput, header: { WGStrings.Menu.Section.Swiftgram.chatInput }))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .swiftgramChatActions, screen: .tab(.swiftgramChat), order: WGSwiftgramOrder.chatActions, header: { WGStrings.Menu.Section.Swiftgram.chatActions }))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .swiftgramChatMenu, screen: .tab(.swiftgramChat), order: WGSwiftgramOrder.chatMenu, header: { WGStrings.Menu.Section.Swiftgram.chatMenu }))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .swiftgramChatCalls, screen: .tab(.swiftgramChat), order: WGSwiftgramOrder.chatCalls, header: { WGStrings.Menu.Section.Swiftgram.chatCalls }))

    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .swiftgramMediaCamera, screen: .tab(.swiftgramMedia), order: WGSwiftgramOrder.mediaCamera, header: { WGStrings.Menu.Section.Swiftgram.mediaCamera }))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .swiftgramMediaVideo, screen: .tab(.swiftgramMedia), order: WGSwiftgramOrder.mediaVideo, header: { WGStrings.Menu.Section.Swiftgram.mediaVideo }))

    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .swiftgramProfilesInfo, screen: .tab(.swiftgramProfiles), order: WGSwiftgramOrder.profilesInfo, header: { WGStrings.Menu.Section.Swiftgram.profilesInfo }, footer: { _ in WGStrings.Appearance.Profile.footer }))

    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .swiftgramProFilter, screen: .tab(.swiftgramPro), order: WGSwiftgramOrder.proFilter, header: { WGStrings.Menu.Section.Swiftgram.proFilter }))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .swiftgramProFormatting, screen: .tab(.swiftgramPro), order: WGSwiftgramOrder.proFormatting, header: { WGStrings.Menu.Section.Swiftgram.proFormatting }))
    WGMenuRegistry.register(section: WGMenuSectionDescriptor(id: .swiftgramProSecurity, screen: .tab(.swiftgramPro), order: WGSwiftgramOrder.proSecurity, header: { WGStrings.Menu.Section.Swiftgram.proSecurity }))
}
