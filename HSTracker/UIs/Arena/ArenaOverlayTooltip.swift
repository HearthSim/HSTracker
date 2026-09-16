//
//  ArenaOverlayTooltip.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit
import SwiftUI

/// One of the draft overlay's hover-visible regions.
///
/// HDT marks these `OverlayExtensions.IsOverlayHoverVisible`, which is not the
/// same as hit-test visible: the region reacts to the cursor without taking the
/// click, so the player can still click through to the card underneath. There is
/// no AppKit equivalent, so as with the bottom panel the frames are reported up to
/// `RootOverlayWindow`, which samples the cursor against them.
@available(macOS 10.15, *)
enum ArenaTooltipTarget: Hashable {
    case relatedCards(Int)
    case additionalInfo(Int)
    case improvements(Int)
    /// A deck-rail marker, carrying the choice the row is reacting to so hovering
    /// it can light that choice's improvements badge.
    case deckTile(cardId: String, choiceIndex: Int?)
}

/// A run of tooltip text. HDT builds the deck-rail tooltip out of WPF `Inline`s so
/// the two card names come out bold; this is the same idea, flattened.
@available(macOS 10.15, *)
struct ArenaTooltipRun: Equatable {
    var text = ""
    var bold = false
    var isLineBreak = false

    static let lineBreak = ArenaTooltipRun(isLineBreak: true)

    /// Splits a positional format - `ArenaPick_SynergyImprove`, "%1$@ improves
    /// %2$@" - around its two arguments, emitting them bold. The specifiers are
    /// positional, so a translation is free to put the second name first.
    static func runs(_ format: String, first: String, second: String) -> [ArenaTooltipRun] {
        var result = [ArenaTooltipRun]()
        var rest = Substring(format)
        while true {
            let firstRange = rest.range(of: "%1$@")
            let secondRange = rest.range(of: "%2$@")
            let next: (Range<Substring.Index>, String)?
            switch (firstRange, secondRange) {
            case let (lhs?, rhs?): next = lhs.lowerBound < rhs.lowerBound ? (lhs, first) : (rhs, second)
            case let (lhs?, nil): next = (lhs, first)
            case let (nil, rhs?): next = (rhs, second)
            case (nil, nil): next = nil
            }
            guard let (range, value) = next else { break }
            if range.lowerBound > rest.startIndex {
                result.append(ArenaTooltipRun(text: String(rest[rest.startIndex..<range.lowerBound])))
            }
            result.append(ArenaTooltipRun(text: value, bold: true))
            rest = rest[range.upperBound...]
        }
        if !rest.isEmpty {
            result.append(ArenaTooltipRun(text: String(rest)))
        }
        return result
    }
}

/// A hover-visible region, reported upward with everything needed to hit-test it
/// and to draw its bubble somewhere else.
///
/// The bubble is drawn by `ArenaPickHelperView` rather than as an overlay on the
/// region itself: the badge row and the deck rail are both clipped, and where WPF's
/// ToolTip is a popup in its own window that escapes that clip, a SwiftUI overlay
/// would be cut off by it.
@available(macOS 10.15, *)
struct ArenaTooltipRegion: Equatable {
    let target: ArenaTooltipTarget
    /// Canvas pixels, for `RootOverlayWindow` to sample the cursor against.
    let frame: CGRect
    /// The same region in the helper's own reference space, to anchor the bubble.
    let anchor: CGRect
    let runs: [ArenaTooltipRun]
    /// HDT's `ToolTipService.IsEnabled`. The region still reports itself when this
    /// is false, because hovering it may do something other than show a tooltip.
    let isEnabled: Bool
}

@available(macOS 10.15, *)
extension CoordinateSpace {
    /// Declared on `ArenaPickHelperView`'s root, so a region can report where it
    /// sits in the 1440x1080 space the bubbles are laid out in.
    static let arenaPickHelper = CoordinateSpace.named("arenaPickHelper")
}

@available(macOS 10.15, *)
struct ArenaTooltipRegionKey: PreferenceKey {
    static var defaultValue: [ArenaTooltipRegion] = []
    static func reduce(value: inout [ArenaTooltipRegion], nextValue: () -> [ArenaTooltipRegion]) {
        value += nextValue()
    }
}

/// HDT's tooltip template: a near-black rounded box, 8pt padding, hairline border,
/// white text, wrapping at 300.
@available(macOS 10.15, *)
struct ArenaTooltipBubble: View {
    let runs: [ArenaTooltipRun]

    /// HDT's `MaxWidth="300"` on the border, less its 8pt padding either side.
    private static let maxTextWidth: CGFloat = 284

    var body: some View {
        text
            .font(.system(size: 13))
            .foregroundColor(.white)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: measuredWidth, alignment: .leading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "#23272A"))
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color(hex: "#141617"), lineWidth: 1))
            )
    }

    /// WPF's border hugs content narrower than its `MaxWidth`, where a SwiftUI
    /// `maxWidth` frame fills whatever it is offered - so the natural width is
    /// measured and clamped, which is what `MaxWidth` amounts to.
    private var measuredWidth: CGFloat {
        let attributed = NSMutableAttributedString()
        for run in runs {
            if run.isLineBreak {
                attributed.append(NSAttributedString(string: "\n"))
                continue
            }
            let font = run.bold ? NSFont.boldSystemFont(ofSize: 13) : NSFont.systemFont(ofSize: 13)
            attributed.append(NSAttributedString(string: run.text, attributes: [.font: font]))
        }
        let unbounded = CGSize(width: CGFloat.greatestFiniteMagnitude,
                               height: CGFloat.greatestFiniteMagnitude)
        let bounds = attributed.boundingRect(with: unbounded, options: [.usesLineFragmentOrigin])
        // The extra point absorbs the rounding difference between AppKit's
        // measurement and SwiftUI's, which would otherwise wrap the last word.
        return min(ceil(bounds.width) + 1, Self.maxTextWidth)
    }

    /// Concatenated rather than laid out as separate views so the bold names wrap
    /// inside the same paragraph, as WPF's inlines do.
    private var text: Text {
        runs.reduce(Text(verbatim: "")) { accumulated, run in
            if run.isLineBreak { return accumulated + Text(verbatim: "\n") }
            return accumulated + (run.bold
                ? Text(verbatim: run.text).bold()
                : Text(verbatim: run.text))
        }
    }
}

@available(macOS 10.15, *)
private struct ArenaTooltipModifier: ViewModifier {
    let target: ArenaTooltipTarget
    let runs: [ArenaTooltipRun]
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ArenaTooltipRegionKey.self,
                    value: [ArenaTooltipRegion(target: target,
                                               frame: proxy.frame(in: .rootOverlayCanvas),
                                               anchor: proxy.frame(in: .arenaPickHelper),
                                               runs: runs,
                                               isEnabled: isEnabled)])
            }
        )
    }
}

@available(macOS 10.15, *)
extension View {
    func arenaOverlayTooltip(_ target: ArenaTooltipTarget,
                             runs: [ArenaTooltipRun],
                             isEnabled: Bool) -> some View {
        modifier(ArenaTooltipModifier(target: target, runs: runs, isEnabled: isEnabled))
    }
}
