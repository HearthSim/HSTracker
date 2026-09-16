//
//  PlayerResourcesView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/22/26.
//

import SwiftUI

// One of HDT's two PlayerResourcesWidget controls, placed on the RootOverlay
// canvas the way OverlayWindow.xaml places them on its own - they are declared
// straight on that canvas next to the counters and the active-effects widgets,
// not in a window of their own, which is what this replaces.
//
// It belongs in RootOverlayView's 1080-reference scaled subtree rather than its
// fixed-pixel chrome layer: OverlayWindow.Update.cs gives both widgets
// `RenderTransform = new ScaleTransform(Height / 1080, Height / 1080)`, the
// same resolution scaling it gives the counters. The AppKit windows this
// replaces were a fixed 222x36 in screen points however large the client was,
// so the widget now grows with the client the way HDT's does.
//
// Positions come from Config: PlayerMaxResourcesVertical/Horizontal
// (95.6/75.2) and OpponentMaxResourcesVertical/Horizontal (0.3/72.2), the same
// numbers SizeHelper.playerMaxResourcesFrame/opponentMaxResourcesFrame used to
// hold. Both anchor by their top edge, as HDT anchors them - unlike the
// counters, whose opponent block hangs from its bottom.
@available(macOS 10.15.0, *)
struct PlayerResourcesView: View {
    @ObservedObject var viewModel: PlayerResourcesViewModel
    // The canvas width RootOverlayView measured, in the 1080-tall reference
    // space this subtree is authored in.
    let canvasWidth: CGFloat

    private static let canvasHeight: CGFloat = 1080

    // Config.PlayerMaxResourcesVertical / PlayerMaxResourcesHorizontal.
    private static let playerVertical: CGFloat = 95.6
    private static let playerHorizontal: CGFloat = 75.2
    // Config.OpponentMaxResourcesVertical / OpponentMaxResourcesHorizontal.
    private static let opponentVertical: CGFloat = 0.3
    private static let opponentHorizontal: CGFloat = 72.2

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it; it renders nothing while the side is hidden or has no
        // resource to show, which is what replaces the old window show/hide.
        //
        // hasVisibleResources is checked here as well as isShown because HDT
        // gates the widget's Border on it (the settings gate is the control's
        // own Visibility): without it an empty list still drew the 8pt padding
        // and rounded background as a small dark blob on the board.
        ZStack(alignment: .topLeading) {
            Color.clear
            if viewModel.isShown && viewModel.hasVisibleResources {
                widget
                    .offset(x: originX, y: originY)
            }
        }
        .frame(width: canvasWidth, height: Self.canvasHeight, alignment: .topLeading)
    }

    private var widget: some View {
        HStack(spacing: 12) {
            ForEach(viewModel.resources) { resource in
                HStack {
                    Image(resource.icon).resizable().frame(width: 20, height: 20)
                        .scaledToFit()
                    // verbatim: a plain "\(Int)" interpolation would have the
                    // value run through the locale's number formatter.
                    Text(verbatim: "\(resource.value)")
                        .fixedSize()
                }
            }
        }
        .padding(8)
        .background(Color(hex: "#AA000000"))
        .cornerRadius(8)
    }

    // Canvas.SetLeft(widget, Helper.GetScaledXPos(horizontal / 100, Width,
    // ScreenRatio)). The ratio is derived from the canvas rather than read off
    // SizeHelper so this stays a pure function of what RootOverlayView
    // measured; it is the same number either way, since the canvas has the
    // client's aspect ratio.
    private var originX: CGFloat {
        let horizontal = viewModel.isPlayer ? Self.playerHorizontal : Self.opponentHorizontal
        let ratio = (4.0 / 3.0) / (canvasWidth / Self.canvasHeight)
        return SizeHelper.getScaledXPos(horizontal / 100.0, width: canvasWidth, ratio: ratio)
    }

    // Canvas.SetTop(widget, Height * vertical / 100), where Height here is the
    // scaled subtree's own 1080.
    private var originY: CGFloat {
        let vertical = viewModel.isPlayer ? Self.playerVertical : Self.opponentVertical
        return Self.canvasHeight * vertical / 100.0
    }
}

@available(macOS 10.15.0, *)
#Preview {
    VStack {
        let vm = PlayerResourcesViewModel(isPlayer: true)
        vm.initialize(30, 10, 10)
        vm.updatePlayerResourcesWidget(35, 15, 12, 5)
        vm.isShown = true
        return PlayerResourcesView(viewModel: vm, canvasWidth: 1440)
    }
    .padding()
    .background(LinearGradient(gradient: Gradient(colors: [.red, .yellow]), startPoint: .top, endPoint: .bottom))
}
