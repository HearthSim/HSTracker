//
//  ConstructedMulliganGuideV2View.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
struct ConstructedMulliganGuideV2View: View {
    @ObservedObject var viewModel: ConstructedMulliganGuideV2ViewModel

    var body: some View {
        ZStack {
            if let error = viewModel.error {
                Text(error)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(6)
            } else if viewModel.statsVisibility && !viewModel.cardStats.isEmpty {
                // Each header column reserves a full card-height cell (see
                // ConstructedMulliganV2SingleCardHeaderView) so this row centers
                // above the physical cards instead of overlapping their art.
                // Row width matches HDT's own card-row container (988, divided
                // evenly across however many cards are offered) and is centered
                // like HDT's XAML - the earlier right-anchor/widen tweaks were
                // very likely compensating for the RootOverlayView centering bug
                // (see its GeometryReader comment), not an actual width mismatch,
                // so this reverts to the simple, principled version now that
                // that's fixed.
                HStack(alignment: .top, spacing: 0) {
                    ForEach(viewModel.cardStats) { card in
                        ConstructedMulliganV2SingleCardHeaderView(viewModel: card.header)
                            .frame(width: 988 / CGFloat(viewModel.cardStats.count))
                    }
                }
                // Small upward nudge on top of the card-height placeholder in
                // ConstructedMulliganV2SingleCardHeaderView, tuned to sit just
                // above the physical cards without overlapping the Hearthstone
                // timer/UI text higher up the screen.
                .offset(y: -30)

                if let message = viewModel.message {
                    Text(message)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(6)
                        // Anchored to the bottom of the overlay independently of
                        // the card row's height, matching HDT's bottom-anchored banner.
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 60)
                }
            }
        }
    }
}

@available(macOS 10.15, *)
#Preview {
    let vm = ConstructedMulliganGuideV2ViewModel()
    let data = MulliganV2Data.MulliganCard(card_status: .valid, justifications: [
        "[]": 0.28,
        "[2]": 0.71
    ])
    vm.cardStats = (1...4).map {
        ConstructedMulliganV2SingleCardViewModel(position: $0, data: data, isFirst: true)
    }
    vm.statsVisibility = true
    vm.message = "vs Mage, going first"

    return ConstructedMulliganGuideV2View(viewModel: vm)
        .padding(40)
        .background(Color.black)
}
