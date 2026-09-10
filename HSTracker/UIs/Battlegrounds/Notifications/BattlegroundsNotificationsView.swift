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
// toast art behind it, offering to open the matching HSReplay.net page.
//
// Both hang off the canvas's right edge, where their OverlayElementBehaviors put
// them (GetRight = 0, AnchorSide = Bottom, GetScaling = AutoScaling), the hero
// one 4% of the canvas height off the bottom and the Timewarp one 5%.
@available(macOS 10.15, *)
struct BattlegroundsNotificationsView: View {
    @ObservedObject var viewModel: BattlegroundsNotificationsViewModel
    let canvasWidth: CGFloat

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear

            if viewModel.heroPickIsShown {
                BattlegroundsNotificationPanel(
                    title: String.localizedString("Toast_Battlegrounds_Compare_Heroes", comment: ""),
                    action: viewModel.openHeroPicker)
                    .padding(.bottom, 0.04 * 1080)
                    .transition(.move(edge: .bottom))
            }

            if viewModel.timewarpIsShown {
                BattlegroundsNotificationPanel(
                    title: String.localizedString("Toast_Battlegrounds_Timewarp", comment: ""),
                    action: viewModel.openTimewarp)
                    .padding(.bottom, 0.05 * 1080)
                    .transition(.move(edge: .bottom))
            }
        }
        .frame(width: canvasWidth, height: 1080)
    }
}

@available(macOS 10.15, *)
private struct BattlegroundsNotificationPanel: View {
    let title: String
    let action: () -> Void

    @SwiftUI.State private var isHovered = false

    // Background="#361637", the Tier7 purple, under the toast art.
    private static let background = Color(red: 0x36 / 255, green: 0x16 / 255, blue: 0x37 / 255)

    var body: some View {
        // DockPanel Margin="10" VerticalAlignment="Center", with the icon
        // docked left and the text filling what is left of it.
        HStack(spacing: 0) {
            if let icon = Self.icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 28, height: 28)
            }
            // Two Runs in one TextBlock: the call to action over the site it
            // opens, centred, with Margin="20,0" around them.
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                Text(String.localizedString("Toast_Battlegrounds_HSReplaynet", comment: ""))
                    .font(.system(size: 12))
            }
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .fixedSize()
            .padding(.horizontal, 20)
        }
        .padding(10)
        .frame(minHeight: 60)
        .background(artwork)
        // BorderThickness="1" BorderBrush="White".
        .overlay(Rectangle().stroke(Color.white, lineWidth: 1))
        // Margin="5" on the control itself.
        .padding(5)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .onHover { hovering in
            // The two storyboards: the art goes from 0.5 to 0.8 over 0.2s.
            withAnimation(.easeInOut(duration: BattlegroundsNotificationsViewModel.slideDuration)) {
                isHovered = hovering
            }
            // Cursor="Hand".
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                       value: [proxy.frame(in: .rootOverlayCanvas)])
            }
        )
    }

    private var artwork: some View {
        // Measured rather than laid out freely: an aspect-filled image is
        // larger than the box it fills, and it has to be pinned to the card's
        // own size before it is clipped - which is what HDT's
        // IgnoreSizeDecorator does for it.
        GeometryReader { proxy in
            ZStack {
                Self.background
                if let image = Self.backgroundImage {
                    // Stretch="UniformToFill".
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .opacity(isHovered ? 0.8 : 0.5)
                }
            }
        }
    }

    // Both images ship loose in Resources/Battlegrounds rather than in the asset
    // catalog, as the tier badges do.
    private static let backgroundImage = loadImage("bgs_toast_background.jpg")
    private static let icon = loadImage("icon_white.png")

    private static func loadImage(_ name: String) -> NSImage? {
        guard let rp = Bundle.main.resourcePath else {
            return nil
        }
        return NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/\(name)")
    }
}
