//
//  QuestGuideView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's QuestGuide.xaml: stacked below HeroGuideView within the
// Heroes tab (not its own tab - GuidesTabsView.content(for:.heroes) renders
// both), one section per selected quest reward. Renders nothing when no
// quest has been picked yet, same as HDT's ItemsControl over an empty
// SelectedQuests collection.
@available(macOS 10.15, *)
struct QuestGuideView: View {
    @ObservedObject var viewModel: BattlegroundsQuestGuidesViewModel

    var body: some View {
        if !viewModel.selectedQuests.isEmpty {
            VStack(spacing: 0) {
                ForEach(viewModel.selectedQuests) { quest in
                    section(quest)
                }
            }
            .background(Color(hex: "#23272A"))
            .overlay(RoundedRectangle(cornerRadius: 0).stroke(Color(hex: "#3f4346"), lineWidth: 1))
        }
    }

    private func section(_ quest: BattlegroundsQuestGuideViewModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(quest.questCard.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 9)
            .frame(height: 40)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#141617"))
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .top)

            if quest.isGuidePublished {
                VStack(alignment: .leading, spacing: 4) {
                    Text("How to Play")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    // FontSize 11 / LineHeight 17 in QuestGuide.xaml.
                    GuideText(text: quest.howToPlay, fontSize: 11, color: .white.opacity(0.7), lineSpacing: 6)
                }
                .padding(9)
            } else {
                Text("No guide available")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }

            if !quest.favorableTribes.isEmpty {
                HStack {
                    Text("Favorable Minions")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(quest.favorableTribes, id: \.self) { race in
                            Image("tribe_\(race.rawValue)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                .padding(9)
                .background(Color(hex: "#1c1f22"))
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .top)
            }
        }
    }
}
