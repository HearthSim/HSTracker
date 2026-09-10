//
//  MulliganToastView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's MulliganPanel.xaml: the same toast chrome the Battlegrounds
// notifications use, in blue, over one of two backgrounds - the regular art
// when the deck has a page on HSReplay.net, and a grey one that doesn't react
// to the cursor when it doesn't.
//
// Its OverlayElementBehavior matches the hero notification's exactly
// (GetRight = 0, GetBottom = Height * 0.04, AnchorSide = Bottom,
// GetScaling = AutoScaling, Slide in and out), so it hangs off the same corner
// of the canvas; the two never share a match.
@available(macOS 10.15, *)
struct MulliganToastView: View {
    @ObservedObject var viewModel: MulliganToastViewModel
    let canvasWidth: CGFloat

    // Background="#1D3657".
    private static let background = Color(red: 0x1D / 255, green: 0x36 / 255, blue: 0x57 / 255)

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear

            if viewModel.isShown {
                OverlayToastPanel(
                    title: viewModel.hasData
                        ? String.localizedString("What should I keep?", comment: "")
                        : viewModel.noDataLabel,
                    subtitle: String.localizedString("HSReplay.net - Mulligan Guide", comment: ""),
                    background: Self.background,
                    artwork: viewModel.hasData ? Self.artwork : Self.greyArtwork,
                    // Only the regular art carries the storyboards; the grey
                    // one is drawn at full opacity and stays there.
                    normalArtworkOpacity: viewModel.hasData ? 0.5 : 1,
                    hoverArtworkOpacity: viewModel.hasData ? 0.8 : 1,
                    // Cursor="{Binding CursorStyle}": hand only when there is
                    // a page to open.
                    showsHandCursor: viewModel.hasData,
                    action: viewModel.click)
                    .padding(.bottom, 0.04 * 1080)
                    .transition(.move(edge: .bottom))
            }
        }
        .frame(width: canvasWidth, height: 1080)
    }

    private static let artwork = NSImage(named: "mulligan-toast-bg")
    private static let greyArtwork = NSImage(named: "mulligan-toast-bg-grey")
}
