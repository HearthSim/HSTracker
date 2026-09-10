//
//  BattlegroundsCompositionPopularityView.swift
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
}

// Port of HDT's BattlegroundsCompositionPopularity.xaml and the
// BattlegroundsCompositionPopularityRow/Bar it repeats: the three warband
// compositions that most often win with this quest reward, each with the share
// of first places it takes.
@available(macOS 10.15, *)
struct BattlegroundsCompositionPopularityView: View {
    let viewModel: BattlegroundsCompositionPopularityViewModel?

    var body: some View {
        content
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.tier7Black))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.tier7Purple, lineWidth: 1))
            // IsOverlayHitTestVisible="True" with a plain string ToolTip, which
            // the picker's resources give the Tier7 style.
            .bgsTopTooltip(String.localizedString("BattlegroundsHeroPicking_Hero_CompositionTooltip", comment: ""))
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                           value: [proxy.frame(in: .rootOverlayCanvas)])
                }
            )
    }

    @ViewBuilder
    private var content: some View {
        if let rows = viewModel?.top3Compositions, !rows.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    BattlegroundsCompositionPopularityRowView(viewModel: row)
                }
            }
            // The ItemsControl's OpacityMask is a Border carrying the outer
            // Border's own corner radius, which is what keeps the rows' square
            // backgrounds inside its rounded corners.
            .clipShape(RoundedRectangle(cornerRadius: 5))
        } else {
            // Foreground="White" FontSize="12" Margin="0 8" Width="200",
            // centred and ellipsised.
            Text(String.localizedString("BattlegroundsHeroPicking_Compositions_NoData", comment: ""))
                .font(.system(size: 12))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .frame(width: 200)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
        }
    }
}

// One composition: the key minion's tile art fading out from the left edge, the
// composition's name, a popularity bar and its percentage.
@available(macOS 10.15, *)
private struct BattlegroundsCompositionPopularityRowView: View {
    let viewModel: BattlegroundsCompositionPopularityRowViewModel

    // DockPanel Background="#141617" Height="24" ClipToBounds="True".
    private static let rowHeight: CGFloat = 24
    // The Canvas the art is drawn in, which is all the room it takes in the row
    // even though the Image itself is wider.
    private static let artColumnWidth: CGFloat = 38

    var body: some View {
        HStack(spacing: 0) {
            art
            HStack(spacing: 0) {
                // HearthstoneTextBlock (outlined) FontSize="12" Width="65"
                // Margin="0 0 8 0".
                Text(viewModel.name)
                    .font(.system(size: 12))
                    .outlinedText()
                    .lineLimit(1)
                    .frame(width: 65, alignment: .leading)
                    .padding(.trailing, 8)

                bar

                // Chunkfive 12pt, right-aligned, Width="32"
                // Margin="8 1 8 0".
                Text(verbatim: viewModel.popularityText)
                    .chunkFive(size: 12)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    // A WPF TextBlock overflows its Width rather than
                    // ellipsising, and this one is sized for the Chunkfive
                    // digits that fit it exactly.
                    .fixedSize()
                    .frame(width: 32, alignment: .trailing)
                    .padding(EdgeInsets(top: 1, leading: 8, bottom: 0, trailing: 8))
            }
            .opacity(viewModel.opacity)
        }
        .frame(height: Self.rowHeight)
        .background(Color.tier7Black)
        .clipped()
    }

    private var art: some View {
        ZStack(alignment: .topLeading) {
            BattlegroundsCompositionTileArt(cardId: viewModel.cardImage)
                .opacity(viewModel.opacity)
            if viewModel.compositionUnavailableVisibility {
                // tribes-x.png, Width="20" at Canvas.Left="6" Canvas.Top="2".
                Image("tribes-x")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20)
                    .offset(x: 6, y: 2)
            }
        }
        // A Canvas takes no room for its children, so the art beyond this
        // column simply draws over what follows - by which point its own
        // gradient has faded it out.
        .frame(width: Self.artColumnWidth, height: Self.rowHeight, alignment: .topLeading)
    }

    // The BattlegroundsCompositionPopularityBar: Height="16" Margin="0 4",
    // RadiusX/Y 2, its width Progress percent of whatever room is left.
    private var bar: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(gradient)
                    // HDT sets StrokeThickness="-1", which draws nothing; the
                    // AppKit bar this replaces drew the 1pt BorderColor the
                    // control still computes, so it keeps it.
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(borderColor, lineWidth: 1))
                    .frame(width: proxy.size.width * CGFloat(viewModel.popularityBarValue) / 100)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
    }

    // StartPoint 0.5,0 -> EndPoint 0.5,1 with GradientColorBottom at offset 0
    // and GradientColorTop at offset 1, so despite the names it is
    // GradientColorBottom that paints the top.
    private var gradient: LinearGradient {
        let highlight = viewModel.compositionAvailable
        let top = highlight ? Color(hex: "#FFC58DC9") : Color(hex: "#CC78577A")
        let bottom = highlight ? Color(hex: "#CCC58DC9") : Color(hex: "#CC78577A")
        return LinearGradient(gradient: Gradient(colors: [top, bottom]),
                              startPoint: .top, endPoint: .bottom)
    }

    private var borderColor: Color {
        return viewModel.compositionAvailable ? Color(hex: "#66FFFFFF") : Color(hex: "#28FFFFFF")
    }
}

// The key minion's tile, drawn 110pt wide and pulled 55pt left so the row shows
// the middle of it, under the OpacityMask that fades it out to the right.
@available(macOS 10.15, *)
private struct BattlegroundsCompositionTileArt: View {
    let cardId: String

    // Image Height="24" Width="110" Margin="-55,0,0,0".
    private static let artWidth: CGFloat = 110
    private static let artHeight: CGFloat = 24
    private static let artOffset: CGFloat = -55

    @SwiftUI.State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: Self.artWidth, height: Self.artHeight)
                    .mask(
                        // LinearGradientBrush StartPoint="0,0" EndPoint="0.85,0"
                        // with an opaque stop at 0.5 and a transparent one at 1,
                        // i.e. across 85% of the image's own width.
                        LinearGradient(gradient: Gradient(stops: [
                            .init(color: .black, location: 0.5),
                            .init(color: .clear, location: 1)
                        ]), startPoint: .leading, endPoint: UnitPoint(x: 0.85, y: 0))
                        .frame(width: Self.artWidth, height: Self.artHeight)
                    )
                    .offset(x: Self.artOffset)
            } else {
                Color.clear
                    .frame(width: Self.artWidth, height: Self.artHeight)
                    .offset(x: Self.artOffset)
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard !cardId.isEmpty else { return }
        if let cached = ImageUtils.cachedTile(cardId: cardId) {
            image = cached
            return
        }
        ImageUtils.tile(for: cardId) { img in
            DispatchQueue.main.async {
                self.image = img
            }
        }
    }
}
