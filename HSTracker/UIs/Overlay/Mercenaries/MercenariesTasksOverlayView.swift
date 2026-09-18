//
//  MercenariesTasksOverlayView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// The two OverlayElementBehaviors OverlayWindow gives the Mercenaries task
// controls - _mercenariesTaskListButtonBehavior and
// _mercenariesTaskListBehavior - expressed as one container, since both anchor
// to the same corner and the list's own offset is defined in terms of the
// button's height.
//
// Both behaviors carry GetScaling = AutoScaling, so this belongs in
// RootOverlayView's scaled subtree and everything below is in that subtree's
// 1080-tall canvas units rather than window pixels.
struct MercenariesTasksOverlayView: View {
    @ObservedObject var viewModel: MercenariesTaskListViewModel
    let canvasWidth: CGFloat
    // The subtree's own scale (Height/1080). Needed for the one offset below
    // that HDT states in window pixels rather than as a fraction of the height.
    let scale: CGFloat

    // GetRight = Height * 0.01 on both, which in canvas units is a flat
    // 0.01 * 1080 however large the client is.
    private static let rightFactor: CGFloat = 0.01

    // OverlayWindow.MercenariesButtonOffset: the button clears Hearthstone's
    // "Back" button in the menus, and sits lower during a match.
    private static let menuBottomFactor: CGFloat = 0.104
    private static let matchBottomFactor: CGFloat = 0.05

    // The `+ 8` in GetBottom on the list behavior. Unlike everything else here
    // it is a window-pixel constant, so it shrinks in canvas units as the
    // client grows.
    private static let listGap: CGFloat = 8

    // EntranceAnimation / ExitAnimation = Slide, which
    // OverlayAnimationUtils.GetAnimation makes a 200ms linear animation of the
    // anchored side - from -ActualWidth (fully off the right edge) to the
    // element's resting offset.
    private static let slideDuration = 0.2

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear

            VStack(alignment: .trailing, spacing: Self.listGap / max(scale, 0.0001)) {
                if viewModel.isListShown {
                    MercenariesTaskListView(viewModel: viewModel, canvasWidth: canvasWidth)
                        .transition(.move(edge: .trailing))
                }
                if viewModel.isButtonShown {
                    MercenariesTaskListButtonView()
                        .transition(.move(edge: .trailing))
                        // IsOverlayHoverVisible="True" with MouseEnter /
                        // MouseLeave handlers: the button reveals the list
                        // without ever taking a click, so it reports a hover
                        // region rather than an interactive one.
                        // RootOverlayWindow matches the cursor against it and
                        // runs HDT's 150ms delay.
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: HoverRegionPreferenceKey.self,
                                    value: [HoverRegion(id: HoverRegionID.mercenariesTasksButton,
                                                        rect: proxy.frame(in: .rootOverlayCanvas))]
                                )
                            }
                        )
                }
            }
            .padding(.trailing, Self.rightFactor * 1080)
            .padding(.bottom, bottomOffset)
        }
        .frame(width: canvasWidth, height: 1080)
        .animation(.linear(duration: Self.slideDuration), value: viewModel.isButtonShown)
        .animation(.linear(duration: Self.slideDuration), value: viewModel.isListShown)
    }

    // MercenariesButtonOffset in canvas units. ScreenRatio is
    // (4/3) / (Width/Height), which in this subtree's own space - always 1080
    // tall, with the 4:3 play area always 1440 wide - is just 1440/canvasWidth.
    private var bottomOffset: CGFloat {
        let ratio = canvasWidth > 0 ? RootOverlayView.fourThreeWidth / canvasWidth : 1
        let factor = viewModel.isInMenu && ratio > 0.9 ? Self.menuBottomFactor : Self.matchBottomFactor
        return factor * 1080
    }
}
