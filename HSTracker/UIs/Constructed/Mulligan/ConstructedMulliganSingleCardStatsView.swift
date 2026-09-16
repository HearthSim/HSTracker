//
//  ConstructedMulliganSingleCardStatsView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's ConstructedMulliganSingleCardStats: a 212-wide DockPanel with the stats
// header docked to its top and, under it, a placeholder standing in for the
// card Hearthstone draws itself (a fully transparent #00ff00ff Grid with a 60pt
// bottom margin in the XAML).
@available(macOS 10.15, *)
struct ConstructedMulliganSingleCardStatsView: View {
    @ObservedObject var viewModel: ConstructedMulliganSingleCardViewModel

    // The Grid each item sits in, from the guide's ItemTemplate.
    static let width: CGFloat = 212
    static let height: CGFloat = 480

    var body: some View {
        VStack(spacing: 0) {
            ConstructedMulliganSingleCardHeaderView(viewModel: viewModel.cardHeaderVM)
                // Only the header claims clicks, so the three tooltip targets
                // work while the card art below stays click-through to
                // Hearthstone. See InteractiveRegionPreferenceKey.
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                               value: [proxy.frame(in: .rootOverlayCanvas)])
                    }
                )
            Spacer(minLength: 0)
        }
        .frame(width: Self.width, height: Self.height, alignment: .top)
    }
}
