//
//  ConstructedMulliganV2SingleCardHeaderView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
struct ConstructedMulliganV2SingleCardHeaderView: View {
    @ObservedObject var viewModel: ConstructedMulliganV2SingleCardHeaderViewModel

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(viewModel.tips) { tip in
                    MulliganTipIconView(tip: tip)
                }
            }
            .frame(height: 45)

            ZStack(alignment: .topTrailing) {
                ZStack {
                    if viewModel.hasError {
                        errorPill
                    } else {
                        LinearGaugeView(viewModel: viewModel)
                            .mulliganTooltip(gaugeTooltip)

                        if viewModel.replaced {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 212, height: 21)
                        }
                    }
                }

                if viewModel.hasWarning {
                    ZStack {
                        MulliganTriangle()
                            .fill(Color.yellow)
                            .overlay(MulliganTriangle().stroke(Color.black, lineWidth: 1.3))
                        Text("!")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.black)
                            .offset(y: 2)
                    }
                    .frame(width: 18, height: 16)
                    .mulliganTooltip(viewModel.warningText)
                    .offset(x: 4, y: -4)
                }
            }

            // The rest of this column is transparent - it's a stand-in for the
            // actual card, which Hearthstone renders itself. Matches HDT's card
            // cell height (555 in the 1080-tall reference canvas) so the header
            // sits in a strip above the real card instead of on top of it.
            Spacer(minLength: 0)
        }
        .frame(width: 212, height: 555, alignment: .top)
    }

    private var errorPill: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 1))
            .overlay(
                Text(viewModel.errorText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.black.opacity(0.8))
            )
            .frame(width: 212, height: 20.5)
    }

    private var gaugeTooltip: String? {
        guard viewModel.hasTooltip, let title = viewModel.tooltipTitle else { return nil }
        if let text = viewModel.tooltipText {
            return "\(title)\n\(text)"
        }
        return title
    }
}

@available(macOS 10.15, *)
#Preview {
    let normal = MulliganV2Data.MulliganCard(card_status: .valid, justifications: [
        "[]": 0.35,
        "[2]": 0.62
    ])

    let warning = MulliganV2Data.MulliganCard(card_status: .lowData, justifications: [
        "[]": 0.8
    ])

    let error = MulliganV2Data.MulliganCard(card_status: .noData)

    return HStack(spacing: 12) {
        ConstructedMulliganV2SingleCardHeaderView(viewModel: ConstructedMulliganV2SingleCardHeaderViewModel(position: 1, data: normal))
        ConstructedMulliganV2SingleCardHeaderView(viewModel: ConstructedMulliganV2SingleCardHeaderViewModel(position: 2, data: warning))
        ConstructedMulliganV2SingleCardHeaderView(viewModel: ConstructedMulliganV2SingleCardHeaderViewModel(position: 3, data: error))
    }
    .padding(30)
    .background(Color.black)
}
