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
    // show the opponent's class icon instead.
    @ViewBuilder
    private var iconView: some View {
        if let classIcon = tip.tipClassIcon {
            Circle()
                .fill(Color.black.opacity(0.4))
                .overlay(
                    Image(classIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                )
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black, lineWidth: 2))
                .frame(width: 32, height: 32)
        } else {
            MulliganCardPortraitView(card: tip.tipCard)
                .frame(width: 32, height: 32)
        }
    }

    private var tooltip: String? {
        guard let title = tip.tooltipTitle else { return nil }
        var parts = [title]
        if let text = tip.tooltipText { parts.append(text) }
        if let base = tip.baseKeepRateText { parts.append(base) }
        if let adjusted = tip.adjustedKeepRateText { parts.append(adjusted) }
        return parts.joined(separator: "\n")
    }
}
