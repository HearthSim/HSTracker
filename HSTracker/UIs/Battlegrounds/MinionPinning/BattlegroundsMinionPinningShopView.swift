//
//  BattlegroundsMinionPinningShopView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's BattlegroundsMinionPinningShop.xaml: the markers drawn on top
// of Bob's actual shop. Seven fixed cells in a horizontal row, centred on the
// canvas, each 138x190 - the footprint of one shop minion at the 1080-tall
// reference resolution.
//
// Deliberately *not* interactive. The shop card's pin marker carries
// Cursor="Hand" and a TogglePinCard MouseBinding in the XAML, but the control
// never sets OverlayExtensions.IsOverlayHitTestVisible, so in HDT those clicks
// fall through to Hearthstone like the rest of the overlay. No interactive
// region is reported here for the same reason - pinning from the shop happens
// through the browser or the panel.
@available(macOS 10.15, *)
struct BattlegroundsMinionPinningShopView: View {
    @ObservedObject var viewModel: BattlegroundsMinionPinningViewModel
    // The canvas width RootOverlayView measured, so the row can centre on it.
    let canvasWidth: CGFloat

    // Grid Margin="0,-290,0,0" around a vertically centred ItemsControl: the
    // margin makes the layout rect 290pt taller at the top, which moves the
    // centre up by half of that.
    private static let verticalOffset: CGFloat = -145

    var body: some View {
        if viewModel.isShown && viewModel.isShopShown {
            HStack(spacing: 0) {
                ForEach(viewModel.shopCards) { card in
                    BattlegroundsMinionPinningCardView(card: card)
                }
            }
            .offset(y: Self.verticalOffset)
            .frame(width: canvasWidth, height: 1080)
        }
    }
}

// Mirrors BattlegroundsMinionPinningCard.xaml. A 138x190 cell holding up to
// three stacked markers down its right edge - manual pin, minion-type pin, key
// piece - plus the hover-only "key comp pieces" tooltip.
//
// An unoccupied slot emits *nothing at all*, taking no width. That is what
// tracks the real shop: HDT's outer Grid is
// Visibility="{Binding IsSlotOccupied, Converter={StaticResource BoolToVisibility}}",
// and that converter yields Visibility.Collapsed, which WPF removes from layout
// entirely rather than merely hiding. So the row only ever contains the
// occupied cells, and the centred ItemsControl centres *those* - three minions
// in the tavern give a 3x138 row centred on screen, exactly as Hearthstone
// centres the shop itself. Reserving all seven widths instead pinned the row to
// a fixed 966pt and pushed every marker left of its minion.
@available(macOS 10.15, *)
struct BattlegroundsMinionPinningCardView: View {
    let card: BattlegroundsMinionPinningViewModel.ShopCard

    private static let cellWidth: CGFloat = 138
    private static let cellHeight: CGFloat = 190
    private static let markerSize: CGFloat = 30

    @ViewBuilder
    var body: some View {
        if card.isSlotOccupied {
            Color.clear
                .frame(width: Self.cellWidth, height: Self.cellHeight)
                .overlay(markers, alignment: .topTrailing)
                .overlay(recommendedTooltip, alignment: .topLeading)
        }
    }

    // Canvas.Top / Canvas.Right on the three Borders: 35/17, 66/3, 99/0.
    // Measured from the cell's top-right corner, hence the topTrailing anchor
    // and the negative x offsets.
    private var markers: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear

            if card.isMinionPinned {
                pinImage
                    .frame(width: Self.markerSize, height: Self.markerSize)
                    .offset(x: -17, y: 35)
            }

            if card.isTribePinned {
                ZStack {
                    pinImage
                        .frame(width: Self.markerSize, height: Self.markerSize)
                    BattlegroundsMinionTypeIcon(minionType: .race(card.tribeIconRace))
                        .frame(width: 23, height: 23)
                }
                .frame(width: Self.markerSize, height: Self.markerSize)
                .offset(x: -3, y: 66)
            }

            if card.isRecommendedPinned {
                keyImage
                    .frame(width: Self.markerSize, height: Self.markerSize)
                    .offset(x: 0, y: 99)
            }
        }
    }

    // Border Width="249" Canvas.Top="-90" Canvas.Left="{Binding
    // RecommendedSectionCanvasLeft}" - so it hangs above the cell and to
    // whichever side the view model picked (see tooltipOffset).
    @ViewBuilder
    private var recommendedTooltip: some View {
        if card.shouldShowRecommendedSection {
            RecommendedCompsTooltip(comps: card.recommendedComps)
                .frame(width: 249)
                .offset(x: card.recommendedSectionOffsetX, y: -90)
        }
    }

    private var pinImage: some View {
        Group {
            if let image = MinionPinningImages.pin {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
            }
        }
    }

    private var keyImage: some View {
        Group {
            if let image = MinionPinningImages.key {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
            }
        }
    }
}

// The "Comps – Enabler / Commit Piece" popover: a titled panel listing every
// comp guide that names this minion in its "when to commit" copy.
//
// HDT groups the ItemsControl by a "Key" property with a
// PropertyGroupDescription; BattlegroundsCompGuideViewModel has no such
// property, so every comp lands in one group and the grouping is a no-op -
// this renders the flat list it actually produces.
@available(macOS 10.15, *)
struct RecommendedCompsTooltip: View {
    let comps: [BattlegroundsCompGuideViewModel]

    var body: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 3) {
                ForEach(comps) { comp in
                    compRow(comp)
                }
            }
            .padding(.horizontal, 9)
            .padding(.top, 9)
            .padding(.bottom, 6)
        }
        .background(Color(hex: "#23272A"))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#141617"), lineWidth: 1))
        .cornerRadius(3)
    }

    // Not localized in HDT either - the string is a literal in the XAML.
    private var header: some View {
        HStack(spacing: 0) {
            Image("tier7-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 14, height: 14)
            Text(verbatim: "Comps – Enabler / Commit Piece")
                .chunkFive(size: 11)
                .outlinedText()
                .padding(.leading, 6)
                .padding(.vertical, 6)
            Spacer(minLength: 0)
        }
        .padding(.leading, 8)
        .background(Color(hex: "#1C2022"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .bottom)
        .cornerRadius(3, corners: [.topLeft, .topRight])
    }

    // Height="48" Margin="0,0,0,3", #141617 on a #CC4A5256 border, with the
    // comp's representative-card art faded behind the name.
    private func compRow(_ comp: BattlegroundsCompGuideViewModel) -> some View {
        HStack(spacing: 0) {
            Text(comp.compGuide.name)
                .chunkFive(size: 13)
                .outlinedText()
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
            Text(comp.tierText)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.white)
                .padding(.leading, 8)
                .padding(.trailing, 8)
                .padding(.top, 2)
                .padding(.bottom, 5)
                .background(LinearGradient(colors: comp.tierColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .cornerRadius(3)
        }
        .padding(.horizontal, 9)
        .frame(height: 48)
        .background(GuideCardArtBackground(card: comp.representativeCard, opacity: 0.4, gradientEnd: 0.80))
        .background(Color(hex: "#141617"))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#CC4A5256"), lineWidth: 1))
        .cornerRadius(3)
        .clipped()
    }
}

// pin.png / key.png, copied from HDT's Resources. Loaded from
// Resources/Battlegrounds rather than the asset catalog, matching the tier
// badges (see MinionsFilterImages).
enum MinionPinningImages {
    static let pin: NSImage? = load("pin")
    static let key: NSImage? = load("key")

    private static func load(_ name: String) -> NSImage? {
        guard let rp = Bundle.main.resourcePath else { return nil }
        return NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/\(name).png")
    }

    // The four HDT screenshots the quick guide is built around.
    static func guideExample(_ name: String) -> NSImage? {
        guard let rp = Bundle.main.resourcePath else { return nil }
        return NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/Tier7/\(name).png")
    }
}
