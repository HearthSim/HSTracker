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
@available(macOS 10.15, *)
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

    // BattlegroundsTribe.xaml's outer Canvas is 38x38 with a 2pt border ring
    // and a 34pt image ellipse inside it; the name label below is a 16pt-tall
    // stack, FontSize 10, MaxWidth 38.
    private var canvasSize: CGFloat { 38 * scale }
    private var circleSize: CGFloat { 34 * scale }
    private var borderWidth: CGFloat { 2 * scale }

    var body: some View {
        VStack(spacing: 2 * scale) {
            ZStack {
                Image(BattlegroundsMinionType.race(race).iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: circleSize, height: circleSize)
                    .clipShape(Circle())
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
}
