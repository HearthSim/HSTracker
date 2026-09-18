//
//  TrackerCounterViews.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit
import SwiftUI

/// The theme-framed rows of a deck tracker: the card counter, the draw chances,
/// the win/loss record and the graveyard counter.
///
/// These are the SwiftUI replacements for the `TextFrame` subclasses, which drew
/// the overlay theme's own PNG and then its numbers over it, every rect authored
/// against a 217-wide box and divided by the card size's ratio as it drew. As
/// with `CardTileView`, the rects are carried over as they are and the size is
/// applied once, as a scale on the finished row.
@available(macOS 10.15, *)
struct TrackerFrameView<Content: View>: View {
    /// The theme PNG behind the numbers.
    let background: String
    /// The authored box - 217x40 for most, 217x71 for the opponent's chances.
    let box: CGSize
    /// The row's on-screen height, which the authored box scales to.
    let height: CGFloat
    @ViewBuilder let content: () -> Content

    /// See `OverlayThemeObserver`: the frame's PNG is picked by the theme, which
    /// is not one of this view's own values, so without observing the change
    /// these rows keep the old theme's frame until their numbers happen to move.
    @ObservedObject private var themeObserver = OverlayThemeObserver.shared

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            if let image = OverlayThemeImage.named(background, in: themeObserver.name) {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: box.width, height: box.height)
            }
            content()
        }
        .frame(width: box.width, height: box.height, alignment: .topLeading)
        .scaleEffect(height / box.height, anchor: .topLeading)
        .frame(width: box.width * height / box.height, height: height, alignment: .topLeading)
    }

}

/// The overlay theme's own PNGs - `TextFrame.add(image:rect:)`, which falls back
/// to the default theme for anything the chosen one does not ship.
enum OverlayThemeImage {
    static func named(_ filename: String, in theme: String = Settings.theme) -> NSImage? {
        let key = "\(theme)/\(filename)"
        if let cached = cache.withLock({ $0[key] }) { return cached }
        var image: NSImage?
        if let resourcePath = Bundle.main.resourcePath {
            image = NSImage(contentsOfFile: "\(resourcePath)/Resources/Themes/Overlay/\(key)")
                ?? NSImage(contentsOfFile: "\(resourcePath)/Resources/Themes/Overlay/default/\(filename)")
        }
        cache.withLock { $0[key] = image }
        return image
    }

    private static let cache = UnfairLockBox([String: NSImage?]())
}

/// One number over a theme frame - `TextFrame.add(string:rect:alignment:)`, which
/// draws ChunkFive at 18 with a black stroke.
@available(macOS 10.15, *)
struct TrackerFrameText: View {
    let text: String
    /// The authored rect, in the frame's bottom-left origin coordinates.
    let rect: CGRect
    /// The authored box's height, which those coordinates are against.
    let boxHeight: CGFloat
    var alignment: TextAlignment = .leading

    static let fontSize: CGFloat = 18

    var body: some View {
        Text(verbatim: text)
            .font(CardTileTheme.font(CardTileTheme.numbersFontName, size: Self.fontSize))
            .lineLimit(1)
            .minimumScaleFactor(0.3)
            .frame(width: rect.width, alignment: alignment == .center ? .center : .leading)
            .outlinedText(.white, width: CardTileTheme.outlineWidth)
            .fixedSize()
            // TextFrame draws with NSAttributedString.draw(in:), which lays the
            // text out from the *top* of the rect downward - not CardBar's
            // String.draw(with:options:), which sits the glyphs on the rect's
            // origin. So the box's top edge is what positions these, and the two
            // families of row need different rules despite both authoring their
            // rects bottom-left.
            .offset(x: rect.minX, y: boxHeight - rect.maxY)
    }
}

/// `CardCounter`: how many cards are in hand and how many are left in the deck.
@available(macOS 10.15, *)
struct TrackerCardCounterView: View {
    let handCount: Int
    let deckCount: Int
    let height: CGFloat

    var body: some View {
        TrackerFrameView(background: "card-counter-frame.png",
                         box: CGSize(width: 217, height: 40), height: height) {
            TrackerFrameText(text: "\(handCount)", rect: CGRect(x: 60, y: 1, width: 68, height: 25), boxHeight: 40)
            TrackerFrameText(text: "\(deckCount)", rect: CGRect(x: 154, y: 1, width: 68, height: 25), boxHeight: 40)
        }
    }
}

/// `PlayerDrawChance`: the odds of drawing a given one-of or two-of next turn.
@available(macOS 10.15, *)
struct TrackerPlayerDrawChanceView: View {
    let drawChance1: Double
    let drawChance2: Double
    let height: CGFloat

    var body: some View {
        TrackerFrameView(background: "player-chance-frame.png",
                         box: CGSize(width: 217, height: 40), height: height) {
            TrackerFrameText(text: TrackerFrameFormat.percent(drawChance1),
                             rect: CGRect(x: 70, y: 1, width: 68, height: 25), boxHeight: 40)
            TrackerFrameText(text: TrackerFrameFormat.percent(drawChance2),
                             rect: CGRect(x: 148, y: 1, width: 68, height: 25), boxHeight: 40)
        }
    }
}

/// `OpponentDrawChance`: the same, plus the odds they are already holding it.
@available(macOS 10.15, *)
struct TrackerOpponentDrawChanceView: View {
    let drawChance1: Double
    let drawChance2: Double
    let handChance1: Double
    let handChance2: Double
    let height: CGFloat

    var body: some View {
        TrackerFrameView(background: "opponent-chance-frame.png",
                         box: CGSize(width: 217, height: 71), height: height) {
            TrackerFrameText(text: TrackerFrameFormat.percent(drawChance1),
                             rect: CGRect(x: 70, y: 32, width: 68, height: 25), boxHeight: 71)
            TrackerFrameText(text: TrackerFrameFormat.percent(drawChance2),
                             rect: CGRect(x: 148, y: 32, width: 68, height: 25), boxHeight: 71)
            TrackerFrameText(text: TrackerFrameFormat.percent(handChance1),
                             rect: CGRect(x: 70, y: 1, width: 68, height: 25), boxHeight: 71)
            TrackerFrameText(text: TrackerFrameFormat.percent(handChance2),
                             rect: CGRect(x: 148, y: 1, width: 68, height: 25), boxHeight: 71)
        }
    }
}

/// `StringTracker`: the deck's win/loss record.
@available(macOS 10.15, *)
struct TrackerRecordView: View {
    let message: String
    let height: CGFloat

    var body: some View {
        TrackerFrameView(background: "text-frame.png",
                         box: CGSize(width: 217, height: 40), height: height) {
            TrackerFrameText(text: message,
                             rect: CGRect(x: 10, y: 1, width: 217 - 20, height: 25),
                             boxHeight: 40, alignment: .center)
        }
    }
}

/// `GraveyardCounter`: how many minions have died, and how many were murlocs.
@available(macOS 10.15, *)
struct TrackerGraveyardCounterView: View {
    let minions: Int
    let murlocs: Int
    let height: CGFloat

    var body: some View {
        TrackerFrameView(background: "graveyard-frame.png",
                         box: CGSize(width: 217, height: 40), height: height) {
            TrackerFrameText(text: "\(minions)", rect: CGRect(x: 60, y: 1, width: 68, height: 25), boxHeight: 40)
            TrackerFrameText(text: "\(murlocs)", rect: CGRect(x: 158, y: 1, width: 68, height: 25), boxHeight: 40)
        }
    }
}

enum TrackerFrameFormat {
    /// `TextFrame.add(double:rect:)`, which drops the decimals on a whole number.
    static func percent(_ value: Double) -> String {
        value == Double(Int(value)) ? String(format: "%.0f%%", value) : String(format: "%.2f%%", value)
    }
}
