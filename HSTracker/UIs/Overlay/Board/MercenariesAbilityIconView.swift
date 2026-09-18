//
//  MercenariesAbilityIconView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/16/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's MercenariesAbilityView: one ability disc under (or over) a Mercenaries
// board minion. Authored on the same 256x256 Canvas the XAML uses and scaled to
// the caller's size, which is what its Viewbox does.
//
// Replaces MercenaryAbilityView, an NSImageView that drew the same disc with
// Core Graphics. That version had drifted from the XAML - it used the art crop
// rather than the full card render and centred the portrait circle differently
// - so this is transcribed from MercenariesAbilityView.xaml rather than from
// the drawing code it replaces.
struct MercenariesAbilityIconView: View {
    let ability: MercenariesAbilityModel
    // The Viewbox's Width/Height, which OverlayWindow sets to AbilitySize.
    let size: CGFloat

    // The Canvas everything below is positioned on.
    private static let canvasSide: CGFloat = 256

    // The full card render the portrait is cut out of: Width="415" with WPF's
    // default Uniform stretch, over a 256x388 source.
    private static let portraitWidth: CGFloat = 415
    private static let portraitAspect: CGFloat = 388.0 / 256.0
    private static let portraitOrigin = CGPoint(x: -81, y: -47)
    // Image.Clip = EllipseGeometry Center="221,178" RadiusX="100" RadiusY="100",
    // in the portrait's own space.
    private static let portraitClip = CGRect(x: 121, y: 78, width: 200, height: 200)

    // Ellipse Width="270" Height="270" Fill="#00FF00" Canvas.Top="-10" Canvas.Left="-8".
    private static let activeIndicatorSize: CGFloat = 270
    private static let activeIndicatorOrigin = CGPoint(x: -8, y: -10)

    // Image Width="120" Canvas.Top="-21" Canvas.Right="-40" with a 20 degree
    // RotateTransform. Canvas.Right is measured from the canvas's right edge,
    // so a negative value pushes it past the edge.
    private static let cooldownIconSize: CGFloat = 120
    private static let cooldownIconOrigin = CGPoint(x: 256 + 40 - 120, y: -21)
    private static let cooldownIconAngle: Double = 20

    // Image Width="190" Canvas.Left="40" Canvas.Top="-82". The checkmark is
    // 97x70, and Uniform gives it its height from that.
    private static let checkmarkWidth: CGFloat = 190
    private static let checkmarkOrigin = CGPoint(x: 40, y: -82)

    var body: some View {
        ZStack(alignment: .topLeading) {
            // The Canvas itself. Everything is placed against its top-left, and
            // several children deliberately hang outside it - the Viewbox scales
            // the Canvas's own 256x256, not the union of its children.
            Color.clear.frame(width: Self.canvasSide, height: Self.canvasSide)

            if ability.active {
                Ellipse()
                    .fill(Color(red: 0, green: 1, blue: 0))
                    .frame(width: Self.activeIndicatorSize, height: Self.activeIndicatorSize)
                    .offset(x: Self.activeIndicatorOrigin.x, y: Self.activeIndicatorOrigin.y)
            }

            MercenariesAbilityPortrait(cardId: ability.cardId,
                                       width: Self.portraitWidth,
                                       height: Self.portraitWidth * Self.portraitAspect,
                                       clip: Self.portraitClip)
                .offset(x: Self.portraitOrigin.x, y: Self.portraitOrigin.y)

            Image("merc_ability")
                .resizable()
                .interpolation(.high)
                .frame(width: Self.canvasSide, height: Self.canvasSide)

            if ability.cooldownShading {
                Ellipse()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: Self.canvasSide, height: Self.canvasSide)
            }

            if ability.cooldown > 0 {
                Image("merc_hourglass")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Self.cooldownIconSize, height: Self.cooldownIconSize)
                    .rotationEffect(.degrees(Self.cooldownIconAngle))
                    .offset(x: Self.cooldownIconOrigin.x, y: Self.cooldownIconOrigin.y)
            }

            if ability.active {
                Image("checkmark")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Self.checkmarkWidth, height: Self.checkmarkWidth * 70 / 97)
                    .offset(x: Self.checkmarkOrigin.x, y: Self.checkmarkOrigin.y)
            }

            if let cooldownText = ability.cooldownText {
                // Canvas.Right="30" Canvas.Top="-9", Width="100" Height="130",
                // FontSize="100", StrokeWidth="20".
                block(cooldownText, fontSize: 100, box: CGSize(width: 100, height: 130),
                      stroke: 20, fill: .white)
                    .offset(x: 256 - 30 - 100, y: -9)
            }

            // Grid Canvas.Left="40" Canvas.Top="150" holding the speed and, over
            // it, the same glyph in 50% black while the ability is cooling down.
            ZStack(alignment: .topLeading) {
                block(ability.speedText, fontSize: 120, box: CGSize(width: 150, height: 150),
                      stroke: 20, fill: ability.speedColor)
                if ability.cooldownShading {
                    block(ability.speedText, fontSize: 120, box: CGSize(width: 150, height: 150),
                          stroke: 20, fill: .black)
                        .opacity(0.5)
                }
            }
            .offset(x: 40, y: 150)

            if ability.speedUncertain {
                ZStack(alignment: .topLeading) {
                    block("?", fontSize: 90, box: CGSize(width: 120, height: 120),
                          stroke: 10, fill: .white)
                    if ability.cooldownShading {
                        block("?", fontSize: 90, box: CGSize(width: 120, height: 120),
                              stroke: 10, fill: .black)
                            .opacity(0.5)
                    }
                }
                .offset(x: 160, y: 160)
            }
        }
        .frame(width: Self.canvasSide, height: Self.canvasSide, alignment: .topLeading)
        .scaleEffect(size / Self.canvasSide, anchor: .topLeading)
        .frame(width: size, height: size, alignment: .topLeading)
    }

    // A HearthstoneTextBlock from the Canvas's own style: Chunkfive, bold,
    // centred, with Width and Height set - which is the branch of
    // OutlinedTextBlock.OnRender that centres the line in the block's height
    // before dropping it by a twentieth of a line.
    //
    // StrokeWidth is a WPF pen centred on the glyph outline, so it reaches half
    // its width outside the glyph - which is what the offset stack behind
    // .outlinedText() reproduces.
    private func block(_ text: String, fontSize: CGFloat, box: CGSize,
                       stroke: CGFloat, fill: Color) -> some View {
        Text(verbatim: text)
            .chunkFive(size: fontSize)
            .outlinedText(fill, outlineColor: .black, width: stroke / 2)
            .fixedSize()
            .frame(width: box.width, height: box.height)
            .offset(y: fontSize * Self.lineHeightFactor * 0.05)
    }

    // Chunkfive's line height as a multiple of its point size, for the 5% drop
    // OutlinedTextBlock applies. Measured once rather than per block, since the
    // ratio does not depend on the size.
    private static let lineHeightFactor: CGFloat = {
        guard let font = NSFont(name: "ChunkFive", size: 100) else { return 1 }
        return (font.ascender - font.descender + font.leading) / 100
    }()
}

// The ability's card art, clipped to the circle the frame leaves open. HDT uses
// the FullImage asset - the whole rendered card - and cuts the portrait out of
// it, which is why the clip sits off-centre in the image.
private struct MercenariesAbilityPortrait: View {
    let cardId: String?
    let width: CGFloat
    let height: CGFloat
    let clip: CGRect

    @SwiftUI.State private var image: NSImage?

    var body: some View {
        // Color.clear rather than a bare `if`: .onAppear does not fire on a view
        // that renders empty, and until the art arrives that is what this is.
        ZStack {
            Color.clear
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            }
        }
        .frame(width: width, height: height)
        .clipShape(Ellipse().path(in: clip))
        .onAppear(perform: load)
    }

    private func load() {
        guard let cardId else { return }
        if let cached = ImageUtils.cachedCardArt(cardId: cardId) {
            image = cached
            return
        }
        ImageUtils.cardArt(for: cardId) { img in
            DispatchQueue.main.async {
                self.image = img
            }
        }
    }
}
