//
//  BattlegroundsNotificationsView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's BattlegroundsHeroPanel.xaml and BattlegroundsTimewarpPanel.xaml,
// which are the same control twice over: a purple card with the Battlegrounds
// toast art behind it, offering to open the matching HSReplay.net page. Both
// are OverlayToastPanel, the chrome they share with the mulligan toast.
//
// Both hang off the canvas's right edge, where their OverlayElementBehaviors put
// them (GetRight = 0, AnchorSide = Bottom, GetScaling = AutoScaling), the hero
// one 4% of the canvas height off the bottom and the Timewarp one 5%.
@available(macOS 10.15, *)
struct BattlegroundsNotificationsView: View {
    @ObservedObject var viewModel: BattlegroundsNotificationsViewModel
    let canvasWidth: CGFloat

    // Background="#361637", the Tier7 purple, under the toast art.
    private static let background = Color(red: 0x36 / 255, green: 0x16 / 255, blue: 0x37 / 255)

    // Ships loose in Resources/Battlegrounds rather than in the asset catalog.
    private static let artwork: NSImage? = {
        guard let rp = Bundle.main.resourcePath else {
            return nil
        }
        return NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/bgs_toast_background.jpg")
    }()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear

            if viewModel.heroPickIsShown {
                panel(title: String.localizedString("Toast_Battlegrounds_Compare_Heroes", comment: ""),
                      action: viewModel.openHeroPicker)
                    .padding(.bottom, 0.04 * 1080)
                    .transition(.move(edge: .bottom))
            }

            if viewModel.timewarpIsShown {
                panel(title: String.localizedString("Toast_Battlegrounds_Timewarp", comment: ""),
                      action: viewModel.openTimewarp)
                    .padding(.bottom, 0.05 * 1080)
                    .transition(.move(edge: .bottom))
            }
        }
        .frame(width: canvasWidth, height: 1080)
    }

    private func panel(title: String, action: @escaping () -> Void) -> some View {
        OverlayToastPanel(
            title: title,
            subtitle: String.localizedString("Toast_Battlegrounds_HSReplaynet", comment: ""),
            background: Self.background,
            artwork: Self.artwork,
            normalArtworkOpacity: 0.5,
            hoverArtworkOpacity: 0.8,
            showsHandCursor: true,
            action: action)
    }
}
