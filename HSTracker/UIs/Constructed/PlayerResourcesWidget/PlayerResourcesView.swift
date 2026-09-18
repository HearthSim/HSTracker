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
// Positions come from Settings, which start at HDT's own defaults, and can be
// dragged while the overlay is unlocked as HDT's can - see
// OverlayWidgetPlacement. PlayerMaxResourcesVertical/Horizontal
// (95.6/75.2) and OpponentMaxResourcesVertical/Horizontal (0.3/72.2), the same
// numbers SizeHelper.playerMaxResourcesFrame/opponentMaxResourcesFrame used to
// hold. Both anchor by their top edge, as HDT anchors them - unlike the
// counters, whose opponent block hangs from its bottom.
@available(macOS 10.15.0, *)
struct PlayerResourcesView: View {
    @ObservedObject var viewModel: PlayerResourcesViewModel
    // Observed as well as the view model: a drag moves the widget without the
    // resources it is showing changing.
    @ObservedObject var placement: OverlayWidgetPlacement
    // The canvas width RootOverlayView measured, in the 1080-tall reference
    // space this subtree is authored in.
    let canvasWidth: CGFloat
    // The canvas's real, post-scale size, which the drag's percentages are
    // taken against - the Width/Height of HDT's own overlay window.
    let canvasSize: CGSize
    // `Settings.windowsLocked`, HDT's `_uiMovable` inverted.
    let isLocked: Bool

    // The widget is as wide as the resources it is showing, so the movable box
    // has to be told rather than compute it - see OverlayWidgetSizePreferenceKey.
    @SwiftUI.State private var widgetSize: CGSize = .zero

    private static let canvasHeight: CGFloat = 1080

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
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: OverlayWidgetSizePreferenceKey.self,
                                                   value: proxy.size)
                        }
                    )
                    .offset(x: originX, y: originY)
                // HDT paints a box over every movable element while the overlay
                // is unlocked and drags it from there (OverlayWindow.Input.cs).
                if !isLocked, widgetSize != .zero {
                    OverlayWidgetMovableBox(
                        placement: placement,
                        frame: CGRect(x: originX, y: originY,
                                      width: widgetSize.width, height: widgetSize.height),
                        canvasSize: canvasSize,
                        canvasScale: canvasSize.height / Self.canvasHeight)
                }
            }
        }
        .frame(width: canvasWidth, height: Self.canvasHeight, alignment: .topLeading)
        .onPreferenceChange(OverlayWidgetSizePreferenceKey.self) { size in
            widgetSize = size
        }
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
        let ratio = (4.0 / 3.0) / (canvasWidth / Self.canvasHeight)
        return SizeHelper.getScaledXPos(CGFloat(placement.horizontal) / 100.0,
                                        width: canvasWidth, ratio: ratio)
    }

    // Canvas.SetTop(widget, Height * vertical / 100), where Height here is the
    // scaled subtree's own 1080.
    private var originY: CGFloat {
        Self.canvasHeight * CGFloat(placement.vertical) / 100.0
    }
}

@available(macOS 10.15.0, *)
#Preview {
    VStack {
        let vm = PlayerResourcesViewModel(isPlayer: true)
        vm.initialize(30, 10, 10)
        vm.updatePlayerResourcesWidget(35, 15, 12, 5)
        vm.isShown = true
        return PlayerResourcesView(viewModel: vm, placement: vm.placement, canvasWidth: 1440,
                                   canvasSize: CGSize(width: 1440, height: 1080), isLocked: true)
    }
    .padding()
    .background(LinearGradient(gradient: Gradient(colors: [.red, .yellow]), startPoint: .top, endPoint: .bottom))
}
