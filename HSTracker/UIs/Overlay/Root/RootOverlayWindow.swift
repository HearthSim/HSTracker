//
//  RootOverlayWindow.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI
import Combine
import Foundation

@available(macOS 10.15, *)
class RootOverlayWindow: OverWindowController {
    var hostingView: NSHostingView<RootOverlayView>!
    let viewModel = RootOverlayViewModel()

    private var regionSubscription: AnyCancellable?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var fallbackTimer: Timer?
    private var hoveredCardId: String?

    override func windowDidLoad() {
        super.windowDidLoad()
        hostingView = NSHostingView(rootView: RootOverlayView(viewModel: viewModel))
        window?.contentView = hostingView
        window?.isOpaque = false
        window?.backgroundColor = .clear
        // RootOverlay spans the whole Hearthstone client area and stays
        // click-through by default - ignoresMouseEvents is a window-level
        // switch, not per-view, so it can't be flipped wholesale without
        // blocking clicks over the rest of the game window too. Instead we
        // track the live cursor position (installMouseMonitors below) and
        // flip it on/off only while the cursor is actually over a child that
        // reported itself as interactive (see InteractiveRegionPreferenceKey
        // in RootOverlayView) - everywhere else stays click-through down to
        // the pixel, including right up to that child's own edge.
        window?.ignoresMouseEvents = true
        installMouseMonitors()
    }

    deinit {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        fallbackTimer?.invalidate()
    }

    private func installMouseMonitors() {
        // Global monitor: fires for mouse moves anywhere on screen while this
        // app isn't the event's destination (e.g. cursor is over Hearthstone,
        // or over empty click-through overlay space). This is what detects
        // the cursor entering the interactive region from outside.
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.updateMouseThrough()
        }
        // Local monitor: fires once ignoresMouseEvents is already false and
        // this window is the destination, so the global monitor above no
        // longer sees these moves - needed to detect the cursor leaving the
        // region again.
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.updateMouseThrough()
            return event
        }
        regionSubscription = viewModel.$interactiveRegion.sink { [weak self] _ in
            self?.updateMouseThrough()
        }
        // Backstop: mouse-moved monitors should keep ignoresMouseEvents in
        // sync on their own, but if either failed to register (or events get
        // dropped for some reason) this guarantees convergence within
        // ~150ms instead of the window getting stuck non-click-through.
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.updateMouseThrough()
        }
    }

    private func updateMouseThrough() {
        guard let window = window, let hostingView = hostingView else { return }
        let screenLocation = NSEvent.mouseLocation
        let windowPoint = window.convertPoint(fromScreen: screenLocation)
        let viewPoint = hostingView.convert(windowPoint, from: nil)

        updateFilterRegionHover(at: viewPoint)

        guard let region = viewModel.interactiveRegion else {
            setIgnoresMouseEvents(true)
            return
        }
        let inside = region.contains(viewPoint)
        setIgnoresMouseEvents(!inside)

        updateCardHover()
    }

    // HDT's BgsTopBarMask MouseEnter/MouseLeave handlers, which flip
    // BattlegroundsMinionsVM.IsFilterRegionHovered to slide the minion browser's
    // filter button in and out.
    //
    // Driven from the cursor position tracked here rather than from a SwiftUI
    // .onHover, because the mask deliberately stays click-through
    // (IsHitTestVisible="False" on HDT's side): .onHover only fires once
    // ignoresMouseEvents is already false, so it would never see the cursor over
    // the part of the mask outside the panel - which is exactly where the button
    // slides out to. Called before the interactiveRegion guard below so it keeps
    // running while the overlay is fully click-through.
    private func updateFilterRegionHover(at viewPoint: NSPoint) {
        let hovering = viewModel.hoverRegion?.contains(viewPoint) ?? false
        let minions = viewModel.battlegroundsMinionsGuide
        guard minions.isFilterRegionHovered != hovering else { return }
        // Durations match the tab's own slide storyboard: 0.2s out, 0.4s back.
        withAnimation(.easeOut(duration: hovering ? 0.2 : 0.4)) {
            minions.isFilterRegionHovered = hovering
        }
    }

    private func setIgnoresMouseEvents(_ ignores: Bool) {
        if window?.ignoresMouseEvents != ignores {
            window?.ignoresMouseEvents = ignores
        }
    }

    // Matches the live cursor position (already computed above for the
    // click-through check) against every currently-reported card hover
    // region and drives CardTooltipPanel directly - see the comment atop
    // CardHoverRegionPreferenceKey in CardImageTooltip.swift for why this
    // replaces a per-view hover callback.
    // Matches the live cursor against registered CardHoverNSView instances using
    // CALayer coordinate conversion. layer.convert(bounds, to: rootLayer) goes
    // through the full CALayer transform chain - including SwiftUI's scaleEffect
    // and NSScrollView's scroll offset - giving the correct visual position.
    // The final comparison is in screen coordinates (Y-up, Cocoa convention)
    // using NSEvent.mouseLocation, avoiding any NSView/SwiftUI coordinate space
    // issues entirely.
    private func updateCardHover() {
        guard let overlayWindow = window else { return }
        let screenLocation = NSEvent.mouseLocation

        let match = CardHoverRegistry.shared.entries.first { entry in
            guard let nsView = entry.view,
                  nsView.window === overlayWindow else { return false }
            // NSView.convert(to: nil) → window base coordinates (Y-up from
            // window bottom, flips handled by AppKit automatically).
            // convertToScreen → screen coordinates (same Y-up convention).
            // NSEvent.mouseLocation is also Y-up screen coordinates.
            let rectInWindow = nsView.convert(nsView.bounds, to: nil)
            let screenRect = overlayWindow.convertToScreen(rectInWindow)
            return screenRect.contains(screenLocation)
        }

        if let match = match {
            if hoveredCardId != match.cardId {
                hoveredCardId = match.cardId
                CardTooltipPanel.shared.show(cardId: match.cardId)
            }
        } else {
            if hoveredCardId != nil {
                hoveredCardId = nil
                // Unconditional hide: we know no card is under cursor, so we must
                // dismiss regardless of which card (base or golden) is currently shown.
                CardTooltipPanel.shared.hide()
            }
            // Force-hide if the tooltip's current card is no longer registered.
            // Fires at most every 150ms via the fallback timer and catches the
            // race where hide(ifShowing:) returned early because currentCardId
            // was a different card than the one whose view was removed (e.g.
            // the guide navigated away while a new 300ms show-delay was still
            // in flight for a different hovered card).
            let registry = CardHoverRegistry.shared
            if let shown = CardTooltipPanel.shared.currentCardId,
               !registry.entries.contains(where: { $0.cardId == shown && $0.view != nil }) {
                CardTooltipPanel.shared.hide()
            }
        }
    }
}
