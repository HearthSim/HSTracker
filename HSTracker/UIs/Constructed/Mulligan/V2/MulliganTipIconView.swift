//
//  MulliganTipIconView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
struct MulliganTipIconView: View {
    let tip: MulliganTipViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            iconView
                .frame(width: 40, height: 40, alignment: .center)

            VStack(spacing: -2) {
                ForEach(0..<tip.arrowCount, id: \.self) { _ in
                    MulliganChevron()
                        .stroke(tip.arrowsUp ? Color.green : Color.red, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(width: 10, height: 6)
                        .rotationEffect(.degrees(tip.arrowsUp ? 0 : 180))
                }
            }
            .padding(.top, 2)
        }
        .frame(width: 40, height: 40)
        .mulliganTooltip(tooltip)
    }

    // Card-synergy tips show the other card's portrait; opponent-class tips
    // show the opponent's class icon; initiative tips show a going-first/coin
    // badge instead.
    @ViewBuilder
    private var iconView: some View {
        if let initiativeIcon = tip.tipInitiativeIcon {
            Circle()
                .fill(Color.black.opacity(0.4))
                .overlay(
                    // Matches HDT's Transform.Identity for this variant - the
                    // going-first/coin badges are already framed correctly,
                    // unlike the card/class art which needs cropping in.
                    Image(initiativeIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                )
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black, lineWidth: 2))
                .frame(width: 32, height: 32)
        } else if let classIcon = tip.tipClassIcon {
            Circle()
                .fill(Color.black.opacity(0.4))
                .overlay(
                    Image(classIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        // Matches HDT's ScaleTransform(1.2, 1.2, 16, 12) on the
                        // class icon variant of this same portrait circle.
                        .scaleEffect(1.2, anchor: UnitPoint(x: 0.5, y: 0.375))
                )
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black, lineWidth: 2))
                .frame(width: 32, height: 32)
        } else {
            MulliganCardPortraitView(card: tip.tipCard)
                .frame(width: 32, height: 32)
        }
    }

    private var tooltip: MulliganTooltipContent? {
        guard let title = tip.tooltipTitle else { return nil }
        var footer: [String] = []
        if let base = tip.baseKeepRateText { footer.append(base) }
        if let adjusted = tip.adjustedKeepRateText { footer.append(adjusted) }
        return MulliganTooltipContent(title: title, body: tip.tooltipText, footer: footer)
    }
}
