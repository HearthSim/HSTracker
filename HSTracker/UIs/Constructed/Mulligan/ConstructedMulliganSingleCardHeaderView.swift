//
//  ConstructedMulliganSingleCardHeaderView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's ConstructedMulliganSingleCardHeader: the 212x53 plate above one offered
// card in the V1 mulligan guide - the mulligan winrate on the left, the hand
// rank badge in the middle, the keep rate on the right.
//
// HDT draws the three plates as one DrawingImage of vector geometry behind the
// text. The rounded rectangles and their rank gradient are ordinary shapes
// here, with the geometry's own numbers carried over: side panels inset
// 0.4363 and 64.1274 wide with a 3.5637 corner and a 0.872587 HSReplayNetBlue
// stroke, a 19pt blue label strip across their tops, and the rank badge
// spanning 73...139.
struct ConstructedMulliganSingleCardHeaderView: View {
    @ObservedObject var viewModel: ConstructedMulliganSingleCardHeaderViewModel

    static let width: CGFloat = 212
    static let height: CGFloat = 53

    // RectangleGeometry Rect="0.4363,0.4363,64.1274,52.1274" and its mirror at
    // 147.436, with RadiusX/Y 3.5637 and a Thickness 0.872587 pen.
    private static let sideInset: CGFloat = 0.4363
    private static let sideWidth: CGFloat = 64.1274
    private static let sideCorner: CGFloat = 3.5637
    private static let sideStroke: CGFloat = 0.872587
    private static let rightSideX: CGFloat = 147.436

    // The blue label strip capping each side panel: the geometry runs to
    // y=17.49 on the right plate and y=19 on the left, over the Grid's own
    // 19pt first row.
    private static let labelRowHeight: CGFloat = 19

    // The rank badge, 73...139 wide and the full 53 tall, with the same corner
    // radius and a black 18% stroke.
    private static let rankX: CGFloat = 73
    private static let rankWidth: CGFloat = 66

    private static let panelFill = Color(hex: "#141617")
    // App.xaml's HSReplayNetBlue.
    private static let hsReplayNetBlue = Color(hex: "#1D3657")

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            sidePanel(x: Self.sideInset,
                      label: String.localizedString("ConstructedMulliganGuide_Header_MulliganWR", comment: ""),
                      value: Self.percent(viewModel.mulliganWr),
                      valueColor: viewModel.mulliganWrColor)
                .guideTooltip(GuideTooltipContent(
                    title: String.localizedString("ConstructedMulliganGuide_Header_MulliganWRTooltip_Title", comment: ""),
                    body: String.localizedString("ConstructedMulliganGuide_Header_MulliganWRTooltip_Desc", comment: "")))

            sidePanel(x: Self.rightSideX,
                      label: String.localizedString("ConstructedMulliganGuide_Header_KeepRate", comment: ""),
                      value: Self.percent(viewModel.keepRate),
                      valueColor: .white)
                .guideTooltip(GuideTooltipContent(
                    title: String.localizedString("ConstructedMulliganGuide_Header_KeepRateTooltip_Title", comment: ""),
                    body: String.localizedString("ConstructedMulliganGuide_Header_KeepRateTooltip_Desc", comment: "")))

            rankBadge
                .guideTooltip(GuideTooltipContent(
                    title: String.localizedString("ConstructedMulliganGuide_Header_HandRankTooltip_Title", comment: ""),
                    body: viewModel.handRankTooltipText))
        }
        .frame(width: Self.width, height: Self.height, alignment: .topLeading)
    }

    // One of the two outer plates: a #141617 rounded rect with a blue stroke, a
    // blue strip across the top carrying the label, and the value under it.
    private func sidePanel(x: CGFloat, label: String, value: String, valueColor: Color) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: Self.sideCorner)
                .fill(Self.panelFill)
            // The blue cap is the same rounded rect clipped to the label row, so
            // its top corners follow the panel's and its bottom edge is square,
            // which is what the geometry's own path describes.
            RoundedRectangle(cornerRadius: Self.sideCorner)
                .fill(Self.hsReplayNetBlue)
                .frame(height: Self.sideWidth)
                .frame(height: Self.labelRowHeight, alignment: .top)
                .clipped()
            RoundedRectangle(cornerRadius: Self.sideCorner)
                .stroke(Self.hsReplayNetBlue, lineWidth: Self.sideStroke)

            VStack(spacing: 0) {
                // FontSize="10.5" with Padding="1 0" and CharacterEllipsis.
                //
                // The scale factor is not in the XAML: HDT inherits Segoe UI,
                // which fits "Mulligan WR" at 10.5 inside the 65pt column, and
                // the system face here is wide enough that the same string
                // would hit the ellipsis instead. Shrinking slightly keeps the
                // label whole the way HDT's renders, and does nothing at all
                // for the shorter strings and translations that already fit.
                Text(label)
                    .font(.system(size: 10.5))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .truncationMode(.tail)
                    .padding(.horizontal, 1)
                    .frame(height: Self.labelRowHeight)
                // StatsTextStyle: Chunkfive at 16.
                Text(verbatim: value)
                    .chunkFive(size: 16)
                    .foregroundColor(valueColor)
                    .lineLimit(1)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: Self.sideWidth, height: Self.height - Self.sideInset * 2)
        .offset(x: x, y: Self.sideInset)
    }

    private var rankBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Self.sideCorner)
                .fill(LinearGradient(gradient: Gradient(colors: viewModel.rankGradient),
                                     startPoint: .leading, endPoint: .trailing))
            RoundedRectangle(cornerRadius: Self.sideCorner)
                .stroke(Color.black.opacity(0.18), lineWidth: Self.sideStroke)

            VStack(spacing: 0) {
                // FontSize="8.5" Margin="0 5 0 0".
                Text(String.localizedString("ConstructedMulliganGuide_Header_HandRank", comment: ""))
                    .font(.system(size: 8.5))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.top, 5)
                // BoldTextStyle overridden to FontSize="23".
                Text(verbatim: viewModel.rank.map { "#\($0)" } ?? "?")
                    .chunkFive(size: 23)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
        .frame(width: Self.rankWidth, height: Self.height)
        .offset(x: Self.rankX)
    }

    // StringFormat={}{0:0.0}% with TargetNullValue set to an en dash.
    private static func percent(_ value: Double?) -> String {
        guard let value else { return "\u{2013}" }
        return String(format: "%.1f%%", value)
    }
}

#Preview {
    VStack(spacing: 8) {
        ForEach(1..<5) { rank in
            ConstructedMulliganSingleCardHeaderView(
                viewModel: ConstructedMulliganSingleCardHeaderViewModel(
                    rank: rank, mulliganWr: 46.0 + Double(rank) * 3, keepRate: 88.5,
                    maxRank: 4, baseWinRate: 52.0))
        }
        ConstructedMulliganSingleCardHeaderView(
            viewModel: ConstructedMulliganSingleCardHeaderViewModel(
                rank: nil, mulliganWr: nil, keepRate: nil, maxRank: nil, baseWinRate: nil))
    }
    .padding(20)
    .background(Color.black)
}
