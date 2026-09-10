//
//  BattlegroundsSessionOverlayView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Places the session panel on the RootOverlay canvas, which is HSTracker's
// equivalent of HDT's OverlayWindow canvas.
//
// HDT positions it with
//   Canvas.SetTop(BattlegroundsSessionStackPanel, Height * SessionRecapTop / 100)
//   Canvas.SetLeft(BattlegroundsSessionStackPanel, Width * SessionRecapLeft / 100)
// (OverlayWindow.Update.cs) and lets the player drag it while the overlay is
// unlocked, writing the new percentages back. This does the same, with
// Settings.windowsLocked standing in for HDT's _uiMovable.
//
// It deliberately lives in RootOverlayView's fixed-pixel chrome layer rather
// than its 1080-reference scaled subtree: HDT applies only
// OverlaySessionRecapScaling to this control, never a resolution scale.
@available(macOS 10.15, *)
struct BattlegroundsSessionOverlayView: View {
    @ObservedObject var viewModel: BattlegroundsSessionViewModel
    // The canvas's real, post-scale size - the same Width/Height HDT's
    // percentages are taken against.
    let canvasSize: CGSize

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it; it renders nothing (and reports no interactive region)
        // while the panel is not shown.
        ZStack(alignment: .topLeading) {
            Color.clear
            if viewModel.isShown {
                panel
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
        .onPreferenceChange(SessionPanelSizePreferenceKey.self) { size in
            viewModel.panelSize = size ?? .zero
        }
        // The panel takes clicks (the cog, and the drag below), so the overlay
        // window stops being click-through over it - see
        // InteractiveRegionPreferenceKey.
        //
        // Computed rather than read off a GeometryReader under the panel:
        // .offset and .scaleEffect are render-time transforms that leave the
        // layout alone, so a reader beneath them reports the panel's untouched
        // position and unscaled size. The origin and scale are known here, and
        // the panel's own (unscaled) size comes back through panelSize above.
        //
        // This is the one place the port diverges from HDT. HDT leaves the
        // session panel click-through and drives its hover from a 60Hz cursor
        // loop (OverlayWindow.MouseOverDetection) and its clicks and drags from
        // a global mouse hook (OverlayWindow.Input), so clicks over it still
        // reach Hearthstone. HSTracker has no synthesized-click machinery, and
        // the panel's own window already swallowed clicks over itself before it
        // moved onto this canvas, so claiming the region is both simpler and no
        // worse than what shipped.
        .preference(key: InteractiveRegionPreferenceKey.self, value: interactiveRegions)
    }

    // Canvas.SetLeft / Canvas.SetTop, in the canvas's real pixels.
    private var originX: CGFloat { canvasSize.width * CGFloat(viewModel.left) / 100.0 }
    private var originY: CGFloat { canvasSize.height * CGFloat(viewModel.top) / 100.0 }

    private var interactiveRegions: [CGRect] {
        guard viewModel.isShown, viewModel.panelSize.width > 0, viewModel.panelSize.height > 0 else {
            return []
        }
        return [CGRect(x: originX, y: originY,
                       width: viewModel.panelSize.width * CGFloat(viewModel.scaling),
                       height: viewModel.panelSize.height * CGFloat(viewModel.scaling))]
    }

    private var panel: some View {
        BattlegroundsSessionView(viewModel: viewModel)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: SessionPanelSizePreferenceKey.self,
                                           value: proxy.size)
                }
            )
            // anchor: .topLeading so the panel's corner stays on the offset
            // origin, which is what the region above assumes.
            .scaleEffect(CGFloat(viewModel.scaling), anchor: .topLeading)
            .offset(x: originX, y: originY)
            .gesture(dragGesture, including: Settings.windowsLocked ? .none : .all)
    }

    // HDT only moves overlay elements while the overlay is unlocked
    // (_uiMovable, toggled from the same place HSTracker toggles
    // Settings.windowsLocked), and saves the config on mouse up.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard !Settings.windowsLocked else { return }
                viewModel.drag(translation: value.translation, canvasSize: canvasSize)
            }
            .onEnded { _ in
                viewModel.endDrag()
            }
    }
}

// The panel's laid-out (unscaled) size, so the interactive region can be worked
// out without reading through the transforms that place it.
@available(macOS 10.15, *)
private struct SessionPanelSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize?
    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
        if let next = nextValue() {
            value = next
        }
    }
}
