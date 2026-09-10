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
    static var defaultValue: [CGRect] = []
    // Collected as a list rather than overwritten or unioned. Originally only
    // one interactive child was ever visible at a time (the pre-lobby widget
    // XOR the trials-exhausted alert), so last-write-wins was fine; the
    // mulligan V2 card row then needed up to three at once, and unioning them
    // into a single rect was enough for three siblings sitting in a row.
    //
    // It stops being enough once two far-apart children are up together - the
    // guides panel in the top-right corner and the Inspiration panel in the
    // middle of the screen. Their bounding box covers most of the overlay, and
    // every click inside it would stop falling through to Hearthstone.
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

// Reports the on-screen frame of a child that wants hover without claiming
// clicks - HDT's IsOverlayHoverVisible, as opposed to the
// IsOverlayHitTestVisible that InteractiveRegionPreferenceKey above models.
// RootOverlayWindow matches the cursor against this without ever touching
// ignoresMouseEvents, so the pixels stay click-through.
@available(macOS 10.15, *)
struct HoverRegionPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect?
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
                // Declared before the scaled subtree because HDT declares the
                // eight BattlegroundsTileText/BattlegroundsTurnText pairs before
                // every Battlegrounds panel on its own canvas
                // (Windows/OverlayWindow.xaml), so everything else draws over
                // them. Like the session panel below it takes real, post-scale
                // pixels rather than living in the scaled subtree - see the
                // view's own header for why.
                BattlegroundsOpponentDeadForView(viewModel: viewModel.battlegroundsOpponentInfo,
                                                 canvasSize: geometry.size)

                // Resolution-scaled, game-relative content (authored at the
                // 1080-tall reference) lives in this inner, transformed
                // subtree only.
                ZStack {
                    ConstructedMulliganGuideV2View(viewModel: viewModel.mulliganGuideV2)

                    // Both counter blocks are children of HDT's own overlay
                    // canvas, declared opponent-first
                    // (Windows/OverlayWindow.xaml), and are scaled by the same
                    // Height/1080 factor this subtree applies - see
                    // CountersOverlayView for the placement they carry.
                    CountersOverlayView(viewModel: viewModel.opponentCounters, canvasWidth: canvasWidth)
                    CountersOverlayView(viewModel: viewModel.playerCounters, canvasWidth: canvasWidth)

                    // The hovered opponent's warband, pinned to the top edge of
                    // the canvas and centred on it - HDT's
                    // BgsOpponentInfoContainer is a Width="1000" StackPanel at
                    // Canvas.Top="0" whose behavior sets
                    //   GetLeft = Width / 2 - ActualWidth * AutoScaling / 2
                    //   GetTop  = 0
                    //   GetScaling = AutoScaling (= Height / 1080)
                    // Since this subtree already applies that scale, all that is
                    // left is "centred horizontally, at the canvas top". The
                    // container's fixed 1000 width only matters when the panel
                    // is narrower than it, and centring the panel itself gives
                    // the same result either way.
                    //
                    // Declared before Tier7PreLobby, matching its place on HDT's
                    // canvas, so the pre-lobby panel, the top bar, the pinning
                    // markers and the Inspiration panel all draw over it.
                    ZStack(alignment: .top) {
                        Color.clear
                        BattlegroundsOpponentInfoView(viewModel: viewModel.battlegroundsOpponentInfo)
                    }
                    .frame(width: canvasWidth, height: 1080)

                    // The Battlegrounds hero picking stats, which HDT
                    // declares right after BgsOpponentInfoContainer and ahead
                    // of Tier7PreLobby on its own canvas
                    // (Windows/OverlayWindow.xaml). OverlayWindow.Update sizes
                    // the control to Width/scaling by Height/scaling at
                    // Canvas 0,0 with scaling = Height/1080, which is this
                    // subtree's own canvas - so it just takes it whole and
                    // places its plates with the XAML's alignments.
                    BattlegroundsHeroPickingView(viewModel: viewModel.battlegroundsHeroPicking,
                                                 canvasWidth: canvasWidth)

                    // The trinket picking stats, declared right after the hero
                    // picker on HDT's canvas and sized to it the same way.
                    BattlegroundsTrinketPickingView(viewModel: viewModel.battlegroundsTrinketPicking,
                                                    canvasWidth: canvasWidth)

                    // The Tier7 Battlegrounds pre-lobby panel, declared ahead of
                    // BgsTopBar on HDT's own canvas (OverlayWindow.xaml) so the
                    // top bar and the Inspiration panel draw over it.
                    //
                    // OverlayElementBehavior gives it
                    // GetScaling = Height/1080 - the very scale this subtree
                    // already applies - so its canvas position is just its
                    // window position divided by that scale:
                    //   GetTop  = Height * 0.103          -> 0.103 * 1080
                    //   GetLeft = GetScaledXPos(0.079, Width, ScreenRatio)
                    //           = Width*ratio*0.079 + Width*(1-ratio)/2, and
                    //     since ratio = 1440/canvasWidth in this space, that
                    //     comes out as 1440*0.079 + (canvasWidth - 1440)/2 -
                    //     i.e. 7.9% into the inner 4:3 area, wherever that area
                    //     sits in a wider client.
                    ZStack(alignment: .topLeading) {
                        Color.clear
                        Tier7PreLobbyView(viewModel: viewModel.tier7PreLobby)
                            .padding(.leading, 1440 * 0.079 + (canvasWidth - 1440) / 2)
                            .padding(.top, 0.103 * 1080)
                    }
                    .frame(width: canvasWidth, height: 1080)

                    // Wrapped in its own top-trailing-anchored ZStack rather
                    // than positioned directly: the outer ZStack here has no
                    // alignment of its own (its children default-center),
                    // and this panel needs to sit at the canvas's top-right
                    // corner, matching HDT's BgsTopBar (Canvas.Top="0"
                    // Canvas.Right="0" in Windows/OverlayWindow.xaml).
                    ZStack(alignment: .topTrailing) {
                        Color.clear
                        // HDT's BgsTopBarMask: a 350x120 hover-only rectangle
                        // pinned to the canvas top-right (Canvas.Top="0"
                        // Canvas.Right="0"), sized to cover the guides panel,
                        // the tier strip, and the ~100pt to their left that the
                        // minion browser's filter button slides out into. Purely
                        // a hover sensor - it never takes clicks, hence
                        // HoverRegionPreferenceKey rather than the interactive
                        // one. Sits under GuidesTabsView so it can't shadow it.
                        Color.clear
                            .frame(width: 350, height: 120)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: HoverRegionPreferenceKey.self,
                                        value: proxy.frame(in: .rootOverlayCanvas)
                                    )
                                }
                            )
                        // HDT's BgsTopBar is a horizontal StackPanel holding the
                        // turn counter and then the guides tabs, anchored to the
                        // canvas's top-right. Pairing them here keeps the counter
                        // pinned to the panel's left edge however wide the panel
                        // gets, which is what the AppKit counter used to
                        // approximate with a hand-computed frame.
                        //
                        // .top so the 49pt counter lines up with the tab strip.
                        HStack(alignment: .top, spacing: 0) {
                            // First in BgsTopBar, left of the turn counter, as
                            // in OverlayWindow.xaml.
                            BattlegroundsInspirationOverlayButtonView(viewModel: viewModel.battlegroundsInspiration)
                            BattlegroundsTurnCounterView(viewModel: viewModel.battlegroundsTurnCounter,
                                                         minionsGuide: viewModel.battlegroundsMinionsGuide,
                                                         guidesTabs: viewModel.battlegroundsGuidesTabs)
                            GuidesTabsView(viewModel: viewModel.battlegroundsGuidesTabs, compsGuides: viewModel.battlegroundsCompsGuides, heroGuides: viewModel.battlegroundsHeroGuides, questGuides: viewModel.battlegroundsQuestGuides, minionsGuide: viewModel.battlegroundsMinionsGuide, minionPinning: viewModel.battlegroundsMinionPinning)
                        }
                    }
                    .frame(width: canvasWidth, height: 1080)

                    // HDT's BgsMinionPinning: a canvas-sized Grid holding the
                    // Tavern Pinning panel (bottom-right) and the markers drawn
                    // over Bob's shop. Both sit in the scaled subtree because
                    // HDT scales them by the same Height/1080 factor.
                    BattlegroundsMinionPinningView(viewModel: viewModel.battlegroundsMinionPinning,
                                                   canvasWidth: canvasWidth)
                    BattlegroundsMinionPinningShopView(viewModel: viewModel.battlegroundsMinionPinning,
                                                       canvasWidth: canvasWidth)

                    // Last, so it draws over the top bar - BattlegroundsInspiration
                    // comes after BgsTopBar on OverlayWindow's canvas too.
                    //
                    // OverlayElementBehavior places it at
                    // GetLeft = GetScaledXPos((1 - 0.65)/2) and GetTop = Height * 0.13.
                    // The panel's 936 width is exactly 65% of the 1440-wide inner
                    // 4:3 area, and that left offset centres it there - which, since
                    // the 4:3 area is itself centred in the window, is just "centred
                    // horizontally", 140.4pt down from the top.
                    ZStack(alignment: .top) {
                        Color.clear
                        BattlegroundsInspirationView(viewModel: viewModel.battlegroundsInspiration)
                            .padding(.top, 0.13 * 1080)
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
                // The Battlegrounds session panel belongs in this fixed-pixel
                // layer, not the scaled subtree above: HDT positions it on the
                // overlay canvas with plain percentages of the canvas size and
                // scales it only by the user's own OverlaySessionRecapScaling,
                // never by the client's resolution.
                BattlegroundsSessionOverlayView(viewModel: viewModel.battlegroundsSession,
                                                canvasSize: geometry.size)
                // Future SwiftUI overlay features attach here as additional children.

            }
        }
        // Declared on the outer GeometryReader so nested frame(in: .rootOverlayCanvas)
        // reports land in the same real, post-scale pixel space as the
        // NSHostingView's own bounds.
        .coordinateSpace(name: "rootOverlayCanvas")
        .onPreferenceChange(InteractiveRegionPreferenceKey.self) { regions in
            viewModel.interactiveRegions = regions
        }
        .onPreferenceChange(HoverRegionPreferenceKey.self) { region in
            viewModel.hoverRegion = region
        }
    }
}
