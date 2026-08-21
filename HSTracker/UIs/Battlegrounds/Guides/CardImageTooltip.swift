//
//  CardImageTooltip.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's CardTooltip (Controls/Tooltips/CardTooltip.xaml): a floating
// full card-image preview shown on hover, placed to the left of the hovered
// element.
//
// Which card is under the cursor is determined by CardHoverRegistry: each
// hoverable view embeds a CardHoverNSView (via NSViewRepresentable) that
// registers itself. RootOverlayWindow checks the registry on every mouse-move
// (using the same monitors that already drive the click-through region) by
// calling layer.convert(bounds, to: rootLayer) on each registered NSView.
// CALayer conversions go through the full transform chain — including
// SwiftUI's scaleEffect and NSScrollView's scroll offset — so the positions
// are always correct regardless of zoom level or scroll position.
// SwiftUI PreferenceKey-based rect reporting (tried first) fails here because
// preferences inside a ScrollView are not re-evaluated when the scroll
// position changes, producing systematically stale/wrong Y values.

// MARK: - Registry

@available(macOS 10.15, *)
final class CardHoverNSView: NSView {
    private(set) var cardId: String = ""
    // HDT's ShowTripleTooltip. False suppresses the golden companion image -
    // see BattlegroundsMinionArt.showTriple.
    private(set) var showTriple: Bool = true

    // Match NSHostingView's own flip so NSView.convert() coordinate conversions
    // are consistent with SwiftUI's Y-down coordinate space throughout the tree.
    override var isFlipped: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(cardId: String, showTriple: Bool) {
        guard cardId != self.cardId || showTriple != self.showTriple else { return }
        self.cardId = cardId
        self.showTriple = showTriple
        if window != nil {
            CardHoverRegistry.shared.register(self)
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            CardHoverRegistry.shared.register(self)
        } else {
            CardHoverRegistry.shared.unregister(self)
            // Hide immediately if this was the currently-shown card — the 150ms
            // fallback timer in RootOverlayWindow is too slow for navigation
            // (back to list) and doesn't fire at all when the match ends and
            // the overlay window is torn down.
            CardTooltipPanel.shared.hide(ifShowing: cardId)
        }
    }
}

@available(macOS 10.15, *)
class CardHoverRegistry {
    static let shared = CardHoverRegistry()

    struct Entry {
        let cardId: String
        let showTriple: Bool
        weak var view: CardHoverNSView?
    }

    private(set) var entries: [Entry] = []

    func register(_ view: CardHoverNSView) {
        entries.removeAll { $0.view == nil || $0.view === view }
        guard !view.cardId.isEmpty else { return }
        entries.append(Entry(cardId: view.cardId, showTriple: view.showTriple, view: view))
    }

    func unregister(_ view: CardHoverNSView) {
        entries.removeAll { $0.view === view || $0.view == nil }
    }
}

@available(macOS 10.15, *)
private struct CardHoverRepresentable: NSViewRepresentable {
    let cardId: String
    let showTriple: Bool

    func makeNSView(context: Context) -> CardHoverNSView {
        CardHoverNSView()
    }

    func updateNSView(_ nsView: CardHoverNSView, context: Context) {
        nsView.update(cardId: cardId, showTriple: showTriple)
    }
}

// MARK: - Tooltip panel

// Mirrors HDT's CardTooltip.xaml: base card shown immediately, golden card shown
// 0.8s later ALONGSIDE the base (matching StoryboardShowDelayed BeginTime="0:0:0.8").
// Both cards are visible simultaneously; golden disappears if the card is no longer hovered.
// If golden art is unavailable (card has no baconTriple), only the base card is shown.
@available(macOS 10.15, *)
class CardTooltipPanel: NSPanel {
    static let shared = CardTooltipPanel()

    private let primaryImageView = NSImageView()
    private let goldenImageView = NSImageView()
    private(set) var currentCardId: String?
    private var pendingShowWork: DispatchWorkItem?
    private var pendingHideWork: DispatchWorkItem?
    private var pendingGoldenWork: DispatchWorkItem?
    private var maxDurationTimer: Timer?

    private static let tooltipWidth: CGFloat = 220
    private static let tooltipHeight: CGFloat = tooltipWidth * 388.0 / 256.0
    private static let showDelay: TimeInterval = 0.3
    private static let hideDelay: TimeInterval = 0.1
    // 0.8s matches CardTooltip.xaml StoryboardShowDelayed BeginTime="0:0:0.8"
    private static let goldenDelay: TimeInterval = 0.8
    private static let maxDuration: TimeInterval = 60

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.tooltipWidth, height: Self.tooltipHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        isOpaque = false
        backgroundColor = .clear
        level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        ignoresMouseEvents = true
        hasShadow = true
        hidesOnDeactivate = false
        animationBehavior = .none

        let w = Self.tooltipWidth
        let h = Self.tooltipHeight
        primaryImageView.imageScaling = .scaleProportionallyUpOrDown
        primaryImageView.frame = NSRect(x: 0, y: 0, width: w, height: h)
        goldenImageView.imageScaling = .scaleProportionallyUpOrDown
        goldenImageView.frame = .zero

        let container = NSView(frame: NSRect(x: 0, y: 0, width: w, height: h))
        container.addSubview(goldenImageView)
        container.addSubview(primaryImageView)
        contentView = container

        // Hide tooltip when Hearthstone loses focus (tab-away).
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(hearthstoneDeactivated(_:)),
            name: NSWorkspace.didDeactivateApplicationNotification,
            object: nil
        )
    }

    @objc private func hearthstoneDeactivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        if app.localizedName == "Hearthstone" {
            hide()
        }
    }

    func show(cardId: String, showTriple: Bool = true) {
        pendingHideWork?.cancel()
        pendingHideWork = nil

        if currentCardId == cardId && isVisible {
            positionNearMouse(panelWidth: frame.size.width)
            return
        }

        pendingShowWork?.cancel()
        pendingGoldenWork?.cancel()
        pendingGoldenWork = nil

        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.pendingShowWork = nil
            // Abort if the view that triggered this show was removed from the
            // hierarchy while the 300ms delay was pending (guide closed, user
            // navigated away).  Without this guard the image load and orderFront
            // still fire, leaving a ghost tooltip after the guide is gone.
            guard CardHoverRegistry.shared.entries.contains(where: { $0.view != nil && $0.cardId == cardId }) else { return }
            self.currentCardId = cardId
            let w = Self.tooltipWidth
            let h = Self.tooltipHeight
            self.primaryImageView.image = nil
            self.goldenImageView.image = nil
            self.goldenImageView.frame = .zero
            self.primaryImageView.frame = NSRect(x: 0, y: 0, width: w, height: h)

            // Try BG art first (BG cards); fall back to the standard render
            // (collectible cards referenced in guide text like Sonya Shadowdancer).
            ImageUtils.cardArtBG(for: cardId, baconTriple: false) { [weak self] img in
                if let img = img {
                    DispatchQueue.main.async {
                        guard let self = self, self.currentCardId == cardId else { return }
                        self.primaryImageView.image = img
                        self.positionNearMouse(panelWidth: Self.tooltipWidth)
                        self.orderFront(nil)
                        self.startMaxDurationTimer()
                        if showTriple {
                            self.scheduleGolden(cardId: cardId)
                        }
                    }
                } else {
                    ImageUtils.cardArt(for: cardId) { [weak self] img in
                        DispatchQueue.main.async {
                            guard let self = self, self.currentCardId == cardId else { return }
                            self.primaryImageView.image = img
                            self.positionNearMouse(panelWidth: Self.tooltipWidth)
                            self.orderFront(nil)
                            self.startMaxDurationTimer()
                            self.scheduleGolden(cardId: cardId)
                        }
                    }
                }
            }
        }
        pendingShowWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.showDelay, execute: work)
    }

    // After goldenDelay seconds, shows the golden (triple upgrade) card ALONGSIDE the base
    // card — matching CardTooltip.xaml's DockPanel with both images side by side.
    // Resolves the triple card via baconTripleUpgradeMinionId; silently does nothing if
    // the card has no triple upgrade or the art is unavailable.
    private func scheduleGolden(cardId: String) {
        pendingGoldenWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.currentCardId == cardId else { return }
            self.pendingGoldenWork = nil
            guard let card = Cards.by(cardId: cardId),
                  card.baconTripleUpgradeMinionId != 0,
                  let golden = Cards.by(dbfId: card.baconTripleUpgradeMinionId, collectible: false) else { return }
            let goldenCardId = golden.id

            func apply(_ img: NSImage) {
                DispatchQueue.main.async {
                    guard self.currentCardId == cardId else { return }
                    let w = Self.tooltipWidth
                    let h = Self.tooltipHeight
                    self.goldenImageView.image = img
                    // Expand to double width: golden on left, base card on right
                    self.positionNearMouse(panelWidth: w * 2)
                    self.goldenImageView.frame = NSRect(x: 0, y: 0, width: w, height: h)
                    self.primaryImageView.frame = NSRect(x: w, y: 0, width: w, height: h)
                }
            }

            // Mirrors HDT's cardImageDownloader URL formula: bgs endpoint (these are
            // always Battlegrounds cards) with "_triple" appended to the *golden* card's
            // own id (which is itself a distinct CardID, e.g. "BG20_100_G" — not the base
            // card's id) — verified against art.hearthstonejson.com directly:
            // bgs/.../BG20_100_G_triple.png → 200, while bgs/.../BG20_100_G.png (no
            // suffix) and render/.../BG20_100_G_triple.png both 404.
            ImageUtils.cardArtBG(for: goldenCardId, baconTriple: true) { img in
                if let img = img {
                    apply(img)
                } else {
                    ImageUtils.cardArt(for: goldenCardId) { img in
                        guard let img = img else { return }
                        apply(img)
                    }
                }
            }
        }
        pendingGoldenWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.goldenDelay, execute: work)
    }

    func hide() {
        pendingShowWork?.cancel()
        pendingShowWork = nil
        pendingHideWork?.cancel()
        pendingHideWork = nil
        pendingGoldenWork?.cancel()
        pendingGoldenWork = nil
        maxDurationTimer?.invalidate()
        maxDurationTimer = nil
        currentCardId = nil
        let w = Self.tooltipWidth
        let h = Self.tooltipHeight
        primaryImageView.image = nil
        goldenImageView.image = nil
        goldenImageView.frame = .zero
        primaryImageView.frame = NSRect(x: 0, y: 0, width: w, height: h)
        orderOut(nil)
    }

    private func startMaxDurationTimer() {
        maxDurationTimer?.invalidate()
        maxDurationTimer = Timer.scheduledTimer(withTimeInterval: Self.maxDuration, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }

    func hide(ifShowing cardId: String) {
        pendingShowWork?.cancel()
        pendingShowWork = nil
        pendingGoldenWork?.cancel()
        pendingGoldenWork = nil

        guard currentCardId == cardId else { return }

        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.pendingHideWork = nil
            guard self.currentCardId == cardId else { return }
            self.currentCardId = nil
            let w = Self.tooltipWidth
            let h = Self.tooltipHeight
            self.primaryImageView.image = nil
            self.goldenImageView.image = nil
            self.goldenImageView.frame = .zero
            self.primaryImageView.frame = NSRect(x: 0, y: 0, width: w, height: h)
            self.orderOut(nil)
        }
        pendingHideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.hideDelay, execute: work)
    }

    private func positionNearMouse(panelWidth: CGFloat) {
        let mousePoint = NSEvent.mouseLocation
        let h = Self.tooltipHeight
        var origin = NSPoint(
            x: mousePoint.x - panelWidth - 20,
            y: mousePoint.y - h / 2
        )
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            origin.x = max(frame.minX, origin.x)
            origin.y = max(frame.minY, min(frame.maxY - h, origin.y))
        }
        setFrame(NSRect(origin: origin, size: CGSize(width: panelWidth, height: h)), display: true)
    }
}

// MARK: - Hover tracking (scale effect only)

// Used only for the minion-tile scale-on-hover cosmetic effect. An NSTrackingArea
// is more reliable here than SwiftUI's .onHover because it fires even while the
// app is in the background (the overlay window is non-activating).
@available(macOS 10.15, *)
final class HoverTrackingNSView: NSView {
    var onHover: ((Bool) -> Void)?
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

    override func mouseEntered(with event: NSEvent) { onHover?(true) }
    override func mouseExited(with event: NSEvent) { onHover?(false) }
}

@available(macOS 10.15, *)
private struct HoverTrackingRepresentable: NSViewRepresentable {
    let onHover: (Bool) -> Void

    func makeNSView(context: Context) -> HoverTrackingNSView {
        HoverTrackingNSView()
    }

    func updateNSView(_ nsView: HoverTrackingNSView, context: Context) {
        nsView.onHover = onHover
    }
}

@available(macOS 10.15, *)
extension View {
    func trackHover(_ onHover: @escaping (Bool) -> Void) -> some View {
        background(HoverTrackingRepresentable(onHover: onHover))
    }
}

// MARK: - Public modifier

@available(macOS 10.15, *)
private struct CardImageTooltipModifier: ViewModifier {
    let cardId: String?
    let showTriple: Bool

    func body(content: Content) -> some View {
        if let cardId = cardId {
            content.background(CardHoverRepresentable(cardId: cardId, showTriple: showTriple))
        } else {
            content
        }
    }
}

@available(macOS 10.15, *)
extension View {
    func cardImageTooltip(cardId: String?, showTriple: Bool = true) -> some View {
        modifier(CardImageTooltipModifier(cardId: cardId, showTriple: showTriple))
    }
}
