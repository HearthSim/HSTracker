//
//  BattlegroundsTribeIconView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/24/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's BattlegroundsTribe.xaml (Controls/Overlay/Battlegrounds/Session):
// a circular, green-ringed tribe portrait with the tribe's localized name below
// it. Guide views (HeroGuide.xaml, TrinketGuideTooltip.xaml, etc.) all render
// their "Favorable Minions" lists with this control at LayoutTransform
// ScaleX/Y="0.9", rather than the flat square icon HSTracker used to show -
// hence the `scale` parameter instead of a fixed size.
struct BattlegroundsTribeIconView: View {
    // HDT's BattlegroundsTribe.MinionTypeAvailability, which picks the ring
    // colour and whether the crossed-out overlay is drawn.
    enum Availability {
        case available
        case banned

        // BattlegroundsTribe.xaml.cs's BorderColor.
        var borderColor: Color {
            switch self {
            case .available: return Color(hex: "#16d220")
            case .banned: return Color(hex: "#D44040")
            }
        }
    }

    let race: Race
    var availability: Availability = .available
    var scale: CGFloat = 1.0
    // HDT's Deity dependency property: the session panel binds the player's
    // Deity so the Aberration slot shows it instead of the generic icon.
    var deity: Card?

    // A banned Aberration type never gets a Deity, so it keeps the generic icon.
    private var shownDeity: Card? {
        guard let deity, race == .aberration, availability == .available else { return nil }
        return deity
    }

    // BattlegroundsTribe.xaml's outer Canvas is 38x38 with a 2pt border ring
    // and a 34pt image ellipse inside it; the name label below is a 16pt-tall
    // stack, FontSize 10, MaxWidth 38.
    private var canvasSize: CGFloat { 38 * scale }
    private var circleSize: CGFloat { 34 * scale }
    private var borderWidth: CGFloat { 2 * scale }

    var body: some View {
        VStack(spacing: 2 * scale) {
            ZStack {
                if let shownDeity {
                    // DeityVisibility: the Deity's portrait, keyed on its id so
                    // a changed Deity loads its own art. The generic icon stays
                    // up until that art has loaded.
                    DeityPortrait(cardId: shownDeity.id, size: circleSize) {
                        tribeIcon
                    }
                    .id(shownDeity.id)
                } else {
                    tribeIcon
                }
                // BorderColor defaults to "#16d220" (Availability.Available) -
                // none of the guide call sites bind Availability, so there it's
                // always the green ring; the session panel's banned list is the
                // one caller that asks for the red one.
                Circle()
                    .stroke(availability.borderColor, lineWidth: borderWidth)
                    .frame(width: circleSize, height: circleSize)
                // XVisibility: a 26pt cross, Canvas.Left="16" Canvas.Top="15"
                // within the 38pt canvas, i.e. offset from its centre by
                // (16 + 13) - 19 = 10 in X and (15 + 13) - 19 = 9 in Y.
                if availability == .banned {
                    Image("tribes-x")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 26 * scale, height: 26 * scale)
                        .offset(x: 10 * scale, y: 9 * scale)
                }
            }
            .frame(width: canvasSize, height: canvasSize)
            Text(BattlegroundsMinionType.raceName(race))
                .font(.system(size: 10 * scale))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: canvasSize, height: 16 * scale)
        }
        .fixedSize()
    }

    private var tribeIcon: some View {
        Image(BattlegroundsMinionType.race(race).iconName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: circleSize, height: circleSize)
            .clipShape(Circle())
    }
}

// The Deity half of BattlegroundsTribe.xaml: a CardAssetType.Portrait ImageBrush
// filling the 34pt ellipse under ScaleTransform ScaleX/Y="1.5" CenterX="18"
// CenterY="13".
//
// Until the portrait has loaded it shows `placeholder` - the generic Aberration
// icon - rather than an empty circle, as HDT's ShowsDeity waits on the asset's
// IsLoaded.
private struct DeityPortrait<Placeholder: View>: View {
    let cardId: String
    let size: CGFloat
    @ViewBuilder let placeholder: () -> Placeholder

    @SwiftUI.State private var portrait: NSImage?

    var body: some View {
        Group {
            if let portrait {
                Image(nsImage: portrait)
                    .resizable()
                    .frame(width: size, height: size)
                    .scaleEffect(1.5, anchor: UnitPoint(x: 18.0 / 34.0, y: 13.0 / 34.0))
            } else {
                placeholder()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .onAppear(perform: load)
    }

    private func load() {
        if let cached = ImageUtils.cachedArt(cardId: cardId) {
            portrait = cached
            return
        }
        ImageUtils.art(for: cardId) { img in
            DispatchQueue.main.async {
                self.portrait = img
            }
        }
    }
}
