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
    private weak var hoveredView: CardHoverNSView?

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
        regionSubscription = viewModel.$interactiveRegions.sink { [weak self] _ in
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
        updateArenaPanelHover(at: viewPoint)
        updateArenaDirectionTrigger(at: viewPoint)
        updateArenaCardListTrigger(at: viewPoint)
        updateArenaTooltipHover(at: viewPoint)

        guard !viewModel.interactiveRegions.isEmpty else {
            setIgnoresMouseEvents(true)
            return
        }
        let inside = viewModel.interactiveRegions.contains { $0.contains(viewPoint) }
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

    // The Arena bottom panel opens on the *in-game* hover (the mirror reports
    // which choice the player's cursor is over), then stays up while the pointer
    // is on the panel itself so it can be read and scrolled. Tracked here rather
    // than with .onHover for the same reason as the filter region above: the
    // panel stays click-through, so .onHover would never fire.
    private var _arenaDirectionWatcher: Any?
    private var arenaDirectionInside = false
    private var arenaDirectionArmPending = false

    private func updateArenaPanelHover(at viewPoint: NSPoint) {
        guard #available(macOS 10.15, *) else { return }
        let hovering = viewModel.arenaBottomPanelFrame?.contains(viewPoint) ?? false
        let pickHelper = viewModel.arenaPickHelper
        guard pickHelper.hoveringPanel != hovering else { return }
        pickHelper.hoveringPanel = hovering
    }

    // HDT's BottomDirectionTrigger: a trapezoid funnel from the hovered choice
    // down to the bottom panel, which keeps the panel open while the cursor is on
    // its way there. Without it the panel closes the instant the in-game hover
    // ends and can never be reached.
    //
    // WPF gets enter/leave events; here the cursor is sampled, so the previous
    // inside/outside state is tracked to derive the same edges - otherwise the
    // watcher's timeout would immediately re-arm while the cursor sat still
    // inside the shape.
    private var arenaDirectionWatcher: ArenaMouseDirectionWatcher {
        if let existing = _arenaDirectionWatcher as? ArenaMouseDirectionWatcher { return existing }
        let watcher = ArenaMouseDirectionWatcher()
        watcher.onTimeout = { [weak self] in self?.endArenaDirectionTrigger() }
        watcher.onDirectionChange = { [weak self] direction in
            // Heading back up is heading away from the panel.
            if direction.contains(.up) { self?.endArenaDirectionTrigger() }
        }
        _arenaDirectionWatcher = watcher
        return watcher
    }

    @available(macOS 10.15, *)
    private func endArenaDirectionTrigger() {
        arenaDirectionWatcher.stop()
        arenaDirectionArmPending = false
        viewModel.arenaPickHelper.hoveringBottomDirectionTrigger = false
    }

    private func updateArenaDirectionTrigger(at viewPoint: NSPoint) {
        guard #available(macOS 10.15, *) else { return }
        let pickHelper = viewModel.arenaPickHelper
        let shape = viewModel.arenaDirectionTriggerShape
        let inside = !shape.isEmpty && Self.polygon(shape, contains: viewPoint)

        if inside && !arenaDirectionInside {
            pickHelper.hoveringBottomDirectionTrigger = true
            arenaDirectionWatcher.stop()
            // The funnel overlaps the choice itself, so the watcher only starts
            // once the in-game hover has ended - otherwise it would time out
            // while the cursor was still sitting on the card.
            arenaDirectionArmPending = true
        } else if !inside && arenaDirectionInside {
            endArenaDirectionTrigger()
        }
        arenaDirectionInside = inside

        if inside, arenaDirectionArmPending, pickHelper.hoveredChoice == nil {
            arenaDirectionArmPending = false
            arenaDirectionWatcher.start()
        }
    }

    // HDT's CardListDirectionTriggers: three wedges, one per choice, widening from
    // the choice across to the deck rail. They keep the rail's synergy highlights
    // up while the cursor travels there, the same way the bottom funnel keeps the
    // panel open. Alongside them the rail itself is a plain hover region.
    //
    // Three watchers rather than one: HDT gives each trigger its own, and their
    // shapes overlap, so the cursor can be inside two at once.
    private var _arenaCardListWatchers: [Any] = []
    private var arenaCardListInside = [false, false, false]
    private var arenaCardListArmPending = [false, false, false]

    @available(macOS 10.15, *)
    private func arenaCardListWatcher(_ index: Int) -> ArenaMouseDirectionWatcher {
        if let existing = _arenaCardListWatchers[safeIndex: index] as? ArenaMouseDirectionWatcher {
            return existing
        }
        let watchers = (0..<3).map { idx -> ArenaMouseDirectionWatcher in
            let watcher = ArenaMouseDirectionWatcher()
            watcher.onTimeout = { [weak self] in self?.endArenaCardListDirection(idx) }
            watcher.onDirectionChange = { [weak self] direction in
                // The rail is on the right, so heading left is heading away.
                if direction.contains(.left) { self?.endArenaCardListDirection(idx) }
            }
            return watcher
        }
        _arenaCardListWatchers = watchers
        return watchers[index]
    }

    @available(macOS 10.15, *)
    private func endArenaCardListDirection(_ index: Int) {
        arenaCardListWatcher(index).stop()
        arenaCardListArmPending[index] = false
        viewModel.arenaPickHelper.setHoveringCardListDirection(index, false)
    }

    private func updateArenaCardListTrigger(at viewPoint: NSPoint) {
        guard #available(macOS 10.15, *) else { return }
        let pickHelper = viewModel.arenaPickHelper

        let onRail = viewModel.arenaCardListTriggerFrame?.contains(viewPoint) ?? false
        if pickHelper.hoveringCardList != onRail {
            pickHelper.hoveringCardList = onRail
        }

        for index in 0..<3 {
            let shape = viewModel.arenaCardListDirectionShapes[safeIndex: index] ?? []
            let inside = !shape.isEmpty && Self.polygon(shape, contains: viewPoint)

            if inside && !arenaCardListInside[index] {
                pickHelper.setHoveringCardListDirection(index, true)
                arenaCardListWatcher(index).stop()
                // As with the bottom funnel: the wedge covers the choice itself,
                // so the watcher waits for the in-game hover to end rather than
                // timing out while the cursor is still on the card.
                arenaCardListArmPending[index] = true
            } else if !inside && arenaCardListInside[index] {
                endArenaCardListDirection(index)
            }
            arenaCardListInside[index] = inside

            if inside, arenaCardListArmPending[index], pickHelper.hoveredChoice == nil {
                arenaCardListArmPending[index] = false
                arenaCardListWatcher(index).start()
            }
        }
    }

    // HDT's OverlayExtensions.IsOverlayHoverVisible regions - the three badges
    // under each offered card and each deck-rail synergy marker. Hover-visible is
    // not the same as hit-test visible: the region reacts to the cursor without
    // taking the click, so this samples rather than flipping ignoresMouseEvents.
    private func updateArenaTooltipHover(at viewPoint: NSPoint) {
        guard #available(macOS 10.15, *) else { return }
        // `last`, not `first`: regions are reported in view-tree order, so a later
        // sibling is the one drawn on top and the one WPF's hit-testing would pick.
        let match = viewModel.arenaTooltipRegions.last { $0.frame.contains(viewPoint) }
        let pickHelper = viewModel.arenaPickHelper
        if pickHelper.hoveredTooltip != match?.target {
            pickHelper.hoveredTooltip = match?.target
        }
    }

    /// Ray casting - the shape is a trapezoid, so a bounding box would not do.
    private static func polygon(_ points: [CGPoint], contains point: NSPoint) -> Bool {
        guard points.count > 2 else { return false }
        var inside = false
        var j = points.count - 1
        for i in 0..<points.count {
            let a = points[i], b = points[j]
            if (a.y > point.y) != (b.y > point.y),
               point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x {
                inside.toggle()
            }
            j = i
        }
        return inside
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

        // `last`, not `first`: the Inspiration board overlaps its tiles by 8pt
        // (HDT's Margin="-4,0"), so two entries can contain the cursor at once.
        // Registration follows view-tree order, and a later sibling draws on
        // top - which is the one WPF's hit-testing would pick. Everywhere else
        // the tiles do not overlap, so at most one entry ever matches and this
        // is the same as before.
        let match = CardHoverRegistry.shared.entries.last { entry in
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
            // Keyed on the matched view as well as the card: an Inspiration board
            // routinely holds two copies of the same minion, and now that the
            // tooltip anchors to the element rather than following the cursor,
            // moving between them has to re-anchor it. HDT gets this for free -
            // each element raises its own MouseLeave/MouseEnter.
            if hoveredCardId != match.cardId || hoveredView !== match.view {
                hoveredCardId = match.cardId
                hoveredView = match.view
                // HDT anchors the tooltip to the hovered element and clamps it to
                // the overlay window (its ActualWidth/ActualHeight), not to the
                // screen - so both rects are handed over here, in the screen
                // coordinates the panel positions itself in.
                let anchor = match.view.map {
                    overlayWindow.convertToScreen($0.convert($0.bounds, to: nil))
                }
                CardTooltipPanel.shared.show(cardId: match.cardId, showTriple: match.showTriple,
                                             baconTriple: match.baconTriple,
                                             placement: match.placement,
                                             anchor: anchor, bounds: overlayWindow.frame)
            }
        } else {
            if hoveredCardId != nil {
                hoveredCardId = nil
                hoveredView = nil
                // Unconditional hide: we know no card is under cursor, so we must
                // dismiss regardless of which card (base or golden) is currently shown.
                // Scoped to this source, though - the cursor leaving the canvas is routinely the
                // cursor arriving somewhere that drives the same panel itself.
                CardTooltipPanel.shared.hide(from: .registry)
            }
            // Force-hide if the tooltip's current card is no longer registered.
            // Fires at most every 150ms via the fallback timer and catches the
            // race where hide(ifShowing:) returned early because currentCardId
            // was a different card than the one whose view was removed (e.g.
            // the guide navigated away while a new 300ms show-delay was still
            // in flight for a different hovered card).
            // Scoped the same way: "not in the registry" only means "gone" for a tooltip the
            // registry started.
            let registry = CardHoverRegistry.shared
            if let shown = CardTooltipPanel.shared.currentCardId,
               !registry.entries.contains(where: { $0.cardId == shown && $0.view != nil }) {
                CardTooltipPanel.shared.hide(from: .registry)
            }
        }
    }
}
