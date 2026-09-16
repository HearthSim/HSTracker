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

// One child's claim on hover without claiming clicks - HDT's
// IsOverlayHoverVisible, as opposed to the IsOverlayHitTestVisible that
// InteractiveRegionPreferenceKey above models. RootOverlayWindow matches the
// cursor against these without ever touching ignoresMouseEvents, so the pixels
// stay click-through.
//
// Carries an id because several children want this at once and each needs to
// know whether the cursor is over *it*: the top-bar mask, and one region per
// offered hero and quest reward for their guide tooltips.
@available(macOS 10.15, *)
struct HoverRegion: Equatable {
    let id: String
    let rect: CGRect
}

// The ids the hover regions are matched by. Free functions rather than
// stringly-typed call sites, since both ends have to agree on them.
@available(macOS 10.15, *)
enum HoverRegionID {
    static let bgsTopBarMask = "bgsTopBarMask"

    // One id, not one per hero: the hero guide trigger is a single rectangle
    // laid over wherever the game currently has its tooltip, as HDT's is.
    static let heroGuideTrigger = "heroGuideTrigger"

    // As with the hero one above: a single rectangle over the game's own
    // tooltip, not one per offered card - and one for the trinket and quest
    // triggers together, which share an element in HDT.
    static let discoveryGuideTrigger = "discoveryGuideTrigger"

    // HDT's MercenariesTaskListButton, which carries IsOverlayHoverVisible with
    // MouseEnter/MouseLeave handlers - it reveals the task list without ever
    // taking a click of its own.
    static let mercenariesTasksButton = "mercenariesTasksButton"
}

@available(macOS 10.15, *)
struct HoverRegionPreferenceKey: PreferenceKey {
    static var defaultValue: [HoverRegion] = []
    static func reduce(value: inout [HoverRegion], nextValue: () -> [HoverRegion]) {
        value.append(contentsOf: nextValue())
    }
}

@available(macOS 10.15, *)
extension CoordinateSpace {
    static let rootOverlayCanvas = CoordinateSpace.named("rootOverlayCanvas")
}

// The `BgsTopBar.Opacity = fadeBgsMinionsList ? 0.3 : 1` line and its four
// siblings at the end of OverlayWindow.UpdateBattlegroundsOverlay. Hovering a
// leaderboard hero makes Hearthstone draw that player's board over the middle of
// the screen; these panels sit on top of it, so they step back rather than
// disappear.
//
// A wrapper view rather than opacity applied inline, because the flag lives on
// BattlegroundsOpponentInfoViewModel - the port of the method that computes it -
// and RootOverlayView observes only RootOverlayViewModel, so something has to
// observe it for the opacity to track it.
@available(macOS 10.15, *)
struct BattlegroundsLeaderboardHoverFade<Content: View>: View {
    @ObservedObject var viewModel: BattlegroundsOpponentInfoViewModel
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .opacity(viewModel.fadeBattlegroundsPanels
                     ? BattlegroundsOpponentInfoViewModel.fadedOpacity
                     : 1)
    }
}

@available(macOS 10.15, *)
struct RootOverlayView: View {
    /// Width of Hearthstone's 4:3 play area in canvas units - the canvas is the
    /// 1080-tall reference space, so this is fixed regardless of window size.
    static let fourThreeWidth: CGFloat = 1440

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
            // Hearthstone letterboxes its 4:3 play area in the middle of the
            // window, and HDT positions game-relative overlays from *its* left
            // edge via GetScaledXPos, which resolves to Width * (1 - ratio) / 2.
            // In canvas units the 4:3 area is always 1440 wide, so that is just
            // half the leftover width. Not the same as the canvas origin, which
            // is the window's own left edge.
            let fourThreeInset = (canvasWidth - RootOverlayView.fourThreeWidth) / 2

            ZStack(alignment: .topLeading) {
                // HDT's three turn timers and its two board attack icons, which
                // sit on its own canvas ahead of the leaderboard tile texts
                // below (Windows/OverlayWindow.xaml). Like those texts they take
                // real, post-scale pixels rather than living in the scaled
                // subtree - OverlayWindow.UpdateScaling never gives any of them
                // a ScaleTransform, so HDT draws them at a flat size however
                // large the client is.
                TurnTimerOverlayView(viewModel: viewModel.turnTimer,
                                     canvasSize: geometry.size)
                // Opponent first, as on HDT's canvas.
                BoardAttackIconView(viewModel: viewModel.opponentBoardAttack,
                                    canvasSize: geometry.size)
                BoardAttackIconView(viewModel: viewModel.playerBoardAttack,
                                    canvasSize: geometry.size)

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
                    // HDT's ExperienceCounter. It is the one of these three
                    // ports that _is_ resolution-scaled:
                    // _experienceCounterBehavior gives it
                    // GetScaling = AutoScaling, the Height/1080 factor this
                    // subtree applies. Its place on HDT's canvas is just ahead
                    // of the two attack icons above, which only matters in
                    // principle - the counter is a menu element and the icons a
                    // gameplay one, so the two never share the screen.
                    ExperienceCounterView(viewModel: viewModel.experienceCounter,
                                          canvasWidth: canvasWidth)

                    // HDT declares the V1 guide immediately before the V2
                    // one on its own canvas, and sizes both to
                    // Width/scaling by Height/scaling at Canvas 0,0 with
                    // scaling = Height/1080 - this subtree's own canvas.
                    ConstructedMulliganGuideView(viewModel: viewModel.mulliganGuide,
                                                 canvasWidth: canvasWidth)
                    ConstructedMulliganGuideV2View(viewModel: viewModel.mulliganGuideV2)

                    // HDT declares the pre-lobby badges immediately after
                    // the two guides on its own canvas, and scales them by
                    // Height/1080 - this subtree's own factor.
                    ConstructedMulliganGuidePreLobbyView(model: viewModel.mulliganGuidePreLobby,
                                                         canvasWidth: canvasWidth)

                    // Both counter blocks are children of HDT's own overlay
                    // canvas, declared opponent-first
                    // (Windows/OverlayWindow.xaml), and are scaled by the same
                    // Height/1080 factor this subtree applies - see
                    // CountersOverlayView for the placement they carry.
                    // PlayerCounters / OpponentCounters are two of the five
                    // elements HDT fades while a leaderboard hero is hovered.
                    // The ActiveEffects and PlayerResources widgets below are
                    // not, so the fade wraps only this pair.
                    BattlegroundsLeaderboardHoverFade(viewModel: viewModel.battlegroundsOpponentInfo) {
                        CountersOverlayView(viewModel: viewModel.opponentCounters, canvasWidth: canvasWidth)
                    }
                    BattlegroundsLeaderboardHoverFade(viewModel: viewModel.battlegroundsOpponentInfo) {
                        CountersOverlayView(viewModel: viewModel.playerCounters, canvasWidth: canvasWidth)
                    }

                    // HDT's two ActiveEffectsOverlay controls, declared right
                    // after those counters on its own canvas, opponent first,
                    // and scaled by the same Height/1080 factor - see
                    // ActiveEffectsOverlayView for the placement they carry.
                    ActiveEffectsOverlayView(viewModel: viewModel.opponentActiveEffects, canvasWidth: canvasWidth)
                    ActiveEffectsOverlayView(viewModel: viewModel.playerActiveEffects, canvasWidth: canvasWidth)

                    // HDT's two PlayerResourcesWidget controls, declared right
                    // after those on the same canvas, opponent first, and
                    // scaled the same way - see PlayerResourcesView for the
                    // placement they carry.
                    PlayerResourcesView(viewModel: viewModel.opponentResources, canvasWidth: canvasWidth)
                    PlayerResourcesView(viewModel: viewModel.playerResources, canvasWidth: canvasWidth)

                    // Bob's Buddy, centred on the canvas top - its
                    // OverlayElementBehavior is
                    //   GetLeft = Width / 2 - ActualWidth * AutoScaling / 2
                    //   GetTop  = 0
                    //   GetScaling = AutoScaling
                    // which, since this subtree already applies that scale, is
                    // just "centred horizontally, at the canvas top". HDT
                    // declares it ahead of BgsOpponentInfoContainer, and the
                    // two never share the screen: the opponent panel takes the
                    // same corner and hides this one while it is up.
                    //
                    // BobsBuddyDisplay is the fifth element HDT fades on
                    // leaderboard hover. It only ever shows while hovering your
                    // own hero or your Duos teammate - hovering an opponent
                    // hides it outright, see BattlegroundsOpponentInfoViewModel.
                    BattlegroundsLeaderboardHoverFade(viewModel: viewModel.battlegroundsOpponentInfo) {
                        ZStack(alignment: .top) {
                            Color.clear
                            BobsBuddyPanelView(viewModel: viewModel.bobsBuddy)
                        }
                        .frame(width: canvasWidth, height: 1080)
                    }

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

                    // HDT's HeroNotificationPanel and TimewarpNotificationPanel,
                    // declared right after BgsOpponentInfoContainer on its own
                    // canvas and, like it, scaled by AutoScaling - the scale
                    // this subtree already applies.
                    BattlegroundsNotificationsView(viewModel: viewModel.battlegroundsNotifications,
                                                   canvasWidth: canvasWidth)

                    // HDT's MulliganNotificationPanel, declared right after
                    // those two and placed exactly where the hero one is.
                    MulliganToastView(viewModel: viewModel.mulliganToast,
                                      canvasWidth: canvasWidth)

                    // HDT's MercenariesTaskListButton and MercenariesTaskList,
                    // declared one after the other right here on its own canvas
                    // - after MulliganNotificationPanel and ahead of the
                    // Battlegrounds pickers. Both carry
                    // GetScaling = AutoScaling, so they belong in this scaled
                    // subtree; the container holds the pair because the list's
                    // own offset is defined in terms of the button's height.
                    MercenariesTasksOverlayView(viewModel: viewModel.mercenariesTasks,
                                                canvasWidth: canvasWidth,
                                                scale: scale)

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

                    // HDT's GuidesTooltipTrigger, laid over the game's own hero
                    // picking tooltip. Declared after the picker so the guide
                    // it raises draws over the stats plates, as HDT's popup
                    // does.
                    BattlegroundsHeroGuideTriggerView(heroGuides: viewModel.battlegroundsHeroGuides,
                                                      canvasWidth: canvasWidth,
                                                      hoveredRegions: viewModel.hoveredRegionIds)

                    // The quest and trinket picking stats, declared right
                    // after the hero picker on HDT's canvas and sized to it the
                    // same way.
                    BattlegroundsQuestPickingView(viewModel: viewModel.battlegroundsQuestPicking,
                                                  canvasWidth: canvasWidth)

                    BattlegroundsTrinketPickingView(viewModel: viewModel.battlegroundsTrinketPicking,
                                                    canvasWidth: canvasWidth)

                    // HDT's DiscoveryGuidesTooltipTrigger, laid over the game's
                    // own tooltip for a hovered quest reward or trinket.
                    // Declared after the pickers for the same reason the hero
                    // one is.
                    BattlegroundsDiscoveryGuideTriggerView(discoveryGuides: viewModel.battlegroundsDiscoveryGuides,
                                                           trinketGuides: viewModel.battlegroundsTrinketGuides,
                                                           questGuides: viewModel.battlegroundsQuestGuides,
                                                           canvasWidth: canvasWidth,
                                                           hoveredRegions: viewModel.hoveredRegionIds)

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
                                        value: [HoverRegion(id: HoverRegionID.bgsTopBarMask,
                                                            rect: proxy.frame(in: .rootOverlayCanvas))]
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
                        //
                        // Faded on leaderboard hover, as BgsTopBar is. The mask
                        // above stays out of it: it is a separate element on
                        // HDT's canvas, outside the StackPanel, and its 0.01
                        // opacity is load-bearing.
                        BattlegroundsLeaderboardHoverFade(viewModel: viewModel.battlegroundsOpponentInfo) {
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
                    }
                    .frame(width: canvasWidth, height: 1080)

                    // HDT's BgsMinionPinning: a canvas-sized Grid holding the
                    // Tavern Pinning panel (bottom-right) and the markers drawn
                    // over Bob's shop. Both sit in the scaled subtree because
                    // HDT scales them by the same Height/1080 factor.
                    //
                    // HDT fades that whole Grid on leaderboard hover, so the
                    // shop markers - the pin, tribe and key icons drawn over
                    // Bob's minions - step back along with the panel. They sit
                    // right where Hearthstone draws the hovered player's board.
                    BattlegroundsLeaderboardHoverFade(viewModel: viewModel.battlegroundsOpponentInfo) {
                        BattlegroundsMinionPinningView(viewModel: viewModel.battlegroundsMinionPinning,
                                                       canvasWidth: canvasWidth)
                    }
                    BattlegroundsLeaderboardHoverFade(viewModel: viewModel.battlegroundsOpponentInfo) {
                        BattlegroundsMinionPinningShopView(viewModel: viewModel.battlegroundsMinionPinning,
                                                           canvasWidth: canvasWidth)
                    }

                    // HDT places ArenaPickHelper with GetLeft = GetScaledXPos(0)
                    // and GetTop = 0, scaled by Height/1080 - i.e. pinned to the
                    // top-left of the 4:3 inner area, which on a window wider
                    // than 4:3 is inset from the canvas origin. It is authored at
                    // HDT's 1440x1080 reference, so it needs no sizing of its own.
                    ZStack(alignment: .topLeading) {
                        Color.clear
                        ArenaPickHelperView(viewModel: viewModel.arenaPickHelper,
                                            bottomPanelFrame: $viewModel.arenaBottomPanelFrame,
                                            directionTriggerShape: $viewModel.arenaDirectionTriggerShape,
                                            cardListDirectionShapes: $viewModel.arenaCardListDirectionShapes,
                                            cardListTriggerFrame: $viewModel.arenaCardListTriggerFrame,
                                            tooltipRegions: $viewModel.arenaTooltipRegions)
                            .padding(.leading, fourThreeInset)
                    }
                    .frame(width: canvasWidth, height: 1080)

                    // HDT's _arenaPreLobbyBehavior puts this at
                    // GetScaledXPos(0.034) / Height * 0.046 - 3.4% in from the
                    // left edge of the 4:3 inner area, 4.6% down.
                    ZStack(alignment: .topLeading) {
                        Color.clear
                        ArenaPreDraftView(viewModel: viewModel.arenaPreDraft)
                            .padding(.leading, fourThreeInset + 0.034 * RootOverlayView.fourThreeWidth)
                            .padding(.top, 0.046 * 1080)
                    }
                    .frame(width: canvasWidth, height: 1080)

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
                // Last of all, because GridFlavorText is the one child HDT gives
                // a Panel.ZIndex (5) on its canvas - everything else is at the
                // default 0, so the flavor text draws over the lot. It belongs
                // in this fixed-pixel layer for the usual reason: nothing ever
                // gives it a ScaleTransform.
                FlavorTextView(viewModel: viewModel.flavorText, canvasSize: geometry.size)
                // Future SwiftUI overlay features attach here as additional children.

            }
            // HDT assigns OpacityMaskOverlay.Mask to OverlayWindow.OpacityMask,
            // so the cut-outs apply to everything the overlay draws - both the
            // scaled game-relative subtree and the fixed-pixel chrome. Applied
            // to the same ZStack here, in the outer geometry's own space, which
            // is the normalized space the regions were computed in.
            .mask(RootOverlayOpacityMaskView(mask: viewModel.opacityMask, size: geometry.size))
            // Applied after the mask, so the outlines this draws are not
            // themselves cut away. Inert unless
            // OverlayOpacityMask.debugShowRegions is flipped on.
            .overlay(RootOverlayOpacityMaskDebugView(mask: viewModel.opacityMask, size: geometry.size))
        }
        // Declared on the outer GeometryReader so nested frame(in: .rootOverlayCanvas)
        // reports land in the same real, post-scale pixel space as the
        // NSHostingView's own bounds.
        .coordinateSpace(name: "rootOverlayCanvas")
        .onPreferenceChange(InteractiveRegionPreferenceKey.self) { regions in
            viewModel.interactiveRegions = regions
        }
        .onPreferenceChange(HoverRegionPreferenceKey.self) { regions in
            viewModel.hoverRegions = regions
        }
    }
}
