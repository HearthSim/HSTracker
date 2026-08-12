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
        guard let region = viewModel.interactiveRegion else {
            setIgnoresMouseEvents(true)
            return
        }
        let screenLocation = NSEvent.mouseLocation
        let windowPoint = window.convertPoint(fromScreen: screenLocation)
        let viewPoint = hostingView.convert(windowPoint, from: nil)
        let inside = region.contains(viewPoint)
        setIgnoresMouseEvents(!inside)
    }

    private func setIgnoresMouseEvents(_ ignores: Bool) {
        if window?.ignoresMouseEvents != ignores {
            window?.ignoresMouseEvents = ignores
        }
    }
}
