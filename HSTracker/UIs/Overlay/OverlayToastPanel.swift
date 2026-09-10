//
//  OverlayToastPanel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// The chrome HDT's overlay toasts all share - BattlegroundsHeroPanel.xaml,
// BattlegroundsTimewarpPanel.xaml and MulliganPanel.xaml are the same control
// three times over, differing only in their tint, their background art and
// whether the art brightens under the cursor:
//
//   Border BorderThickness="1" BorderBrush="White"
//     Grid
//       IgnoreSizeDecorator > Image Stretch="UniformToFill"
//       DockPanel Margin="10" VerticalAlignment="Center"
//         Image HsReplayIconWhite 28x28, docked left
//         TextBlock TextAlignment="Center" Margin="20,0"
//           Run FontWeight="SemiBold" FontSize="17" / LineBreak / Run FontSize="12"
//
// with Margin="5" and MinHeight="60" on the control itself.
@available(macOS 10.15, *)
struct OverlayToastPanel: View {
    let title: String
    let subtitle: String
    // The UserControl's own Background, behind the art.
    let background: Color
    let artwork: NSImage?
    // The two storyboards: the art crossfades between these over 0.2s. Equal
    // values mean the panel doesn't react to the cursor at all, which is what
    // the mulligan toast's grey "no data" art does.
    let normalArtworkOpacity: Double
    let hoverArtworkOpacity: Double
    // Cursor="Hand" - true for every toast that has somewhere to go.
    let showsHandCursor: Bool
    let action: () -> Void

    @SwiftUI.State private var isHovered = false

    var body: some View {
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
                Text(subtitle)
                    .font(.system(size: 12))
            }
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .fixedSize()
            .padding(.horizontal, 20)
        }
        .padding(10)
        .frame(minHeight: 60)
        .background(artworkLayer)
        .overlay(Rectangle().stroke(Color.white, lineWidth: 1))
        .padding(5)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
            if showsHandCursor {
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                       value: [proxy.frame(in: .rootOverlayCanvas)])
            }
        )
    }

    private var artworkLayer: some View {
        // Measured rather than laid out freely: an aspect-filled image is
        // larger than the box it fills, and it has to be pinned to the card's
        // own size before it is clipped - which is what HDT's
        // IgnoreSizeDecorator does for it.
        GeometryReader { proxy in
            ZStack {
                background
                if let artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .opacity(isHovered ? hoverArtworkOpacity : normalArtworkOpacity)
                }
            }
        }
    }

    // HDT's HsReplayIconWhite, which every one of these toasts carries. It
    // ships loose in Resources/Battlegrounds rather than in the asset catalog,
    // as the tier badges do.
    static let icon: NSImage? = {
        guard let rp = Bundle.main.resourcePath else {
            return nil
        }
        return NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/icon_white.png")
    }()
}
