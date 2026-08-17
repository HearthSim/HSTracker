//
//  OutlinedText.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mimics HDT's OutlinedTextBlock (a black outline behind the glyph fill),
// used throughout the Battlegrounds Guides ports wherever HDT pairs it with
// the ChunkFive title font. The sibling Arenasmith app does this with
// Canvas + an alphaThreshold/blur filter, but Canvas needs macOS 12 - this
// module's baseline (like the rest of this codebase) is 10.15, so this uses
// the classic 8-direction offset-stack trick instead: paint the outline
// color underneath at 8 pixel offsets around the origin, then the real
// glyph on top.
//
// Takes and applies textColor itself rather than reading whatever
// .foregroundColor() the caller already chained on `content` - SwiftUI
// resolves environment values (which is what .foregroundColor() sets) from
// the innermost modifier outward, so a .foregroundColor() applied by the
// caller *before* .outlinedText() sits closer to the Text leaf than any
// .foregroundColor() this modifier tries to apply afterward, and wins over
// it. Every one of the 8 offset copies below would render in the caller's
// original color instead of the outline color, which is what was producing
// a smeared blur of the fill color instead of a black outline.
@available(macOS 10.15, *)
private struct OutlinedTextModifier: ViewModifier {
    var textColor: Color
    var outlineColor: Color
    var width: CGFloat = 1

    private static let offsets: [CGSize] = [
        CGSize(width: -1, height: -1), CGSize(width: 0, height: -1), CGSize(width: 1, height: -1),
        CGSize(width: -1, height: 0), CGSize(width: 1, height: 0),
        CGSize(width: -1, height: 1), CGSize(width: 0, height: 1), CGSize(width: 1, height: 1)
    ]

    func body(content: Content) -> some View {
        ZStack {
            ForEach(Array(Self.offsets.enumerated()), id: \.offset) { _, offset in
                content
                    .foregroundColor(outlineColor)
                    .offset(x: offset.width * width, y: offset.height * width)
            }
            content
                .foregroundColor(textColor)
        }
    }
}

@available(macOS 10.15, *)
extension View {
    // Do not chain .foregroundColor() before this - it won't take effect
    // (see OutlinedTextModifier's doc comment). Pass the fill color as
    // textColor instead.
    func outlinedText(_ textColor: Color = .white, outlineColor: Color = .black, width: CGFloat = 1) -> some View {
        modifier(OutlinedTextModifier(textColor: textColor, outlineColor: outlineColor, width: width))
    }

    // HDT's ChunkFive title font, already bundled and ATS-registered (see
    // Info.plist's ATSApplicationFontsPath) - the AppKit side already uses
    // it via NSFont(name: "ChunkFive", ...).
    func chunkFive(size: CGFloat) -> some View {
        font(.custom("ChunkFive", size: size))
    }
}
