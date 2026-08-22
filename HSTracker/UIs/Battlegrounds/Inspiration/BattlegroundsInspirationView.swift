//
//  BattlegroundsInspirationView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's BattlegroundsInspiration.xaml: a 936x800 panel listing
// first-place lineups that contained the clicked minion, four to a page.
//
// The outer Border is Width=936 Height=800, BorderBrush #4A5256, Background
// #2E3235, CornerRadius 5, with a 25pt blur drop shadow. Inside it a DockPanel
// stacks a title bar, a description strip, a pager docked to the bottom, and
// the lineup list filling what is left.
//
// isShown is checked here, in the view holding its own @ObservedObject - see
// MulliganGuideTrialsExhaustedView for why gating from RootOverlayView doesn't
// reliably react to a nested ObservableObject.
@available(macOS 10.15, *)
struct BattlegroundsInspirationView: View {
    @ObservedObject var viewModel: BattlegroundsInspirationViewModel

    static let panelWidth: CGFloat = 936
    static let panelHeight: CGFloat = 800
    // Height="170" on the DockPanel inside each lineup row.
    private static let rowHeight: CGFloat = 170

    var body: some View {
        if viewModel.isShown {
            VStack(spacing: 0) {
                titleBar
                descriptionBar
                lineups
                pager
            }
            .frame(width: Self.panelWidth, height: Self.panelHeight)
            .background(Color(hex: "#2E3235"))
            .cornerRadius(5)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "#4A5256"), lineWidth: 1))
            .shadow(radius: 12.5)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                           value: [proxy.frame(in: .rootOverlayCanvas)])
                }
            )
        }
    }

    // MARK: - Chrome

    // Background #1C2022, CornerRadius "5,5,0,0", 1pt bottom border, Margin 6.
    // Three elements in one Grid: the logo + product name pinned left, the key
    // minion's name centred, and the close button pinned right.
    private var titleBar: some View {
        ZStack {
            Text(viewModel.titleText)
                .chunkFive(size: 16)
                .outlinedText()
                .lineLimit(1)

            HStack(spacing: 0) {
                Image("tier7-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                    .padding(.trailing, 6)
                Text(BattlegroundsInspirationViewModel.localized("BattlegroundsInspiration_Title",
                                                                fallback: "Tier7 Inspiration"))
                    .chunkFive(size: 16)
                    .outlinedText()
                Spacer(minLength: 0)
                closeButton
            }
        }
        .padding(6)
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#1C2022"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .bottom)
    }

    // AccentedSquareButtonStyle with a 16pt appbar_close_white glyph. HSTracker
    // has no MahApps accent brushes, so this reuses the same #1D3657 the rest
    // of the overlay treats as the HSReplay accent.
    private var closeButton: some View {
        Button {
            viewModel.close()
        } label: {
            Image("close")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .padding(4)
                .background(Color(hex: "#1D3657"))
                .cornerRadius(3)
        }
        .buttonStyle(.plain)
    }

    // Second docked strip: what the list is, and which slice of the ladder it
    // was sampled from.
    private var descriptionBar: some View {
        HStack(spacing: 0) {
            Text(BattlegroundsInspirationViewModel.localized("BattlegroundsInspiration_Description",
                                                            fallback: "1st Place Lineups"))
            Spacer(minLength: 0)
            Text(viewModel.mmrText)
        }
        .font(.system(size: 13))
        .foregroundColor(.white.opacity(0.8))
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#1C2022"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .bottom)
    }

    // MARK: - Lineups

    @ViewBuilder
    private var lineups: some View {
        ZStack {
            if viewModel.isLoadingData {
                // mah:ProgressRing, 40x40, white. SwiftUI's ProgressView needs
                // macOS 11, so this wraps AppKit's spinner - the same control
                // BobsBuddyPanel already uses for its own loading state.
                SpinningIndicator()
                    .frame(width: 40, height: 40)
            } else if viewModel.hasNoGames {
                Text(BattlegroundsInspirationViewModel.localized("BattlegroundsInspiration_NoData",
                                                                fallback: "No data available. Please check back later."))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.pagedGames) { game in
                        InspirationLineupRow(game: game, viewModel: viewModel)
                            .frame(height: Self.rowHeight)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Pager

    // Bottom Border: #1C2022, CornerRadius "0,0,5,5", Height 40, buttons
    // Width=40 Margin="4,0", the active one filled with the accent colour.
    private var pager: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.pageButtons) { button in
                Button {
                    viewModel.setPage(button.page)
                } label: {
                    Text("\(button.page)")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 28)
                        .background(button.isActive ? Color(hex: "#1D3657") : Color(hex: "#2E3235"))
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(hex: "#4A5256"), lineWidth: 1))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#1C2022"))
    }
}

// NSProgressIndicator in its spinning style, sized by its SwiftUI frame.
@available(macOS 10.15, *)
private struct SpinningIndicator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSProgressIndicator {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.isIndeterminate = true
        indicator.controlSize = .regular
        // The overlay is dark throughout, so force the light-on-dark variant
        // rather than following the system appearance.
        indicator.appearance = NSAppearance(named: .vibrantDark)
        indicator.startAnimation(nil)
        return indicator
    }

    func updateNSView(_ nsView: NSProgressIndicator, context: Context) {
        nsView.startAnimation(nil)
    }
}

// MARK: - One lineup

// The DataTemplate for each game: hero portrait with its crown and hero power
// on the left, the final board on the right, separated by a hairline. The row
// carries a 1pt bottom border and a top/bottom inner shadow (a vertical
// gradient from 32-alpha black at both edges to transparent at 10%/90%).
@available(macOS 10.15, *)
private struct InspirationLineupRow: View {
    @ObservedObject var game: BattlegroundsInspirationGameViewModel
    @ObservedObject var viewModel: BattlegroundsInspirationViewModel

    // Width="110" on each BattlegroundsMinion, Margin="-4,0" so neighbours
    // overlap slightly. HSTracker's minion art is authored 300x350, so the
    // height follows from the width rather than being square as in HDT.
    private static let minionWidth: CGFloat = 110
    private static let minionHeight: CGFloat = 110 * 350 / 300

    var body: some View {
        HStack(spacing: 0) {
            heroColumn
                .padding(.trailing, 15)
            boardColumn
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Self.edgeShadow)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .bottom)
    }

    private static var edgeShadow: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .black.opacity(32.0 / 255.0), location: 0),
                .init(color: .black.opacity(0), location: 0.1),
                .init(color: .black.opacity(0), location: 0.9),
                .init(color: .black.opacity(32.0 / 255.0), location: 1)
            ]),
            startPoint: .top, endPoint: .bottom
        )
    }

    // The hero Grid is sized by its 140x140 portrait. Two things hang off it:
    // the crown, 48x48 centred on the top edge at Margin="0,-20,0,0" so it
    // overhangs by 20; and the hero power, bottom-right at Margin="-15,5",
    // which puts it 15 past the right edge and 5 up from the bottom.
    //
    // The container is grown to fit both overhangs rather than letting them
    // clip: 140 + 15 wide, and 140 + 20 tall with the grid pushed down by the
    // crown's overhang.
    private static let heroSize: CGFloat = 140
    private static let crownSize: CGFloat = 48
    private static let crownOverhang: CGFloat = 20
    private static let heroPowerOverhang: CGFloat = 15
    private static let columnWidth = heroSize + heroPowerOverhang
    private static let columnHeight = heroSize + crownOverhang

    private var heroColumn: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.frame(width: Self.columnWidth, height: Self.columnHeight)

            if let heroImage = game.heroImage {
                Image(nsImage: heroImage)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Self.heroSize, height: Self.heroSize)
                    .offset(y: Self.crownOverhang)
            }

            Image("bgs_crown_large")
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: Self.crownSize, height: Self.crownSize)
                .offset(x: (Self.heroSize - Self.crownSize) / 2)

            InspirationHeroPowerView(card: game.heroPowerCard, cost: game.heroPowerCost) {
                if let card = game.heroPowerCard {
                    viewModel.setKeyMinion([card])
                }
            }
            .offset(x: Self.heroSize - InspirationHeroPowerView.displaySize + Self.heroPowerOverhang,
                    y: Self.crownOverhang + Self.heroSize - InspirationHeroPowerView.displaySize - 5)
        }
        .frame(width: Self.columnWidth, height: Self.columnHeight)
    }

    // StackPanel Width="750", the board centred inside it.
    private var boardColumn: some View {
        HStack(spacing: -8) {
            ForEach(game.board) { minion in
                Button {
                    viewModel.setKeyMinion([minion.card])
                } label: {
                    BattlegroundsMinionArtView(minion: BattlegroundsMinionArt(
                        card: minion.card,
                        attack: minion.attack,
                        health: minion.health,
                        isPremium: minion.isPremium,
                        hasTaunt: minion.hasTaunt,
                        hasReborn: minion.hasReborn,
                        hasDeathrattle: minion.hasDeathrattle,
                        hasPoisonous: minion.hasPoisonous,
                        hasVenomous: minion.hasVenomous,
                        hasDivineShield: minion.hasDivineShield
                    ))
                    .scaledToFrame(width: Self.minionWidth, height: Self.minionHeight)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 750)
        .frame(maxHeight: .infinity)
        // BorderThickness="1,0,0,0" with a 3%-white brush, over the same
        // top/bottom shadow as the row but at 64 alpha rather than 32.
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .black.opacity(64.0 / 255.0), location: 0),
                    .init(color: .black.opacity(0), location: 0.1),
                    .init(color: .black.opacity(0), location: 0.9),
                    .init(color: .black.opacity(64.0 / 255.0), location: 1)
                ]),
                startPoint: .top, endPoint: .bottom
            )
        )
        .overlay(Rectangle().frame(width: 1).foregroundColor(.white.opacity(0.03)), alignment: .leading)
    }
}

// MARK: - Hero power

// Mirrors HDT's HeroPower control on a 256x256 canvas: the card portrait
// clipped to a circle (radius 70 about 80,80 within a 160x160 image at 48,60),
// the hero_power frame at 3,3 sized 250x250, and - unless the power hides its
// cost - the coin gem at 88,6 with the cost number on top.
//
// The control wraps that canvas in a `Viewbox Width="110" Height="110"`, and
// the Inspiration panel scales it a further 0.75 via a LayoutTransform - so it
// lands at 82.5pt on screen.
@available(macOS 10.15, *)
private struct InspirationHeroPowerView: View {
    let card: Card?
    let cost: Int?
    let onTap: () -> Void

    private static let canvas: CGFloat = 256
    static let displaySize: CGFloat = 110 * 0.75

    @SwiftUI.State private var portrait: NSImage?
    @SwiftUI.State private var isHovering = false

    var body: some View {
        if let card {
            Button(action: onTap) {
                ZStack(alignment: .topLeading) {
                    Color.clear.frame(width: Self.canvas, height: Self.canvas)

                    if let portrait {
                        Image(nsImage: portrait)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 160, height: 160)
                            .clipShape(Circle().path(in: CGRect(x: 10, y: 10, width: 140, height: 140)))
                            .offset(x: 48, y: 60)
                    }

                    Image("hero_power")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 250, height: 250)
                        .offset(x: 3, y: 3)

                    if let cost {
                        Image("coin-cost")
                            .resizable()
                            .interpolation(.high)
                            .frame(width: 80, height: 80)
                            .offset(x: 88, y: 6)
                        Text("\(cost)")
                            .font(.system(size: 60, weight: .bold))
                            .outlinedText()
                            .frame(width: 75, height: 75, alignment: .center)
                            .offset(x: 90, y: 6)
                    }
                }
                .frame(width: Self.canvas, height: Self.canvas)
                .scaleEffect(Self.displaySize / Self.canvas, anchor: .topLeading)
                .frame(width: Self.displaySize, height: Self.displaySize, alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // Same 1.05 hover pop the minions get, per the HeroPower style in
            // BattlegroundsInspiration.xaml.
            .scaleEffect(isHovering ? 1.05 : 1.0)
            .trackHover { isHovering = $0 }
            .cardImageTooltip(cardId: card.id, showTriple: false, placement: .right)
            .onAppear(perform: loadPortrait)
        }
    }

    private func loadPortrait() {
        guard let cardId = card?.id else { return }
        if let cached = ImageUtils.cachedArt(cardId: cardId) {
            portrait = cached
            return
        }
        ImageUtils.art(for: cardId) { img in
            DispatchQueue.main.async { self.portrait = img }
        }
    }
}
