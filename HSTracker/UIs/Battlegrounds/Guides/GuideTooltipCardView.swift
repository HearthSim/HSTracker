//
//  GuideTooltipCardView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's TrinketGuideTooltip.xaml/AnomalyGuideTooltip.xaml, which are
// identical apart from their view model's source card type - a floating card
// shown while hovering a trinket or anomaly, not the small text bubble from
// GuideTooltip.swift. HDT gives this its own header/footer bands, so it's a
// dedicated view rather than a GuideTooltipContent instance. Shared between
// both guide types rather than duplicated.
@available(macOS 10.15, *)
struct GuideTooltipCardView: View {
    let howToPlay: String
    let favorableTribes: [Race]
    // HeroGuideTooltip.xaml alone carries a second block under the guide, shown
    // while buddies are enabled; the trinket, quest and anomaly tooltips have
    // none, so it defaults to empty for them.
    var buddyGuide: String = ""

    // MaxWidth="300" MinWidth="200" on the Border; pinned, as the other
    // tooltips in this overlay are. Read by the pickers, which place the card
    // beside the hovered hero or reward.
    static let width: CGFloat = 260

    // HDT's HeroGuideVisibility, QuestGuideVisibility and
    // TrinketGuideVisibility all gate on the same pair of settings.
    static var isEnabled: Bool {
        return Settings.showBattlegroundsBrowser && Settings.showBattlegroundsGuides
    }

    var isGuidePublished: Bool { !howToPlay.isEmpty }
    private var isBuddyGuidePublished: Bool { isGuidePublished && !buddyGuide.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
            if !favorableTribes.isEmpty {
                footer
            }
        }
        .frame(width: Self.width)
        .background(Color(hex: "#292D30"))
        // Simplified from HDT's square-middle/rounded-top-and-bottom-bands
        // look to one uniform corner radius on the whole card.
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.3), lineWidth: 1))
    }

    private var header: some View {
        HStack {
            Text("How to Play")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            if isGuidePublished {
                VStack(spacing: 2) {
                    Text("Created by")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.8))
                    // Matches HDT's TrinketGuideTooltip.xaml exactly: a
                    // hardcoded author name, not part of the API response.
                    Text("JeefHS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(10)
        .background(Color(hex: "#1C2022"))
    }

    @ViewBuilder
    private var content: some View {
        if isGuidePublished {
            VStack(alignment: .leading, spacing: 0) {
                // TrinketGuideTooltip.xaml/AnomalyGuideTooltip.xaml both spec
                // FontSize 15 / LineHeight 23 here, not 13 with no line spacing.
                GuideText(text: howToPlay, fontSize: 15, color: .white, lineSpacing: 8)
                if isBuddyGuidePublished {
                    buddyBlock
                }
            }
            .padding(16)
        } else {
            Text("No guide available")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .padding(16)
        }
    }

    // HeroGuideTooltip.xaml's buddy block: a #1C2022 box with a 1pt #2e3235
    // border and a 5pt radius, 9pt of padding, 9pt below the guide, headed by
    // the Chunkfive "Buddy Guide" line the hero guide panel uses too.
    private var buddyBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Buddy Guide")
                .chunkFive(size: 12)
                .outlinedText()
            // FontSize 11 / LineHeight 17, as in the panel.
            GuideText(text: buddyGuide, fontSize: 11, color: .white.opacity(0.7), lineSpacing: 6)
        }
        .padding(9)
        .background(RoundedRectangle(cornerRadius: 5).fill(Color(hex: "#1C2022")))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: "#2e3235"), lineWidth: 1))
        .padding(.top, 9)
    }

    private var footer: some View {
        HStack {
            Text("Favorable Minions")
                .font(.system(size: 11))
                .foregroundColor(.white)
            Spacer()
            HStack(spacing: 8) {
                ForEach(favorableTribes, id: \.self) { race in
                    // TrinketGuideTooltip.xaml/AnomalyGuideTooltip.xaml both wrap
                    // session:BattlegroundsTribe in a LayoutTransform ScaleX/Y="0.9".
                    BattlegroundsTribeIconView(race: race, scale: 0.9)
                }
            }
        }
        .padding(10)
        .background(Color(hex: "#1C2022"))
    }
}
