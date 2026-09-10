//
//  BattlegroundsQuestTileView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// The quest badge shown for a hovered Battlegrounds opponent: the quest's art
// in its bubble frame, with the turn it was picked up underneath.
//
// This has no HDT counterpart - BattlegroundsOpponentInfo.xaml has never shown
// quests - so the layout here is carried over verbatim from HSTracker's own
// BattlegroundsQuestView.xib rather than ported from XAML, down to the "!"
// glyph drawn over the bubble (the bubble art itself is blank).
@available(macOS 10.15, *)
struct BattlegroundsQuestTileView: View {
    let quest: BattlegroundsOpponentInfoViewModel.Quest

    @SwiftUI.State private var art: NSImage?

    static let width: CGFloat = 83
    static let height: CGFloat = 108

    private var isLocked: Bool { quest.turn == 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            badge
            turnLabel
        }
        .padding(.top, 4)
        .frame(width: Self.width, height: Self.height, alignment: .topLeading)
        .onAppear(perform: loadArt)
    }

    // The 80x82 "Canvas" from the xib, with every child at its own offset.
    private var badge: some View {
        ZStack(alignment: .topLeading) {
            Color.clear

            if quest.dbfId > 0, let art {
                Image(nsImage: art)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .opacity(isLocked ? 0.5 : 1)
                    .offset(x: 5, y: 15)
            }

            Image("bacon_quest_frame")
                .resizable()
                .interpolation(.high)
                .frame(width: 80, height: 80)
                .offset(x: 0, y: 2)

            Image(isLocked ? "bacon_quest_locked" : "bacon_quest_exclamation")
                .resizable()
                .interpolation(.high)
                .frame(width: 30, height: 30)
                .offset(x: 25, y: 0)

            Text(verbatim: "!")
                .font(.system(size: 15))
                .foregroundColor(.white)
                .fixedSize()
                .offset(x: 38, y: 7)
        }
        .frame(width: 80, height: 82, alignment: .topLeading)
    }

    private var turnLabel: some View {
        Group {
            if !isLocked {
                Text(verbatim: String(format: String.localizedString("Turn %d", comment: ""), quest.turn))
                    .font(.custom("Impact", size: 13))
                    .foregroundColor(.white)
                    .fixedSize()
            }
        }
        .frame(width: Self.width, height: 16, alignment: .center)
    }

    private func loadArt() {
        guard quest.dbfId > 0, let card = Cards.by(dbfId: quest.dbfId, collectible: false) else {
            art = nil
            return
        }
        if let cached = ImageUtils.cachedArt(cardId: card.id) {
            art = cached
            return
        }
        ImageUtils.art(for: card.id) { image in
            guard let image else { return }
            DispatchQueue.main.async {
                self.art = image
            }
        }
    }
}
