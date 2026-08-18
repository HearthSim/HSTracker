//
//  RootOverlayView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Reports the on-screen frame (in RootOverlayCanvasSpace - the outer
// GeometryReader's own bounds, i.e. real post-scale pixels matching the
// NSHostingView's local coordinate space) of whichever child currently needs
// real mouse interactivity. RootOverlayWindow reads this to know which
// pixels should stop being click-through - see its mouse-tracking comment.
@available(macOS 10.15, *)
struct InteractiveRegionPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect?
    // Unioned rather than overwritten: originally only one interactive child
    // was ever visible at a time (the pre-lobby widget XOR the trials-exhausted
    // alert), so last-write-wins was fine. The mulligan V2 card row reports one
    // region per offered card (up to 3 simultaneously), so they all need to
    // stay interactive together instead of only the last one evaluated.
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        if let next = nextValue() {
            value = value?.union(next) ?? next
        }
    }
}

@available(macOS 10.15, *)
extension CoordinateSpace {
    static let rootOverlayCanvas = CoordinateSpace.named("rootOverlayCanvas")
}

@available(macOS 10.15, *)
struct RootOverlayView: View {
    @ObservedObject var viewModel: RootOverlayViewModel
    var body: some View {
        // GeometryReader measures the real, current bounds NSHostingView gives this
        // view directly - scale/canvas are derived from that measurement and the
        // whole scaled subtree is explicitly centered on it with .position(), rather
        // than relying on NSHostingView's implicit placement of a fixed-size (canvas,
        // pre-scale) root view within its actual (post-scale) bounds, which doesn't
        // reliably line up.
        GeometryReader { geometry in
            let scale = geometry.size.height / 1080
            let canvasWidth = scale > 0 ? geometry.size.width / scale : geometry.size.width

            ZStack(alignment: .topLeading) {
                // Resolution-scaled, game-relative content (authored at the
                // 1080-tall reference) lives in this inner, transformed
                // subtree only.
                ZStack {
                    ConstructedMulliganGuideV2View(viewModel: viewModel.mulliganGuideV2)

                    // Wrapped in its own top-trailing-anchored ZStack rather
                    // than positioned directly: the outer ZStack here has no
                    // alignment of its own (its children default-center),
                    // and this panel needs to sit at the canvas's top-right
                    // corner, matching HDT's BgsTopBar (Canvas.Top="0"
                    // Canvas.Right="0" in Windows/OverlayWindow.xaml).
                    ZStack(alignment: .topTrailing) {
                        Color.clear
                        GuidesTabsView(viewModel: viewModel.battlegroundsGuidesTabs, compsGuides: viewModel.battlegroundsCompsGuides, heroGuides: viewModel.battlegroundsHeroGuides, questGuides: viewModel.battlegroundsQuestGuides, minionsGuide: viewModel.battlegroundsMinionsGuide)
                    }
                    .frame(width: canvasWidth, height: 1080)
                }
                .frame(width: canvasWidth, height: 1080)
                .scaleEffect(scale, anchor: .center)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                // Fixed-size UI chrome (not resolution-scaled game content) is
                // positioned directly in geometry's real, post-scale pixel
                // space instead of living inside the center-anchored
                // scaleEffect/position transform above (an offset applied
                // there gets pulled toward that transform's center anchor in
                // a non-obvious way). No explicit position/offset here at
                // all - the outer ZStack's .topLeading alignment already
                // anchors it at (0,0), matching HDT's own OverlayWindow.xaml
                // (`Canvas.Top="0" Canvas.Left="0"` on this exact widget).
                //
                // Always instantiated (not gated behind an `if` here) so their
                // own @ObservedObject binding reacts directly to view model
                // changes - see the comment on
                // ConstructedMulliganPreLobbyWidgetView.body for why gating
                // from out here doesn't work. Each view renders nothing (and
                // reports no interactive region) when its own isShown says
                // not to - see their own .background() for that reporting,
                // which is why none is attached out here.
                ConstructedMulliganPreLobbyWidgetView(viewModel: viewModel.constructedMulliganPreLobbyWidget)
                MulliganGuideTrialsExhaustedView(viewModel: viewModel.mulliganGuideTrialsExhausted)
                AnomalyGuideMulliganTriggerView(anomalyGuides: viewModel.battlegroundsAnomalyGuides, geometrySize: geometry.size)
                AnomalyGuideBadgeTriggerView(anomalyGuides: viewModel.battlegroundsAnomalyGuides, geometrySize: geometry.size)
                // Future SwiftUI overlay features attach here as additional children.

            }
        }
        // Declared on the outer GeometryReader so nested frame(in: .rootOverlayCanvas)
        // reports land in the same real, post-scale pixel space as the
        // NSHostingView's own bounds.
        .coordinateSpace(name: "rootOverlayCanvas")
        .onPreferenceChange(InteractiveRegionPreferenceKey.self) { region in
            viewModel.interactiveRegion = region
        }
    }
}
