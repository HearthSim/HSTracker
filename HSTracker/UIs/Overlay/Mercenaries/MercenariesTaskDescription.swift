//
//  MercenariesTaskDescription.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Task descriptions come out of the mirror as Hearthstone's own card-text
// markup - `<b>`/`<i>` runs, `<br>` breaks and HTML entities - which HDT's
// plain `<TextBlock Text="{Binding Description}"/>` shows verbatim, tags and
// all. The AppKit row did not: it ran the string through
// String.htmlToAttributedString and drew the result, so the markup rendered.
// That behaviour is kept here rather than regressed to HDT's, and this is the
// SwiftUI-side replacement for it: NSAttributedString can't be handed to a
// SwiftUI Text before macOS 12, so the same small subset is parsed into styled
// runs and concatenated instead.
@available(macOS 10.15, *)
enum MercenariesTaskDescription {
    struct Run {
        var text: String
        var bold: Bool
        var italic: Bool
    }

    static func text(_ html: String, size: CGFloat) -> Text {
        runs(html).reduce(Text(verbatim: "")) { result, run in
            var piece = Text(verbatim: run.text)
                .font(.system(size: size, weight: run.bold ? .bold : .regular))
            if run.italic {
                piece = piece.italic()
            }
            return result + piece
        }
    }

    // Splits on the tags that carry styling, drops every other tag, and decodes
    // the handful of entities Hearthstone's strings actually use. Anything that
    // doesn't parse as a tag is left in place as literal text, which is what an
    // HTML parser would do with a stray "<".
    static func runs(_ html: String) -> [Run] {
        var result: [Run] = []
        var bold = 0
        var italic = 0
        var current = ""
        var index = html.startIndex

        func flush() {
            guard !current.isEmpty else { return }
            result.append(Run(text: decodeEntities(current), bold: bold > 0, italic: italic > 0))
            current = ""
        }

        while index < html.endIndex {
            guard html[index] == "<",
                  let close = html.range(of: ">", range: index..<html.endIndex) else {
                current.append(html[index])
                index = html.index(after: index)
                continue
            }
            let inner = html[html.index(after: index)..<close.lowerBound]
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
            switch inner {
            case "b", "strong": flush(); bold += 1
            case "/b", "/strong": flush(); bold = max(0, bold - 1)
            case "i", "em": flush(); italic += 1
            case "/i", "/em": flush(); italic = max(0, italic - 1)
            case "br", "br/", "br /": current.append("\n")
            default: break // any other tag is dropped, as the AppKit path did
            }
            index = close.upperBound
        }
        flush()
        return result
    }

    private static let entities: [(String, String)] = [
        ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""), ("&apos;", "'"),
        ("&#39;", "'"), ("&nbsp;", "\u{00a0}"),
        // Last: decoding it earlier would let "&amp;lt;" turn into "<".
        ("&amp;", "&")
    ]

    private static func decodeEntities(_ text: String) -> String {
        entities.reduce(text) { $0.replacingOccurrences(of: $1.0, with: $1.1) }
    }
}
