// Compiled into ChatListUI (filegroup //Wraithgram/WGHooks:ChatListUIHookSources).
// «Папки внизу» (W2-5 folders_tweaks, SG-A5): the folder tabs of the root chat list in their own
// glass strip above the tab bar instead of the header. ChatListControllerNode hands the tabs it
// built for the header to `takeTabs` (every header layout, both the full container layout and
// `requestNavigationBarLayout`); the strip is laid out there and the list's bottom inset grows by
// `reservedHeight`. The strip is a second HeaderPanelContainerComponent with the same tabs, so
// taps, the context menu, editing and reordering are the header's own.
//
// Two looks (`WGChatListFolderStrip.bottomStyle`): `.glass` (above) and `.flat`, a full-width bar
// attached to the tab bar (plain list background, thin separator on top, no gap and no side insets),
// hosted by `WGFlatFolderStripView` below with the same tabs component.
//
// While `WGChatListFolderStrip.atBottom` is off, `takeTabs` returns the tabs unchanged and nothing
// is created: the header is upstream's.

import Foundation
import UIKit
import Display
import ComponentFlow
import TelegramPresentationData
import AccountContext
import HeaderPanelContainerComponent
import HorizontalTabsComponent
import GlassBackgroundComponent
import ChatListTitleView

final class WGChatListBottomFolderStrip {
    /// Gap between the strip and the tab bar; the same again under the list's last row.
    private static let spacing: CGFloat = 8.0

    private var host: ComponentView<Empty>?
    /// The `.flat` host; at most one of `host` / `flatHost` exists.
    private var flatHost: WGFlatFolderStripView?
    /// Height the list leaves free at its bottom for the strip; 0 while the strip is not shown.
    private(set) var reservedHeight: CGFloat = 0.0

    init() {
    }

    /// The tabs for the header. With «Папки внизу» on they go to the strip (laid out here, in
    /// `parentView` above `aboveView`) and the header gets nil. `isHidden`: search or an inline
    /// forum covers the list — the strip fades out, the tabs still stay out of the header.
    func takeTabs(_ tabs: AnyComponent<Empty>?, context: AccountContext, layout: ContainerViewLayout, theme: PresentationTheme, parentView: UIView, aboveView: UIView, isHidden: Bool, transition: ComponentTransition) -> AnyComponent<Empty>? {
        let strip = wgChatListFolderStrip(context: context)
        if !strip.atBottom {
            self.remove(transition: transition)
            return tabs
        }
        guard let tabs = tabs, !isHidden else {
            self.remove(transition: transition)
            return nil
        }

        if strip.bottomStyle == .flat {
            return self.takeTabsFlat(tabs, strip: strip, layout: layout, theme: theme, parentView: parentView, aboveView: aboveView, transition: transition)
        }
        if self.flatHost != nil {
            self.remove(transition: .immediate)
        }

        let host: ComponentView<Empty>
        var hostTransition = transition
        if let current = self.host {
            host = current
        } else {
            host = ComponentView()
            self.host = host
            hostTransition = .immediate
        }
        let width = layout.size.width - layout.safeInsets.left - layout.safeInsets.right
        let size = host.update(
            transition: hostTransition,
            component: AnyComponent(HeaderPanelContainerComponent(
                theme: theme,
                tabs: tabs,
                panels: [],
                wgTabsHeightOffset: strip.heightOffset
            )),
            environment: {},
            containerSize: CGSize(width: width, height: 10000.0)
        )
        // `intrinsicInsets.bottom` of the chat list is the top of the tab bar (TabBarController), or
        // the safe area when the tab bar is hidden.
        let bottomEdge = layout.size.height - layout.insets(options: []).bottom
        let frame = CGRect(origin: CGPoint(x: layout.safeInsets.left, y: bottomEdge - WGChatListBottomFolderStrip.spacing - size.height), size: size)
        if let view = host.view {
            if view.superview == nil {
                parentView.insertSubview(view, aboveSubview: aboveView)
                view.alpha = 0.0
            }
            hostTransition.setFrame(view: view, frame: frame)
            transition.setAlpha(view: view, alpha: 1.0)
        }
        self.reservedHeight = size.height + WGChatListBottomFolderStrip.spacing * 2.0
        return nil
    }

    private func takeTabsFlat(_ tabs: AnyComponent<Empty>, strip: WGChatListFolderStrip, layout: ContainerViewLayout, theme: PresentationTheme, parentView: UIView, aboveView: UIView, transition: ComponentTransition) -> AnyComponent<Empty>? {
        if self.host != nil {
            self.remove(transition: .immediate)
        }
        let flatHost: WGFlatFolderStripView
        var hostTransition = transition
        if let current = self.flatHost {
            flatHost = current
        } else {
            flatHost = WGFlatFolderStripView()
            self.flatHost = flatHost
            hostTransition = .immediate
        }
        let safeWidth = layout.size.width - layout.safeInsets.left - layout.safeInsets.right
        let height = flatHost.update(tabs: tabs, theme: theme, safeInsets: UIEdgeInsets(top: 0.0, left: layout.safeInsets.left, bottom: 0.0, right: layout.safeInsets.right), safeWidth: safeWidth, totalWidth: layout.size.width, heightOffset: strip.heightOffset, transition: hostTransition)
        // The same edge as the glass strip: the top of the tab bar (or the safe area without one).
        let bottomEdge = layout.size.height - layout.insets(options: []).bottom
        let frame = CGRect(origin: CGPoint(x: 0.0, y: bottomEdge - height), size: CGSize(width: layout.size.width, height: height))
        if flatHost.superview == nil {
            parentView.insertSubview(flatHost, aboveSubview: aboveView)
            flatHost.alpha = 0.0
        }
        hostTransition.setFrame(view: flatHost, frame: frame)
        transition.setAlpha(view: flatHost, alpha: 1.0)
        self.reservedHeight = height
        return nil
    }

    /// Follows a swipe between folders, as the header's tabs do (ChatListController).
    func updateTabSwitchFraction(fraction: CGFloat, isDragging: Bool, transition: ComponentTransition) {
        self.tabsView?.updateTabSwitchFraction(fraction: fraction, isDragging: isDragging, transition: transition)
    }

    /// The folder order after the tabs were reordered in the strip, as ChatListController maps the
    /// header's (`Int32.min` — «All chats» — is 0). Nil when nothing was reordered here.
    var reorderedFilterIds: [Int32]? {
        guard let itemIds = self.tabsView?.reorderedItemIds else {
            return nil
        }
        return itemIds.compactMap { item -> Int32? in
            guard let value = item.base as? Int32 else {
                return nil
            }
            if value == Int32.min {
                return 0
            }
            return value
        }
    }

    private var tabsView: HorizontalTabsComponent.View? {
        if let flatHost = self.flatHost {
            return flatHost.tabsView
        }
        guard let containerView = self.host?.view as? HeaderPanelContainerComponent.View else {
            return nil
        }
        return containerView.tabs as? HorizontalTabsComponent.View
    }

    private func remove(transition: ComponentTransition) {
        self.reservedHeight = 0.0
        if let flatHost = self.flatHost {
            self.flatHost = nil
            transition.setAlpha(view: flatHost, alpha: 0.0, completion: { [weak flatHost] _ in
                flatHost?.removeFromSuperview()
            })
        }
        guard let host = self.host else {
            return
        }
        self.host = nil
        if let view = host.view {
            transition.setAlpha(view: view, alpha: 0.0, completion: { [weak view] _ in
                view?.removeFromSuperview()
            })
        }
    }
}

/// The `.flat` look: a full-width bar in the list's own background with a hairline on top, the tabs
/// of the header inside. Frame is set by the owner; `update` lays out the content and returns the height.
private final class WGFlatFolderStripView: UIView {
    /// Vertical padding above and below the tabs.
    private static let verticalInset: CGFloat = 4.0
    /// Same side padding the glass capsule gives its tabs.
    private static let sideInset: CGFloat = 16.0

    private let glassContainer = GlassBackgroundContainerView()
    private let separator = UIView()
    private let tabs = ComponentView<Empty>()

    var tabsView: HorizontalTabsComponent.View? {
        return self.tabs.view as? HorizontalTabsComponent.View
    }

    init() {
        super.init(frame: CGRect())
        self.addSubview(self.separator)
        self.addSubview(self.glassContainer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(tabs: AnyComponent<Empty>, theme: PresentationTheme, safeInsets: UIEdgeInsets, safeWidth: CGFloat, totalWidth: CGFloat, heightOffset: CGFloat, transition: ComponentTransition) -> CGFloat {
        self.backgroundColor = theme.list.plainBackgroundColor
        self.separator.backgroundColor = theme.rootController.tabBar.separatorColor

        let inset = WGFlatFolderStripView.sideInset
        let isNew = self.tabs.view == nil
        let tabsSize = self.tabs.update(
            transition: isNew ? .immediate : transition,
            component: tabs,
            environment: {},
            containerSize: CGSize(width: safeWidth - inset * 2.0, height: 40.0)
        )
        // As in HeaderPanelContainerComponent: the offset grows the row, the tabs stay centered in it.
        let offset = max(-floor(tabsSize.height * 0.5), heightOffset)
        let verticalInset = WGFlatFolderStripView.verticalInset
        let height = verticalInset * 2.0 + tabsSize.height + offset

        // The lens of the tabs lifts into a glass container, as in the capsule (which pads it by 32pt).
        let pad: CGFloat = 32.0
        let containerFrame = CGRect(origin: CGPoint(), size: CGSize(width: totalWidth, height: height)).insetBy(dx: -pad, dy: -pad)
        transition.setFrame(view: self.glassContainer, frame: containerFrame)
        self.glassContainer.update(size: containerFrame.size, isDark: theme.overallDarkAppearance, transition: transition)

        if let tabsView = self.tabs.view {
            if tabsView.superview == nil {
                self.glassContainer.contentView.addSubview(tabsView)
                if let tabsView = tabsView as? HeaderPanelContainerChildView {
                    tabsView.setOverlayContainerView(overlayContainerView: self.glassContainer.contentView)
                }
            }
            let tabsFrame = CGRect(origin: CGPoint(x: pad + safeInsets.left + inset, y: pad + verticalInset + floor(offset * 0.5)), size: tabsSize)
            (isNew ? ComponentTransition.immediate : transition).setFrame(view: tabsView, frame: tabsFrame)
        }
        transition.setFrame(view: self.separator, frame: CGRect(origin: CGPoint(), size: CGSize(width: totalWidth, height: UIScreenPixel)))
        return height
    }
}
