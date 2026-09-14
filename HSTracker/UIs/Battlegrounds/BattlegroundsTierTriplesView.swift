//
//  BattlegroundsTierTriplesView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's BattlegroundsTierTriples.xaml (+ its code-behind's derived
// properties) and the BattlegroundsTier.xaml badge it hosts: one tavern tier's
// badge, how many triples the player took at that tier, and the turn they
// tavern'd up to it.
//
// A tier the player never reached has Turn == 0, which greys the badge, slides
// it to the middle of the cell and hides everything else.
@available(macOS 10.15, *)
struct BattlegroundsTierTriplesView: View {
    let model: BattlegroundsOpponentInfoViewModel.TierTriples

    // Canvas Height="42" Width="70" inside a StackPanel Margin="3 4 0 0"
    // Height="60", so the Border ends up 73 wide.
    static let width: CGFloat = 73

    private var turn: Int { model.turn }

    // BgColor / TierLeft / TierTop / TierOpacity / TripleOpacity /
    // TripleVisibility / QtyText, one for one.
    private var backgroundColor: Color { Color(hex: turn > 0 ? "#37393C" : "#282b2e") }
    private var tierLeft: CGFloat { turn > 0 ? 0 : 12 }
    private var tierTop: CGFloat { turn > 0 ? 2 : 7 }
    private var tierOpacity: Double { turn > 0 ? 1 : 0.5 }
    private var tripleOpacity: Double { model.qty > 0 ? 0 : 0.2 }
    private var tripleVisible: Bool { turn > 0 }
    private var qtyText: String { turn > 0 ? "\(model.qty)" : "" }
    private var turnText: String {
        turn > 0 ? String(format: String.localizedString("Turn %d", comment: ""), turn) : ""
    }

    var body: some View {
        // StackPanel Orientation="Vertical" Margin="3 4 0 0" Height="60"
        VStack(alignment: .leading, spacing: 0) {
            canvas
            turnLabel
        }
        .padding(EdgeInsets(top: 4, leading: 3, bottom: 0, trailing: 0))
        .frame(width: Self.width, height: 64, alignment: .topLeading)
        // Border CornerRadius="3"
        .background(backgroundColor)
        .cornerRadius(3)
    }

    // Canvas Height="42" Width="70", with each child at its literal
    // Canvas.Left/Canvas.Top.
    private var canvas: some View {
        ZStack(alignment: .topLeading) {
            Color.clear

            if let image = Self.tierImage(model.tier) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .opacity(tierOpacity)
                    .offset(x: tierLeft, y: tierTop)
            }

            if tripleVisible {
                Image("triple")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 34, height: 34)
                    .offset(x: 28, y: 2)

                // Drawn over the triple icon to dim it when the player took no
                // triples at this tier.
                Image("triple-black")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 34, height: 34)
                    .opacity(tripleOpacity)
                    .offset(x: 28, y: 2)

                Text(verbatim: qtyText)
                    .chunkFive(size: 15)
                    .outlinedText()
                    .fixedSize()
                    .offset(x: 40, y: 5)
            }
        }
        .frame(width: 70, height: 42, alignment: .topLeading)
    }

    // Label Foreground="White" FontSize="10" FontWeight="Bold"
    // Margin="2 -7 0 0" HorizontalAlignment="Center" - the 5pt inset is the WPF
    // Label template's own Padding.
    private var turnLabel: some View {
        Group {
            if tripleVisible {
                Text(verbatim: turnText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .fixedSize()
                    .padding(5)
                    .padding(EdgeInsets(top: -7, leading: 2, bottom: 0, trailing: 0))
            }
        }
        .frame(width: 70, alignment: .center)
    }

    // The tier-N.png badges in Resources/Battlegrounds, which is where the rest
    // of the Battlegrounds ports get them too.
    private static func tierImage(_ tier: Int) -> NSImage? {
        guard tier > 0, let rp = Bundle.main.resourcePath else { return nil }
        return NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/tier-\(tier).png")
    }
}
