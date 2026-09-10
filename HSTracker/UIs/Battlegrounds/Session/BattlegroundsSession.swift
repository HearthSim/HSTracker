//
//  BattlegroundsSession.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/12/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// Hosts the SwiftUI session recap panel (BattlegroundsSessionView, a port of
// HDT's BattlegroundsSession.xaml) in the draggable, user-positionable overlay
// window HSTracker has always shown it in. Everything that used to be wired up
// through BattlegroundsSession.xib now lives in BattlegroundsSessionViewModel;
// this class is only the window, the scaling, and the mouse tracking.
//
// The class itself is not gated on macOS 10.15 because WindowManager and Game
// reference it unconditionally from dozens of places; the SwiftUI content is,
// so on 10.14 the window simply stays empty.
class BattlegroundsSession: OverWindowController {
    private var _viewModel: Any?
    // update() reaches this from whichever thread the log reader is on, before
    // the window (and with it windowDidLoad) has necessarily loaded, so the
    // lazy creation below has to be serialised or two callers can end up with
    // two different view models.
    private let viewModelLock = UnfairLock()
    private var hostingView: NSView?

    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var fallbackTimer: Timer?
    private var hoverSubscription: Any?
    private var _finalBoardPanel: Any?

    @available(macOS 10.15, *)
    var viewModel: BattlegroundsSessionViewModel {
        viewModelLock.lock()
        defer {
            viewModelLock.unlock()
        }
        if let existing = _viewModel as? BattlegroundsSessionViewModel {
            return existing
        }
        let created = BattlegroundsSessionViewModel()
        _viewModel = created
        return created
    }

    var visibility = false

    var battlegroundsGameMode: SelectedBattlegroundsGameMode {
        get {
            if #available(macOS 10.15, *) {
                return viewModel.battlegroundsGameMode
            }
            return .unknown
        }
        set {
            if #available(macOS 10.15, *) {
                viewModel.battlegroundsGameMode = newValue
            }
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        window?.isOpaque = false
        window?.backgroundColor = .clear

        if #available(macOS 10.15, *) {
            let hosting = NSHostingView(rootView: BattlegroundsSessionRootView(viewModel: viewModel))
            window?.contentView = hosting
            hostingView = hosting
            // The panel is a small box inside a window that spans the whole
            // left edge of the Hearthstone client, so the window cannot simply
            // take mouse events wholesale - everything outside the panel has to
            // keep falling through to the game. installMouseMonitors tracks the
            // cursor and flips ignoresMouseEvents only over the panel itself,
            // the same trick RootOverlayWindow uses.
            window?.ignoresMouseEvents = true
            installMouseMonitors()
            hoverSubscription = viewModel.$hoveredGame.sink { [weak self] hovered in
                self?.updateFinalBoard(hovered)
            }
        }
    }

    @available(macOS 10.15, *)
    private var finalBoardPanel: BattlegroundsFinalBoardPanel {
        if let existing = _finalBoardPanel as? BattlegroundsFinalBoardPanel {
            return existing
        }
        let created = BattlegroundsFinalBoardPanel()
        _finalBoardPanel = created
        return created
    }

    // HDT's BattlegroundsGameViewModel.OnMouseEnter / OnMouseLeave, applied to
    // the tooltip's own window rather than to a canvas inside the panel.
    @available(macOS 10.15, *)
    private func updateFinalBoard(_ hovered: HoveredGame?) {
        guard let window, let hostingView else { return }
        guard let hovered, window.isVisible else {
            finalBoardPanel.hide()
            return
        }
        finalBoardPanel.show(minions: hovered.viewModel.finalBoardMinions,
                             tooltipToRight: viewModel.tooltipToRight,
                             rowFrame: hovered.frame,
                             in: hostingView,
                             scaling: CGFloat(viewModel.scaling),
                             parent: window)
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

    // MARK: - Final board

    // MARK: - Mouse tracking

    @available(macOS 10.15, *)
    private func installMouseMonitors() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.updateMouseThrough()
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.updateMouseThrough()
            return event
        }
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.updateMouseThrough()
        }
    }

    @available(macOS 10.15, *)
    private func updateMouseThrough() {
        guard let window, let hostingView, window.isVisible else { return }
        // Unlocked windows are meant to be grabbed and dragged anywhere, so
        // they keep taking every event, exactly as they did before.
        if !Settings.windowsLocked {
            setIgnoresMouseEvents(false)
            return
        }
        let screenLocation = NSEvent.mouseLocation
        let windowPoint = window.convertPoint(fromScreen: screenLocation)
        let viewPoint = hostingView.convert(windowPoint, from: nil)
        let inside = viewModel.panelRegion.contains(viewPoint)
        setIgnoresMouseEvents(!inside)
        // Backstop for the tooltip: the window going click-through again should
        // deliver a SwiftUI hover-exit, but if that is missed the tooltip would
        // be left on screen with the cursor nowhere near it.
        if !inside && viewModel.hoveredGame != nil {
            viewModel.hoveredGame = nil
        }
    }

    private func setIgnoresMouseEvents(_ ignores: Bool) {
        if window?.ignoresMouseEvents != ignores {
            window?.ignoresMouseEvents = ignores
        }
    }

    // MARK: - Entry points used by Game / CoreManager / preferences

    @MainActor
    func updateScaling() {
        guard #available(macOS 10.15, *) else { return }
        viewModel.scaling = Settings.battlegroundsSessionScaling
        updateTooltipSide()
    }

    // HDT's `tooltipToRight`: a final board opens to the right of the panel
    // unless the panel itself sits in the right half of the Hearthstone window,
    // in which case it would run off-screen and opens to the left instead.
    @MainActor
    private func updateTooltipSide() {
        guard #available(macOS 10.15, *), let window else { return }
        let hearthstoneFrame = SizeHelper.hearthstoneWindow.frame
        viewModel.tooltipToRight = window.frame.minX < hearthstoneFrame.midX
    }

    func onGameStart() {
        guard #available(macOS 10.15, *) else { return }
        DispatchQueue.main.async {
            self.viewModel.onGameStart()
            self.updateScaling()
        }
    }

    func onGameEnd(gameStats: InternalGameStats) {
        guard #available(macOS 10.15, *) else { return }
        DispatchQueue.main.async {
            self.viewModel.onGameEnd()
            self.updateScaling()
        }
    }

    @MainActor
    func show() {
        guard #available(macOS 10.15, *) else { return }
        if window?.occlusionState.contains(.visible) ?? false || AppDelegate.instance().coreManager.game.spectator {
            return
        }
        updateSectionsVisibilities()
        update()
        updateScaling()
    }

    @MainActor
    func updateSectionsVisibilities() {
        guard #available(macOS 10.15, *) else { return }
        viewModel.updateSectionsVisibilities()
    }

    func update() {
        guard #available(macOS 10.15, *) else { return }
        viewModel.update()
    }

    @available(macOS 10.15, *)
    func updateCompositionStatsVisibility() async {
        await viewModel.updateCompositionStatsVisibility()
    }

    @MainActor
    func hideCompStatsOnError() {
        guard #available(macOS 10.15, *) else { return }
        viewModel.hideCompStatsOnError()
    }
}

// The session window spans a tall strip down the left of the Hearthstone
// client (SizeHelper.battlegroundsSessionFrame), with the panel pinned to its
// top-left corner and scaled by the user's Battlegrounds scaling setting -
// which is what the old AppKit code did by hand in updateScaling().
@available(macOS 10.15, *)
struct BattlegroundsSessionRootView: View {
    @ObservedObject var viewModel: BattlegroundsSessionViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            BattlegroundsSessionView(viewModel: viewModel)
                // Measured before the scale is applied - scaleEffect is a
                // render-time transform that leaves the layout size alone -
                // so the view model multiplies it back out itself.
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: SessionPanelSizePreferenceKey.self,
                                               value: proxy.size)
                    }
                )
                .scaleEffect(CGFloat(viewModel.scaling), anchor: .topLeading)
        }
        .onPreferenceChange(SessionPanelSizePreferenceKey.self) { size in
            viewModel.panelSize = size ?? .zero
        }
    }
}

// How big the panel came out, so the window knows which pixels should stop
// being click-through.
@available(macOS 10.15, *)
private struct SessionPanelSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize?
    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
        if let next = nextValue() {
            value = next
        }
    }
}
