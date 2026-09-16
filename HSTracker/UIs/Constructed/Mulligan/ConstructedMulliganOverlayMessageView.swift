//
//  ConstructedMulliganOverlayMessageView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's OverlayMessage: a Tier7Black pill with an HSReplayNetBlue border, an
// HSReplay icon in a blue cap on its left, and the message text beside it.
@available(macOS 10.15, *)
struct ConstructedMulliganOverlayMessageView: View {
    @ObservedObject var viewModel: ConstructedMulliganOverlayMessageViewModel

    private static let hsReplayNetBlue = Color(hex: "#1D3657")
    // App.xaml's Tier7Black.
    private static let tier7Black = Color(hex: "#141617")
    private static let cornerRadius: CGFloat = 5

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it; it draws nothing while there is no message, which is
        // HDT's Visibility binding.
        if let text = viewModel.text {
            HStack(spacing: 0) {
                // Border Background=HSReplayNetBlue CornerRadius="5 0 0 5"
                // Margin="-1" Padding="5 5 4 4" - the negative margin pulls the
                // cap out over the container's own 1pt border.
                Image("hsreplay_logo_white")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 13, height: 16)
                    .padding(.leading, 5 + 1)
                    .padding(.trailing, 4)
                    .padding(.vertical, 5)
                    .background(Self.hsReplayNetBlue)
                    .cornerRadius(Self.cornerRadius, corners: [.topLeft, .bottomLeft])

                Text(text)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.leading, 8)
                    .padding(.trailing, 8)
                    .padding(.top, 4)
                    .padding(.bottom, 5)
            }
            .fixedSize()
            .background(Self.tier7Black)
            .cornerRadius(Self.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .stroke(Self.hsReplayNetBlue, lineWidth: 1)
            )
        }
    }
}

@available(macOS 10.15, *)
#Preview {
    let vm = ConstructedMulliganOverlayMessageViewModel()
    vm.text = "vs Mage, going first"
    return ConstructedMulliganOverlayMessageView(viewModel: vm)
        .padding(30)
        .background(Color.black)
}
