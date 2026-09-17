//
//  LinkOpponentDeckPanelView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

/// HDT's `LinkOpponentDeckPanel.xaml`:
///
///   <Border Background="#23272A" BorderBrush="#141617" BorderThickness="1"
///           CornerRadius="3" Margin="0,5,0,0" MaxWidth="352">
///     <StackPanel Margin="10"> title / description / button / link / error </StackPanel>
///   </Border>
///
/// declared on the overlay canvas at `Width="218"` and placed under the opponent
/// stack by `OverlayWindow.UpdateElementPositions`:
///
///   Canvas.SetLeft(LinkOpponentDeckDisplay, Width * OpponentDeckLeft / 100);
///   if(opponentTop + opponentStackVisibleHeight + 10 + panelHeight < Height)
///       Canvas.SetTop(panel, opponentTop + opponentStackVisibleHeight + 10);
///   else
///       Canvas.SetTop(panel, opponentTop - panelHeight * scaling - 10);
///
/// It carries the opponent stack's own scaling, as HDT's `UpdateScaling` gives it.
@available(macOS 10.15, *)
struct LinkOpponentDeckPanelView: View {
    @ObservedObject var viewModel: LinkOpponentDeckPanelViewModel
    @ObservedObject var opponent: TrackerPanelViewModel
    let canvasSize: CGSize

    /// The panel's own laid-out height, so the "does it still fit below the
    /// stack?" test above can be made.
    // Qualified: HSTracker has a `State` enum of its own, which shadows SwiftUI's
    // property wrapper.
    @SwiftUI.State private var panelHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            if viewModel.isShowing {
                panel
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
        .preference(key: InteractiveRegionPreferenceKey.self, value: interactiveRegions)
    }

    private static let width: CGFloat = 218

    private var scale: CGFloat { CGFloat(opponent.scaling) / 100.0 }
    private var originX: CGFloat { canvasSize.width * CGFloat(opponent.left) / 100.0 }

    /// HDT's `OpponentStackVisibleHeight` - the stack's drawn content, scaled.
    private var stackBottom: CGFloat {
        let layout = TrackerPanelLayout(viewModel: opponent, canvasHeight: canvasSize.height)
        let content = layout.sections.reduce(0) { $0 + $1.height }
        return canvasSize.height * CGFloat(opponent.top) / 100.0 + content * scale
    }

    private var originY: CGFloat {
        let opponentTop = canvasSize.height * CGFloat(opponent.top) / 100.0
        let below = stackBottom + 10
        if below + panelHeight < canvasSize.height {
            return below
        }
        return opponentTop - panelHeight * scale - 10
    }

    /// The panel is the one piece of this port that has to take clicks whatever
    /// the overlay's lock state: its whole purpose is the "set deck from
    /// clipboard" button. Its own window did the same - `LinkOpponentDeckPanel`
    /// overrode `updateFrames` to force `ignoresMouseEvents = false`.
    private var interactiveRegions: [CGRect] {
        guard viewModel.isShowing, panelHeight > 0 else { return [] }
        return [CGRect(x: originX, y: originY,
                       width: Self.width * scale, height: panelHeight * scale)]
    }

    private var panel: some View {
        content
            .frame(width: Self.width, alignment: .leading)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: LinkPanelHeightKey.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(LinkPanelHeightKey.self) { height in panelHeight = height ?? 0 }
            .scaleEffect(scale, anchor: .topLeading)
            .offset(x: originX, y: originY)
            .onHover { inside in
                viewModel.mouseIsOver = inside
                if !inside { viewModel.mouseExited() }
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String.localizedString("LinkOpponentDeck_Panel_Title", comment: ""))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            if viewModel.showsDescription {
                Text(String.localizedString("LinkOpponentDeck_Panel_Description", comment: ""))
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .opacity(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 3)
            }

            Button(action: { viewModel.linkDeckFromClipboard() }) {
                Text(String.localizedString("LinkOpponentDeck_Panel_LinkDeckButton", comment: ""))
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 6)

            if !viewModel.linkMessage.isEmpty {
                Text(viewModel.linkMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .underline()
                    .opacity(0.7)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)
                    .onTapGesture { viewModel.linkTapped() }
            }

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }
        }
        .padding(10)
        .background(Color(hex: "#23272A"))
        .cornerRadius(3)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#141617"), lineWidth: 1))
        .padding(.top, 5)
    }
}

@available(macOS 10.15, *)
private struct LinkPanelHeightKey: PreferenceKey {
    static var defaultValue: CGFloat?
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        if let next = nextValue() { value = next }
    }
}
