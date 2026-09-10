//
//  BattlegroundsOpponentInfoView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's BattlegroundsOpponentInfo.xaml: the panel that drops down from
// the top of the screen while the cursor is over an opponent on the
// Battlegrounds leaderboard, showing the warband they were last seen with, how
// long ago that was, and the turns they tavern'd up on plus the triples they
// took at each tier.
//
// The quest box on the right has no HDT counterpart - it is HSTracker's own
// addition, carried over from the AppKit panel this replaces.
@available(macOS 10.15, *)
struct BattlegroundsOpponentInfoView: View {
    @ObservedObject var viewModel: BattlegroundsOpponentInfoViewModel

    // Height="150" on both Borders.
    private static let boxHeight: CGFloat = 150
    // MinWidth="740" on the board Border's inner StackPanel.
    private static let boardMinWidth: CGFloat = 740

    // Style TargetType="controls:BattlegroundsMinion": Width/Height 110,
    // Margin="0,20,-10,20". HSTracker's minion drawing is 300x350 rather than
    // HDT's square 256x256 viewbox, so the slot keeps HDT's 110pt width and
    // takes the height that preserves that aspect (the same call
    // BattlegroundsFinalBoardTooltip makes). The 20pt vertical margin is what
    // gives way for it: the padding here is whatever centres the taller slot in
    // the Border's literal 150pt height.
    private static let minionWidth: CGFloat = 110
    private static let minionHeight = BattlegroundsMinionRepresentable.height(forWidth: minionWidth)
    private static let minionVerticalPadding = (boxHeight - minionHeight) / 2
    private static let minionOverlap: CGFloat = 10

    // BorderBrush="#404345", and the LinearGradientBrush both Borders share
    // (StartPoint 0.5,0 -> EndPoint 0.5,1).
    private static let borderColor = Color(hex: "#404345")
    private static let gradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#202427"), Color(hex: "#23272A")]),
        startPoint: .top, endPoint: .bottom)

    // Gated in here rather than by the parent: RootOverlayView instantiates this
    // unconditionally so its @ObservedObject binding stays live, and a parent
    // does not re-render for a nested ObservableObject's changes.
    var body: some View {
        if viewModel.isShown {
            panel
        }
    }

    private var panel: some View {
        // The outer StackPanel is vertical with one horizontal child,
        // HorizontalAlignment="Center"; the tiers Border is
        // VerticalAlignment="Top", which is what the .top alignment here is.
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                boardBox
                ageText
            }
            tiersBox
            if !viewModel.quests.isEmpty {
                questsBox
            }
        }
        .fixedSize()
    }

    // MARK: - Board

    private var boardBox: some View {
        boardContent
            .frame(minWidth: Self.boardMinWidth)
            .frame(height: Self.boxHeight)
            .background(Self.gradient)
            // CornerRadius="0 0 0 3" - only the corner that isn't flush against
            // the screen edge or the box beside it.
            .cornerRadius(3, corners: .bottomLeft)
            // BorderThickness="1 0 1 1": no top edge, since the panel is pinned
            // to the very top of the overlay canvas.
            .overlay(boxEdges)
            .opacity(0.9)
    }

    @ViewBuilder
    private var boardContent: some View {
        if viewModel.notFoughtOpponent {
            message(String.localizedString("You have not fought this opponent", comment: ""))
        } else if viewModel.heroNoMinionsOnBoard {
            message(String.localizedString("No minions on board", comment: ""))
        } else {
            // StackPanel Name="BattlegroundsBoard" Margin="10 0 20 0",
            // HorizontalAlignment="Center".
            HStack(spacing: -Self.minionOverlap) {
                ForEach(Array(viewModel.minions.prefix(7).enumerated()), id: \.offset) { _, minion in
                    BattlegroundsMinionRepresentable(entity: minion)
                        .frame(width: Self.minionWidth, height: Self.minionHeight)
                        .padding(.vertical, Self.minionVerticalPadding)
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 20)
        }
    }

    // NotFoughtOpponent / HeroNoMinionsOnBoard: FontSize="16" Margin="50 63".
    private func message(_ text: String) -> some View {
        Text(verbatim: text)
            .chunkFive(size: 16)
            .outlinedText()
            .fixedSize()
            .padding(EdgeInsets(top: 63, leading: 50, bottom: 63, trailing: 50))
    }

    // BattlegroundsAge: FontSize="16" Margin="0, 5, 0, -5", left-aligned under
    // the board box because a vertical StackPanel's children stretch.
    private var ageText: some View {
        Text(verbatim: viewModel.boardAgeText)
            .chunkFive(size: 16)
            .outlinedText()
            .fixedSize()
            .padding(.top, 5)
            .padding(.bottom, -5)
    }

    // MARK: - Tiers

    private var tiersBox: some View {
        // StackPanel Name="TiersInfo" Margin="6 10 10 10", two rows of three.
        VStack(alignment: .leading, spacing: 0) {
            tierRow(0..<3)
            tierRow(3..<6)
                // Margin="0 5 0 0" on the second row.
                .padding(.top, 5)
        }
        .padding(EdgeInsets(top: 10, leading: 6, bottom: 10, trailing: 10))
        .frame(height: Self.boxHeight)
        .background(Self.gradient)
        // CornerRadius="0 0 3 0". With the HSTracker-only quest box present the
        // tiers box is no longer the rightmost one, so the rounded corner moves
        // along to whichever box actually ends the row.
        .cornerRadius(3, corners: viewModel.quests.isEmpty ? .bottomRight : [])
        .overlay(boxEdges)
        .opacity(0.9)
    }

    private func tierRow(_ range: Range<Int>) -> some View {
        HStack(spacing: 0) {
            ForEach(range, id: \.self) { index in
                BattlegroundsTierTriplesView(model: viewModel.tiers[index])
                    // Margin="5 0 0 0" on every tile.
                    .padding(.leading, 5)
            }
        }
    }

    // MARK: - Quests (HSTracker only)

    private var questsBox: some View {
        HStack(spacing: 5) {
            ForEach(viewModel.quests, id: \.dbfId) { quest in
                BattlegroundsQuestTileView(quest: quest)
            }
        }
        .padding(5)
        .frame(height: Self.boxHeight)
        .background(Self.gradient)
        .cornerRadius(3, corners: .bottomRight)
        .overlay(boxEdges)
        .opacity(0.9)
    }

    // MARK: - Shared chrome

    // BorderThickness="1 0 1 1" drawn as three hairlines rather than a stroked
    // shape, so the missing top edge stays missing.
    private var boxEdges: some View {
        ZStack {
            Self.borderColor.frame(width: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            Self.borderColor.frame(width: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            Self.borderColor.frame(height: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .allowsHitTesting(false)
    }
}
