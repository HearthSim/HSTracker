//
//  GuideTooltip.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's ToolTip template (OutlinedTextBlock title, bold/13pt with a
// 6pt bottom margin; MultiLineTextBlock body, regular/12pt with an 8pt bottom
// margin when a footer follows; OutlinedTextBlock footer lines, bold/12pt,
// flush against each other with no margin).
//
// Originally built for the Mulligan V2 overlay (still its main consumer) but
// generic to any RootOverlayView content - Battlegrounds Guides reuses it for
// its own small text tooltips (e.g. difficulty/tier explanations). Not a fit
// for card-preview tooltips (a full card image, like HDT's CardTooltip) -
// those are a different visual and aren't built yet.
@available(macOS 10.15, *)
struct GuideTooltipContent: Equatable {
    var title: String?
    var body: String?
    var footer: [String] = []
}

// RootOverlayWindow is a non-activating floating panel that never becomes key
// (so it doesn't steal focus from Hearthstone) - AppKit's native tooltip
// mechanism (NSView.toolTip) needs the window to be key to ever display, so
// it never fires here, hence rolling our own via .onHover.
//
// The bubble renders in place, which means it sits inside the RootOverlayView
// child's own scaled subtree and scales with the rest of the overlay -
// matching HDT, which deliberately applies the same ScaleTransform to its
// tooltips via the LayoutTransform setter in the consuming XAML.
@available(macOS 10.15, *)
private struct GuideTooltipModifier: ViewModifier {
    let content: GuideTooltipContent?

    @SwiftUI.State private var isHovering = false

    // HDT: Placement="Top" with VerticalOffset="-4", plus the template Border's
    // own 10pt bottom margin.
    private static let gap: CGFloat = 14

    func body(content viewContent: Content) -> some View {
        viewContent
            .onHover { hovering in
                guard content != nil else { return }
                isHovering = hovering
            }
            .overlay(bubble, alignment: .top)
    }

    @ViewBuilder
    private var bubble: some View {
        if isHovering, let content {
            // Zero-height marker pinned to the anchor's top edge, with the
            // bubble bottom-aligned onto it so it grows *upward* (HDT's
            // Placement="Top") without this view needing to know the bubble's
            // height, and horizontally centered on the anchor (HDT's
            // CenteredTooltipConverter).
            Color.clear
                .frame(height: 0)
                .overlay(GuideTooltipBubble(content: content), alignment: .bottom)
                .offset(y: -Self.gap)
                .allowsHitTesting(false)
        }
    }
}

@available(macOS 10.15, *)
private struct GuideTooltipBubble: View {
    let content: GuideTooltipContent

    // HDT's ConstructedTooltipStyle caps its Border at MaxWidth=230 (inclusive
    // of the 8pt horizontal padding) and lets it hug narrower content; this
    // pins the width at that cap, which every tooltip here wraps to anyway.
    private static let textWidth: CGFloat = 214

    var body: some View {
        text
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            // fixedSize only vertically, against a definite width: a Text's
            // *ideal* size is a single unwrapped line, so fixing it
            // horizontally too would size the box to one line's height while
            // the text itself wraps to several - and .cornerRadius() below
            // clips to that box, which is what was cutting off lines.
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: Self.textWidth, alignment: .leading)
            .padding(EdgeInsets(top: 5, leading: 8, bottom: 6, trailing: 8))
            .background(Color(red: 0x14 / 255, green: 0x16 / 255, blue: 0x17 / 255))
            .cornerRadius(2)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(white: 0x33 / 255.0).opacity(0.8), lineWidth: 1))
    }

    // Built as a single concatenated Text (SwiftUI's `+` operator preserves
    // each segment's own font/weight) rather than a VStack of separate Text
    // children, whose height computation proved unreliable under fixedSize.
    private var text: Text {
        var result: Text?
        func append(_ next: Text) {
            result = result.map { $0 + next } ?? next
        }

        if let title = content.title {
            append(Text(title).font(.system(size: 13, weight: .bold)))
        }
        if let body = content.body {
            if result != nil { append(Text("\n\n")) }
            append(Text(body).font(.system(size: 12, weight: .regular)))
        }
        if !content.footer.isEmpty {
            if result != nil { append(Text("\n\n")) }
            for (index, line) in content.footer.enumerated() {
                if index > 0 { append(Text("\n")) }
                append(Text(line).font(.system(size: 12, weight: .bold)))
            }
        }
        return result ?? Text("")
    }
}

@available(macOS 10.15, *)
extension View {
    func guideTooltip(_ content: GuideTooltipContent?) -> some View {
        modifier(GuideTooltipModifier(content: content))
    }

    // Convenience for tooltips with no title/footer, just a body line (e.g.
    // the low-data warning triangle).
    func guideTooltip(_ text: String?) -> some View {
        modifier(GuideTooltipModifier(content: text.map { GuideTooltipContent(body: $0) }))
    }
}

// MARK: - Battlegrounds left-placed tooltip

// Mirrors HDT's BgsLeftTooltipStyle (Controls/Overlay/Battlegrounds/
// BattlegroundsResources.xaml), which the comp guides pick up through their own
// BgsTooltipStyle: a square #141617 bubble with a 1pt #FFB00D border, 8pt
// padding, MaxWidth="230" and white 14pt centered wrapping text, placed to the
// left of its target with their top edges aligned.
//
// Hosted in its own borderless panel rather than drawn in place like
// GuideTooltipModifier above, because the comp guide's content sits inside a
// ScrollView whose clip would cut off a bubble that by construction hangs
// entirely outside the panel. Same mechanics as CardTooltipPanel, and the same
// reason it is a panel too.
@available(macOS 10.15, *)
final class BgsTooltipPanel: NSPanel {
    static let shared = BgsTooltipPanel()

    private var hostingView: NSHostingView<BgsTooltipBubble>!
    private var pendingShowWork: DispatchWorkItem?
    // The anchor the panel is currently showing for, so a hide from a different
    // anchor (a stale mouseExited, a row being torn down) is a no-op.
    private weak var owner: NSView?

    // ToolTipService.InitialShowDelay="500" on the comp guide's wrapper Border.
    private static let showDelay: TimeInterval = 0.5

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: BgsTooltipBubble.maxWidth, height: 40),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        isOpaque = false
        backgroundColor = .clear
        level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        ignoresMouseEvents = true
        hasShadow = false
        hidesOnDeactivate = false
        animationBehavior = .none

        let host = NSHostingView(rootView: BgsTooltipBubble(text: ""))
        hostingView = host
        contentView = host
    }

    /// - Parameter verticalOffset: HDT's `ToolTip.VerticalOffset`, in WPF's
    ///   Y-down sense - negative lifts the bubble.
    func show(text: String, from view: NSView, verticalOffset: CGFloat) {
        pendingShowWork?.cancel()
        owner = view
        let work = DispatchWorkItem { [weak self, weak view] in
            guard let self = self, let view = view, let window = view.window else { return }
            self.pendingShowWork = nil

            self.hostingView.rootView = BgsTooltipBubble(text: text)
            let size = self.hostingView.fittingSize
            self.setContentSize(size)
            self.hostingView.layoutSubtreeIfNeeded()

            let anchor = window.convertToScreen(view.convert(view.bounds, to: nil))
            // Placement="Left": the bubble's right edge meets the target's left
            // edge and their tops line up. Screen coordinates are Y-up, so the
            // Y-down VerticalOffset is subtracted rather than added.
            var origin = NSPoint(x: anchor.minX - size.width,
                                 y: anchor.maxY - verticalOffset - size.height)
            // HDT keeps its tooltips inside the overlay window (the Hearthstone
            // window), not inside the screen.
            let bounds = window.frame
            origin.x = max(bounds.minX, min(origin.x, bounds.maxX - size.width))
            origin.y = max(bounds.minY, min(origin.y, bounds.maxY - size.height))
            self.setFrameOrigin(origin)
            self.orderFrontRegardless()
        }
        pendingShowWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.showDelay, execute: work)
    }

    func hide(from view: NSView) {
        guard owner === view else { return }
        pendingShowWork?.cancel()
        pendingShowWork = nil
        owner = nil
        orderOut(nil)
    }
}

@available(macOS 10.15, *)
private struct BgsTooltipBubble: View {
    let text: String

    // The template Border's MaxWidth="230", inclusive of its 8pt padding and
    // 1pt border. Pinned rather than capped, as in GuideTooltipBubble above -
    // every tooltip on this surface wraps to it anyway.
    static let maxWidth: CGFloat = 230
    private static let textWidth: CGFloat = maxWidth - 2 * (8 + 1)

    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            // Vertical-only fixedSize against a definite width, for the reason
            // spelled out in GuideTooltipBubble.
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: Self.textWidth)
            .padding(8)
            .background(Color(hex: "#141617"))
            // Tier7Orange, and a square Border - BgsLeftTooltipStyle sets no
            // CornerRadius.
            .overlay(Rectangle().stroke(Color(hex: "#FFB00D"), lineWidth: 1))
    }
}

// The hover source and the placement target in one: an NSView reports both
// through AppKit tracking areas, which - unlike SwiftUI's .onHover - keep
// working for a subtree that .disabled() has taken out of hit-testing, and
// unlike a SwiftUI overlay it can be converted to screen coordinates through
// the whole scaled, scrolled chain.
@available(macOS 10.15, *)
private final class BgsTooltipAnchorNSView: NSView {
    var text: String?
    var verticalOffset: CGFloat = 0

    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        guard let text = text, !text.isEmpty else { return }
        BgsTooltipPanel.shared.show(text: text, from: self, verticalOffset: verticalOffset)
    }

    override func mouseExited(with event: NSEvent) {
        BgsTooltipPanel.shared.hide(from: self)
    }

    // The guide can be navigated away from - or the whole overlay torn down -
    // while the bubble is up or its show delay is still pending.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            BgsTooltipPanel.shared.hide(from: self)
        }
    }
}

@available(macOS 10.15, *)
private struct BgsTooltipAnchorRepresentable: NSViewRepresentable {
    let text: String?
    let verticalOffset: CGFloat

    func makeNSView(context: Context) -> BgsTooltipAnchorNSView {
        BgsTooltipAnchorNSView()
    }

    func updateNSView(_ nsView: BgsTooltipAnchorNSView, context: Context) {
        nsView.text = text
        nsView.verticalOffset = verticalOffset
        // The tooltip's Visibility is bound in HDT, so it can go away while the
        // cursor is still on the element.
        if text == nil || text?.isEmpty == true {
            BgsTooltipPanel.shared.hide(from: nsView)
        }
    }
}

@available(macOS 10.15, *)
extension View {
    // A nil or empty text attaches nothing, mirroring the bound Visibility HDT
    // puts on these tooltips.
    func bgsTooltip(_ text: String?, verticalOffset: CGFloat = 0) -> some View {
        background(BgsTooltipAnchorRepresentable(text: text, verticalOffset: verticalOffset))
    }
}
