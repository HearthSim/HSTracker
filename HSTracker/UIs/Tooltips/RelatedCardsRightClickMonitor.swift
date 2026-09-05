//
//  RelatedCardsRightClickMonitor.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/27/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit

// Ports HDT's OverlayWindow.Input.cs right-click handling (PollRightClick/
// StartRightClickPolling/_hoveredLargePoolCard/_hoveredLargePoolCards) to macOS.
//
// HDT's overlay window is click-through, so a normal WPF mouse-event handler can never see a
// right-click that lands on the game window underneath it - it works around this with a ~16ms
// poll of the raw OS right-mouse-button state, gated on Hearthstone being frontmost, the overlay
// being visible, a large-pool card currently hovered, and Config.Instance.OutfinderEnabled.
//
// RelatedCardsTooltipPanel is click-through the same way (ignoresMouseEvents = true), so the same
// problem applies here. An NSEvent.addGlobalMonitorForEvents(.rightMouseDown) monitor was tried
// first, but it's a single edge-triggered snapshot: Game.swift's own hovered-card tracking (driven
// by the game's log-read state, see onBigCardChange) clears the instant Hearthstone stops
// reporting a hover - which a physical mouse-down transiently does on some cards - and
// updateTooltips() clears this monitor's state synchronously and immediately on that same edge (no
// debounce, unlike the 400ms delay on the show path). A single-shot listener has no chance to
// catch a click landing inside that blip. Polling NSEvent.pressedMouseButtons instead - the same
// "read the live OS button state" idea as HDT's IsRightMouseButtonDown(), and
// RootOverlayWindow.swift's own installMouseMonitors() comment documents this exact class of
// failure mode as the reason it keeps a fallback timer for its .mouseMoved global monitor - checks
// repeatedly for the ~100ms+ a physical click is normally held, so it isn't defeated by one bad
// tick the way a single event delivery is. It also needs no Accessibility/Input Monitoring grant,
// unlike observing another app's events via a monitor.
final class RelatedCardsRightClickMonitor {
    static let shared = RelatedCardsRightClickMonitor()

    private static let pollInterval: TimeInterval = 0.016 // matches HDT's RightClickPollInterval
    private static let rightButtonBit = 0x2

    private var pollTimer: Timer?
    private var rightButtonWasDown = false
    private var hoveredCard: Card?
    private var hoveredPool: [Card] = []
    private var anchorFrame: NSRect = .zero

    private init() {}

    /// Called from every path that shows the compact related-cards tooltip (Game.swift's
    /// tooltipDisplay() hand/secret branches and setRelatedCardsTrigger, Tracker.swift's
    /// deck-list hover) each time it decides whether it's showing a large pool - mirrors HDT's
    /// SetHoveredLargePool(Card?, List<Card>?), including the same nil/empty-pool "nothing
    /// hovered" state used to clear it.
    func setHoveredLargePool(card: Card?, pool: [Card], anchorFrame: NSRect) {
        hoveredCard = card
        hoveredPool = pool
        self.anchorFrame = anchorFrame
        startPolling()
    }

    func clearHoveredLargePool() {
        hoveredCard = nil
        hoveredPool = []
    }

    // Left running for the app's lifetime once started, exactly like HDT's poll loop - the
    // per-tick guards in pollRightClick() do the actual gating, not whether the timer is alive.
    private func startPolling() {
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            self?.pollRightClick()
        }
    }

    private func pollRightClick() {
        let isDown = NSEvent.pressedMouseButtons & Self.rightButtonBit != 0
        let pressed = isDown && !rightButtonWasDown
        rightButtonWasDown = isDown

        guard pressed else { return }
        // Mirrors PollRightClick's guard order: frontmost app, the setting gate, then whether a
        // large-pool card is actually hovered right now. HDT checks Config.Instance.OutfinderEnabled
        // alone here; showPlayerRelatedCards is kept alongside it because the pool that would be
        // browsed only ever gets set by a tooltip that setting already gates.
        guard CoreManager.isHearthstoneActive() else { return }
        guard Settings.outfinderEnabled else { return }
        guard Settings.showPlayerRelatedCards else { return }
        guard let card = hoveredCard, !hoveredPool.isEmpty else { return }

        if #available(macOS 10.15, *) {
            RelatedCardsBrowserPanel.shared.show(sourceCard: card, relatedCards: hoveredPool, near: anchorFrame)
        }
    }
}
