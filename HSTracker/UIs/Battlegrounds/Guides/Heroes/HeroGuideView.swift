//
//  HeroGuideView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's HeroGuide.xaml.
@available(macOS 10.15, *)
struct HeroGuideView: View {
    @ObservedObject var viewModel: BattlegroundsHeroGuidesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let hero = viewModel.selectedHero {
                header(hero)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if hero.isGuidePublished {
                            guideContent(hero)
                        } else {
                            Text("No guide available")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                        }
                    }
                }
            } else {
                Text("Waiting for hero pick")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding(9)
    }

    private func header(_ hero: BattlegroundsHeroGuideViewModel) -> some View {
        HStack {
            Text(hero.heroCard.name)
                .chunkFive(size: 13)
                .outlinedText()
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 9)
        .frame(height: 48)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GuideCardArtBackground(card: hero.heroCard, opacity: 0.4, gradientEnd: 0.80))
        .background(Color(hex: "#141617"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .bottom)
        .clipped()
    }

    @ViewBuilder
    private func guideContent(_ hero: BattlegroundsHeroGuideViewModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("How to Play")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            // FontSize 11 / LineHeight 17 in HeroGuide.xaml.
            GuideText(text: hero.howToPlay, fontSize: 11, color: .white.opacity(0.7), lineSpacing: 6)
        }
        .padding(9)

        if hero.isBuddyGuidePublished {
            VStack(alignment: .leading, spacing: 4) {
                Text("Buddy Guide")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                // Same FontSize 11 / LineHeight 17 as the guide above.
                GuideText(text: hero.howToPlayBuddy, fontSize: 11, color: .white.opacity(0.7), lineSpacing: 6)
            }
            .padding(9)
        }

        if !hero.favorableTribes.isEmpty {
            VStack(alignment: .leading, spacing: 7) {
                Text("Favorable Minions")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 12) {
                    ForEach(hero.favorableTribes, id: \.self) { race in
                        Image("tribe_\(race.rawValue)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                    }
                }
            }
            .padding(9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#1c1f22"))
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .top)
        }

        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Created by")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.8))
                // Matches HDT's HeroGuide.xaml exactly: a hardcoded author
                // name, not part of the API response.
                Text("JeefHS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(7)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#141617"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .top)
    }
}
