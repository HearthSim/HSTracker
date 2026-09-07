//
//  RelatedCardsTooltipPanel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/26/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's CardTooltip.xaml GridCardImages + PoolSummaryView pair - the
// "related cards" half of that control, as opposed to the single/golden card
// preview half already ported in CardImageTooltip.swift's CardTooltipPanel.
// Replaces the old AppKit GridCardImages/NSCollectionView tooltip window with
// SwiftUI content hosted in a plain NSPanel, following that same precedent.

@available(macOS 10.15, *)
final class RelatedCardsTooltipViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var cards: [Card] = []
    @Published var maxGridHeight: Int?
    @Published var poolStatistics: PoolStatistics?
    @Published var relatedCardsSummary: [String: String]?
    @Published var hasLargePool: Bool = false

    var layout: RelatedCardsGridLayout {
        RelatedCardsGridLayout(cardCount: cards.count, maxGridHeight: maxGridHeight)
    }
}

// Ported from GridCardImages.xaml.cs's Update(): rather than a fixed column
// count, HDT searches every possible row count (its Columns dependency
// property is left at its -1/auto default by every caller, including the
// pool tooltip this mirrors) and keeps whichever (rows, cols) pair lets cards
// render largest without exceeding the grid's width/height bounds or its
// 0.85 native-scale cap. A fixed 3-column cap starves huge pools (a card
// with dozens of possible outcomes) into single-digit-point-tall cells -
// this reproduces HDT's actual search instead of clamping columns.
struct RelatedCardsGridLayout {
    static let gridWidth = 600
    static let gridHeight = 750
    private static let maxScale = 0.85
    // HDT's CardWidth/CardHeight (256x388) plus its CardMargin (-2, -14, -2, -14):
    // the crop margin baked into each cell's footprint before scaling.
    private static let effectiveCardWidth = 256.0 - 4
    private static let effectiveCardHeight = 388.0 - 28
    static let baseCardHeight = 194.0

    let columns: Int
    let rows: Int
    let cardWidth: Int
    let cardHeight: Int
    let gridWidth: Int
    let gridHeight: Int

    init(cardCount: Int, maxGridHeight: Int?) {
        guard cardCount > 0 else {
            columns = 0
            rows = 0
            cardWidth = 0
            cardHeight = 0
            gridWidth = 0
            gridHeight = 0
            return
        }

        // Container margin HDT reserves before fitting cards (ItemsControl's Margin="5,0").
        let maxWidth = Double(Self.gridWidth) - 10
        let maxHeight = Double(maxGridHeight ?? Self.gridHeight)

        var bestRows = 1
        var bestCols = cardCount
        var bestScale: Double

        if cardCount <= 3 {
            // Small pools always size as if laid out 3-wide, so a 1- or 2-card pool
            // doesn't blow up to fill the whole box.
            bestCols = cardCount
            bestRows = 1
            bestScale = min(Self.maxScale, maxWidth / (Self.effectiveCardWidth * 3))
        } else {
            bestScale = 0
            for candidateRows in 1..<cardCount {
                let candidateCols = Int(ceil(Double(cardCount) / Double(candidateRows)))
                let scale = min(Self.maxScale, min(maxHeight / (Self.effectiveCardHeight * Double(candidateRows)),
                                                    maxWidth / (Self.effectiveCardWidth * Double(candidateCols))))
                if scale > bestScale {
                    bestScale = scale
                    bestRows = candidateRows
                    bestCols = candidateCols
                }
            }
        }

        columns = bestCols
        rows = bestRows
        cardWidth = Int(Self.effectiveCardWidth * bestScale)
        cardHeight = Int(Self.effectiveCardHeight * bestScale)
        gridWidth = columns * cardWidth
        gridHeight = rows * cardHeight + 35
    }
}

// Ports GridCardImageItem's negative-constraint crop (calculateCardMargin in
// the old GridCardImages.swift): Hearthstone's card art PNGs carry extra
// border padding, so the image is inflated slightly beyond the cell and
// clipped back down, cropping that padding away instead of shrinking the art.
@available(macOS 10.15, *)
private struct RelatedCardImageView: View {
    let card: Card
    let width: CGFloat
    let height: CGFloat
    @SwiftUI.State private var image: NSImage?

    private var insetX: CGFloat { 2 * (height / RelatedCardsGridLayout.baseCardHeight) }
    private var insetY: CGFloat { 13 * (height / RelatedCardsGridLayout.baseCardHeight) }

    private var loadingImageName: String {
        switch card.type {
        case .hero: return "loading_hero"
        case .minion: return "loading_minion"
        case .weapon: return "loading_weapon"
        default: return "loading_spell"
        }
    }

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
            } else {
                Image(loadingImageName).resizable().aspectRatio(contentMode: .fit)
            }
        }
        .frame(width: width + insetX * 2, height: height + insetY * 2)
        .frame(width: width, height: height)
        .clipped()
        .onAppear(perform: loadImage)
    }

    private func loadImage() {
        let cardId = card.id
        if card.baconCard {
            ImageUtils.cardArtBG(for: cardId, baconTriple: false) { img in
                DispatchQueue.main.async { self.image = img }
            }
        } else {
            ImageUtils.cardArt(for: cardId) { img in
                DispatchQueue.main.async { self.image = img }
            }
        }
    }
}

// Ported from Controls/GridCardImages.xaml: a titled, rounded dark box
// holding the card grid.
@available(macOS 10.15, *)
struct RelatedCardsGridView: View {
    let title: String
    let cards: [Card]
    let layout: RelatedCardsGridLayout

    var body: some View {
        VStack(spacing: 0) {
            if !title.isEmpty {
                Text(title)
                    .chunkFive(size: 15)
                    .foregroundColor(.white)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#1C2022"))
            }
            if layout.columns > 0 {
                // LazyVGrid needs macOS 11 - this file's baseline is 10.15, matching
                // the rest of this codebase's SwiftUI ports - so rows/columns are laid
                // out by hand from the already-known layout.rows/columns instead.
                VStack(spacing: 0) {
                    ForEach(0..<layout.rows, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<layout.columns, id: \.self) { column in
                                let index = row * layout.columns + column
                                if index < cards.count {
                                    RelatedCardImageView(card: cards[index], width: CGFloat(layout.cardWidth), height: CGFloat(layout.cardHeight))
                                        // This panel is a singleton whose hosting view outlives any
                                        // one hover, so a grid slot keeps its view identity when the
                                        // next tooltip reuses it - and RelatedCardImageView loads its
                                        // art from .onAppear, which fires once per identity. Without
                                        // keying identity to the card, hovering the Beetle counter and
                                        // then the Blood Gem counter left the gem's slot still showing
                                        // the beetle render under the new title.
                                        .id(cards[index].imageIdentity)
                                }
                            }
                        }
                    }
                }
                .padding(5)
            }
        }
        .frame(width: CGFloat(layout.gridWidth))
        .background(Color(hex: "#CC2E3235"))
        .cornerRadius(10)
    }
}

// Ports Controls/Tooltips/PoolSummaryView.xaml: median/bar-chart distribution
// for cost/attack/health, plus keyword-match percentages (populated only once
// the Outfinder trial/premium keyword fetch is wired up - relatedCardsSummary
// stays nil until then, which just hides that section, matching HDT's own
// NullableToVisibility binding).
//
// The HSReplay-branding divider HDT shows above the keyword chips
// (TheOutfinder_Label_Title + the premium gold color/icon) is omitted here -
// nothing that reads it exists in HSTracker yet, and it's dead weight until
// the premium wiring lands alongside real keyword data.
@available(macOS 10.15, *)
struct PoolSummaryPanelView: View {
    static let width: CGFloat = 330

    let totalCardCount: Int
    let statistics: PoolStatistics
    let relatedCardsSummary: [String: String]?
    let hasLargePool: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text(String(format: String.localizedString("TheOutfinder_Label_PoolOfCards", comment: ""), totalCardCount))
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#9AABB5"))
                .padding(.top, 10)
                .padding(.bottom, 2)

            HStack(alignment: .top, spacing: 8) {
                StatBarColumnView(labelText: String.localizedString("TheOutfinder_Label_Cost", comment: ""),
                                  labelColor: Color(hex: "#4A6FA5"), barColor: Color(hex: "#4A6FA5"),
                                  bars: statistics.costBars, medianText: statistics.medianCostText)
                if let attackBars = statistics.attackBars, let medianAttackText = statistics.medianAttackText {
                    StatBarColumnView(labelText: String.localizedString("TheOutfinder_Label_Attack", comment: ""),
                                      labelColor: Color(hex: "#BFA010"), barColor: Color(hex: "#FCD116"),
                                      bars: attackBars, medianText: medianAttackText)
                }
                if let healthBars = statistics.healthBars, let medianHealthText = statistics.medianHealthText {
                    StatBarColumnView(labelText: String.localizedString("TheOutfinder_Label_Health", comment: ""),
                                      labelColor: Color(hex: "#8A4A4A"), barColor: Color(hex: "#8A4A4A"),
                                      bars: healthBars, medianText: medianHealthText)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            if let relatedCardsSummary, !relatedCardsSummary.isEmpty {
                // No LazyVGrid (macOS 11+, this file's baseline is 10.15) - chunked into
                // fixed-size rows instead of a true wrap, which is a fair approximation
                // for a handful of keyword chips in a 330pt-wide panel.
                let entries = relatedCardsSummary.sorted(by: { $0.key < $1.key })
                let chipsPerRow = 3
                VStack(spacing: 6) {
                    ForEach(0..<Int(ceil(Double(entries.count) / Double(chipsPerRow))), id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<chipsPerRow, id: \.self) { column in
                                let index = row * chipsPerRow + column
                                if index < entries.count {
                                    let (key, value) = entries[index]
                                    VStack(spacing: 2) {
                                        Text(value)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                        Text(key)
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(hex: "#8A9BA8"))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(Color(hex: "#1A2228"))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#2E3E4A"), lineWidth: 1))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }

            if hasLargePool {
                Text(String.localizedString("TheOutfinder_Label_RightClickHint", comment: ""))
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(Color(hex: "#8A9BA8"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }
        }
        .padding(.bottom, 10)
        .frame(width: Self.width)
        .background(Color(hex: "#DD1E2428"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#2C3A42"), lineWidth: 1))
    }
}

@available(macOS 10.15, *)
private struct StatBarColumnView: View {
    let labelText: String
    let labelColor: Color
    let barColor: Color
    let bars: [StatBar]
    let medianText: String

    private static let barAreaHeight: CGFloat = 40

    var body: some View {
        VStack(spacing: 3) {
            Text(labelText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(labelColor)
            HStack(alignment: .bottom, spacing: 1) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                    VStack(spacing: 2) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(bar.isMedian ? Color.white : barColor)
                            .frame(height: max(CGFloat(bar.barHeight), 1))
                        Text(bar.label)
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "#7A8E97"))
                    }
                }
            }
            .frame(height: Self.barAreaHeight + 14, alignment: .bottom)
            Text(medianText)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            Text(String.localizedString("TheOutfinder_Label_Median", comment: ""))
                .font(.system(size: 9))
                .foregroundColor(Color(hex: "#556066"))
        }
    }
}

@available(macOS 10.15, *)
private struct RelatedCardsTooltipContentView: View {
    @ObservedObject var viewModel: RelatedCardsTooltipViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Mirrors HDT's CardTooltipViewModel.RelatedCards being nulled out (and the
            // GridCardImages control's Visibility collapsing) once the pool exceeds
            // LargePoolThreshold - the card grid is omitted entirely rather than rendered
            // shrunk, leaving only the summary panel + right-click hint. totalCardCount
            // still reads viewModel.cards.count here since it's unaffected by this check.
            if !viewModel.hasLargePool {
                RelatedCardsGridView(title: viewModel.title, cards: viewModel.cards, layout: viewModel.layout)
            }
            if let statistics = viewModel.poolStatistics {
                PoolSummaryPanelView(totalCardCount: viewModel.cards.count, statistics: statistics,
                                     relatedCardsSummary: viewModel.relatedCardsSummary, hasLargePool: viewModel.hasLargePool)
            }
        }
    }
}

// Public surface mirrors the old GridCardImages/tooltipGridCards closely
// (setCardIdsFromCards, title, gridWidth/gridHeight) so callers that compute
// their own desired frame from gridWidth/gridHeight before positioning it
// (Tracker.swift, Game.swift, CounterChipView.swift) needed only their
// show/hide call sites updated, not their positioning math.
@available(macOS 10.15, *)
final class RelatedCardsTooltipPanel: NSPanel {
    static let shared = RelatedCardsTooltipPanel()

    private let viewModel = RelatedCardsTooltipViewModel()

    // No real per-card pool data flows into this yet (that needs the Pools/
    // card architecture, out of scope for this pass) - a generous fixed
    // estimate is fine until then.
    private static let estimatedPoolPanelHeight = 260

    // The grid layout's own footprint is omitted from both once hasLargePool is set,
    // matching RelatedCardsTooltipContentView no longer rendering RelatedCardsGridView -
    // otherwise the window would be framed for a grid that's no longer on screen.
    var gridWidth: Int {
        (viewModel.hasLargePool ? 0 : viewModel.layout.gridWidth) + (viewModel.poolStatistics != nil ? Int(PoolSummaryPanelView.width) : 0)
    }

    var gridHeight: Int {
        max(viewModel.hasLargePool ? 0 : viewModel.layout.gridHeight, viewModel.poolStatistics != nil ? Self.estimatedPoolPanelHeight : 0)
    }

    var cards: [Card] { viewModel.cards }

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: RelatedCardsGridLayout.gridWidth, height: RelatedCardsGridLayout.gridHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        isOpaque = false
        backgroundColor = .clear
        ignoresMouseEvents = true
        hasShadow = true
        hidesOnDeactivate = false
        animationBehavior = .none
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)) + 1)

        contentView = NSHostingView(rootView: RelatedCardsTooltipContentView(viewModel: viewModel))
    }

    func setCardIdsFromCards(_ cards: [Card]?, _ maxGridHeight: Int? = nil) {
        guard let cards else { return }
        viewModel.maxGridHeight = maxGridHeight
        viewModel.cards = cards
    }

    func setTitle(_ title: String) {
        viewModel.title = title
    }

    func setPoolStatistics(_ statistics: PoolStatistics?, relatedCardsSummary: [String: String]?, hasLargePool: Bool) {
        viewModel.poolStatistics = statistics
        viewModel.relatedCardsSummary = relatedCardsSummary
        viewModel.hasLargePool = hasLargePool
    }

    func show(frame: NSRect) {
        collectionBehavior = Settings.canJoinFullscreen ? [.canJoinAllSpaces, .fullScreenAuxiliary] : []
        if frame.origin.x.isFinite && frame.origin.y.isFinite && frame.size.width.isFinite && frame.size.height.isFinite {
            setFrame(frame, display: true, animate: false)
        }
        orderFront(nil)
    }

    func hide() {
        orderOut(nil)
    }
}
