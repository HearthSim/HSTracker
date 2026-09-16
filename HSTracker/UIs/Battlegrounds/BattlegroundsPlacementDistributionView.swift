//
//  BattlegroundsPlacementDistributionView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
private extension Color {
    static let tier7Purple = Color(red: 0x36 / 255, green: 0x16 / 255, blue: 0x37 / 255)
    static let tier7Black = Color(red: 0x14 / 255, green: 0x16 / 255, blue: 0x17 / 255)
    // The strip the placement labels sit on.
    static let placementLabelStrip = Color(red: 0x4A / 255, green: 0x52 / 255, blue: 0x56 / 255)
}

// Port of HDT's BattlegroundsPlacementDistribution.xaml plus the
// BattlegroundsPlacementDistributionBar it repeats: the eight-bar histogram
// that takes over the right-hand side of a hero's stats header while the
// cursor is on its average placement.
@available(macOS 10.15, *)
struct BattlegroundsPlacementDistributionView: View {
    let values: [Double]

    // MaxValue="30" is the control's default, raised to fit whenever a single
    // placement is more popular than that (OnValuesChanged).
    private var maxValue: Double {
        let maxFromValues = values.max() ?? 0
        return maxFromValues > 30 ? maxFromValues.rounded(.up) : 30
    }

    private var hasData: Bool {
        return values.contains { $0 > 0 }
    }

    // RowDefinitions "*" and "16".
    private static let labelRowHeight: CGFloat = 16
    // The two 2pt ColumnDefinitions bracketing the eight bar columns.
    private static let sideColumnWidth: CGFloat = 2

    var body: some View {
        content
            .background(RoundedRectangle(cornerRadius: 3).fill(Color.tier7Black))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.tier7Purple, lineWidth: 1))
    }

    @ViewBuilder
    private var content: some View {
        if hasData {
            chart
        } else {
            noData
        }
    }

    private var chart: some View {
        VStack(spacing: 0) {
            // The bars fill whatever is left above the label strip, and each
            // one's own height is that share of MaxValue - hence measuring the
            // row rather than the whole control.
            GeometryReader { proxy in
                columns { index in
                    BattlegroundsPlacementDistributionBar(
                        value: index < values.count ? values[index] : 0,
                        maxValue: maxValue,
                        // Highlight="True" on the first four bars only.
                        highlight: index < 4,
                        rowHeight: proxy.size.height)
                }
            }
            labels
        }
    }

    // Foreground="White" FontSize="12" TextAlignment="Center" MaxWidth="200",
    // wrapping, centred in the control.
    private var noData: some View {
        Text(String.localizedString("BattlegroundsHeroPicking_PlacementDistribution_NoData", comment: ""))
            .font(.system(size: 12))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 200)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var labels: some View {
        columns { index in
            label(for: index)
        }
        .frame(height: Self.labelRowHeight)
        .background(
            labelStrip
                // Margin="-1 0 -1 -1": the strip covers the border down its
                // sides and along the bottom rather than sitting inside it.
                .padding(EdgeInsets(top: 0, leading: -1, bottom: -1, trailing: -1))
        )
    }

    @ViewBuilder
    private func label(for index: Int) -> some View {
        if index == 0 {
            // bgs_crown.png, 16x16, rotated 46 degrees about its own centre,
            // Margin="0 1 0 0".
            Image("bgs_crown")
                .resizable()
                .interpolation(.high)
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(46))
                .padding(.top, 1)
        } else if index == 3 || index == 7 {
            // LocUtil.GetPlacement(4) / GetPlacement(8), which HSTracker
            // already carries as the session panel's placement ordinals.
            Text(String.localizedString("Battlegrounds_Game_Ordinal_\(index + 1)", comment: ""))
                .font(.system(size: 10))
                .foregroundColor(.white)
                .fixedSize()
        } else {
            Color.clear
        }
    }

    // Background="#4A5256" with BorderThickness="1 0 1 1" in Tier7Purple and
    // CornerRadius="0 0 5 5" - no top edge, since the bars sit directly on it.
    private var labelStrip: some View {
        ZStack {
            RoundedCorner(radius: 5, corners: [.bottomLeft, .bottomRight])
                .fill(Color.placementLabelStrip)
            PlacementLabelStripBorder()
                .stroke(Color.tier7Purple, lineWidth: 1)
        }
    }

    // The Grid's ten columns: 2pt, eight equal shares, 2pt.
    private func columns<Content: View>(@ViewBuilder content: @escaping (Int) -> Content) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: Self.sideColumnWidth)
            ForEach(0..<8) { index in
                content(index)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Color.clear.frame(width: Self.sideColumnWidth)
        }
    }
}

// The label strip's three-sided border, drawn as an open path so the missing
// top edge stays missing while the two bottom corners still round.
@available(macOS 10.15, *)
private struct PlacementLabelStripBorder: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 5
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius), radius: radius,
                    startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius), radius: radius,
                    startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

// Port of BattlegroundsPlacementDistributionBar.xaml: one bar, bottom-aligned
// in its column, whose height is Value/MaxValue of the row.
@available(macOS 10.15, *)
private struct BattlegroundsPlacementDistributionBar: View {
    let value: Double
    let maxValue: Double
    let highlight: Bool
    let rowHeight: CGFloat

    // The Rectangle's own gradient: StartPoint 0.5,0 -> EndPoint 0.5,1 with
    // GradientColorBottom at offset 0 and GradientColorTop at offset 1, so
    // despite the names it is GradientColorBottom that paints the top.
    private var gradient: LinearGradient {
        let top = highlight ? Color(hex: "#FFC58DC9") : Color(hex: "#CC78577A")
        let bottom = highlight ? Color(hex: "#CCC58DC9") : Color(hex: "#CC78577A")
        return LinearGradient(gradient: Gradient(colors: [top, bottom]),
                              startPoint: .top, endPoint: .bottom)
    }

    private var borderColor: Color {
        return highlight ? Color(hex: "#66FFFFFF") : Color(hex: "#28FFFFFF")
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 2)
                .fill(gradient)
                // HDT sets StrokeThickness="-1", which draws nothing; the
                // AppKit view this replaces drew the 1pt BorderColor the
                // control still computes, so it keeps it.
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(borderColor, lineWidth: 1))
                .frame(height: maxValue > 0 ? rowHeight * CGFloat(value / maxValue) : 0)
                // Margin="2 0".
                .padding(.horizontal, 2)
        }
    }
}
