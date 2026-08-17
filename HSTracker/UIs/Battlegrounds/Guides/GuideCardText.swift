//
//  GuideCardText.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// A line of guide body text, split into plain-text runs and card references.
// Mirrors HDT's ReferencedCardRun.ParseCardsFromText, which turns
// `[[Name||dbfId]]` markup embedded in guide copy (comp/hero/quest "how to
// play" text, etc.) into hoverable inline card links.
@available(macOS 10.15, *)
enum GuideTextSegment: Equatable {
    case plain(String)
    case card(name: String, dbfId: Int?)
}

@available(macOS 10.15, *)
enum GuideCardText {
    // Splits on newlines first (each line renders as its own wrapping
    // paragraph) then parses `[[Name||dbfId]]` runs out of each line.
    static func parse(_ text: String?) -> [[GuideTextSegment]] {
        guard let text, !text.isEmpty else { return [] }

        return text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
            .map(parseLine)
    }

    private static func parseLine(_ line: String) -> [GuideTextSegment] {
        var segments: [GuideTextSegment] = []
        var index = line.startIndex

        func appendPlain(_ range: Range<String.Index>) {
            guard !range.isEmpty else { return }
            segments.append(.plain(String(line[range])))
        }

        while index < line.endIndex {
            guard let openRange = line.range(of: "[[", range: index..<line.endIndex) else {
                appendPlain(index..<line.endIndex)
                break
            }

            appendPlain(index..<openRange.lowerBound)
            let contentStart = openRange.upperBound

            guard let closeRange = line.range(of: "]]", range: contentStart..<line.endIndex) else {
                // No closing "]]" - HDT treats the rest of the line
                // (including the unmatched "[[") as plain text.
                appendPlain(openRange.lowerBound..<line.endIndex)
                break
            }

            var separatorRange = line.range(of: "||", range: contentStart..<line.endIndex)
            if let separator = separatorRange, separator.lowerBound > closeRange.lowerBound {
                // A "||" found belongs to a later `[[...]]` run, not this one.
                separatorRange = nil
            }

            let nameEnd = separatorRange?.lowerBound ?? closeRange.lowerBound
            let name = String(line[contentStart..<nameEnd])
            let dbfId = separatorRange.flatMap { Int(line[$0.upperBound..<closeRange.lowerBound]) }

            segments.append(.card(name: name, dbfId: dbfId))
            index = closeRange.upperBound
        }

        return segments
    }

    // Resolves a card segment's display name against the card database,
    // falling back to the literal name between the brackets when the dbfId
    // is missing or unknown - same fallback HDT's ResolveCardNameOrFallback
    // uses. Unlike HDT (which stores every locale's name on one Card object
    // and resolves at render time), HSTracker's card database is already
    // loaded in the current game language, so no explicit locale lookup is
    // needed here.
    static func displayName(for segment: GuideTextSegment) -> String {
        switch segment {
        case .plain(let text):
            return text
        case .card(let name, let dbfId):
            guard let dbfId, let card = Cards.by(dbfId: dbfId, collectible: false) else { return name }
            return card.name
        }
    }
}

// Renders parsed guide text as wrapping paragraphs with card references in
// bold - matches HDT's ReferencedCardRun style (FontWeight="Bold", no color
// change) - and, since GuideFlowParagraph below now makes each card token
// individually hoverable, the same ToolTipService.Placement="Left"/
// CardTooltip binding ReferencedCardRun's style applies.
@available(macOS 10.15, *)
struct GuideText: View {
    let text: String?
    var fontSize: CGFloat = 12
    var color: Color = .white
    // WPF's LineHeight sets an absolute per-line box height, unlike
    // SwiftUI's .lineSpacing() which adds extra space on top of the font's
    // natural leading - pass (HDT's LineHeight - FontSize) here so wrapped
    // paragraphs don't render visibly tighter than HDT's.
    var lineSpacing: CGFloat = 0

    var body: some View {
        let lines = GuideCardText.parse(text)
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, segments in
                GuideFlowParagraph(segments: segments, fontSize: fontSize, color: color, lineSpacing: lineSpacing)
            }
        }
    }
}

@available(macOS 10.15, *)
private struct GuideFlowToken: Identifiable {
    let id: Int
    let text: String
    let isCard: Bool
    let cardId: String?
}

@available(macOS 10.15, *)
private struct GuideFlowWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// A single wrapping paragraph built out of individually-hoverable word
// tokens, so a card-reference run (HDT's ReferencedCardRun, which can be
// mid-sentence, flowing alongside plain text before/after it) can show its
// own CardTooltip on hover while the paragraph as a whole still wraps
// naturally at the container's width - something a single concatenated
// SwiftUI Text can't do, since it has no way to attach interactivity to a
// sub-range. Pre-Layout-protocol (this module's baseline is macOS 10.15,
// Layout needs 13+), so wrapping is hand-rolled: measure each token via
// NSAttributedString sizing, greedily pack into lines for the available
// width, then self-size vertically via mathematical height computation
// (line count × font line height + inter-line spacing) — a GeometryReader-
// based measurement created a self-referential sizing loop that collapsed
// to zero height.
@available(macOS 10.15, *)
struct GuideFlowParagraph: View {
    let segments: [GuideTextSegment]
    var fontSize: CGFloat = 12
    var color: Color = .white
    var lineSpacing: CGFloat = 0
    var alignment: HorizontalAlignment = .leading

    @SwiftUI.State private var containerWidth: CGFloat = 0

    private var nsFont: NSFont { .systemFont(ofSize: fontSize) }
    private var nsFontBold: NSFont { .boldSystemFont(ofSize: fontSize) }
    // `lineSpacing` (HDT's LineHeight - FontSize) is the caller's intended
    // extra space between wrapped lines, but since each line here is built
    // out of separate word Text views in an HStack rather than one wrapping
    // Text, SwiftUI's own .lineSpacing() modifier has nothing to act on -
    // this VStack spacing is the only place that gap can actually be
    // applied, so it takes over that role directly (falling back to a
    // font-relative default when a caller doesn't pass one).
    private var rowSpacing: CGFloat { lineSpacing > 0 ? lineSpacing : max(fontSize * 0.35, 3) }

    private var singleLineHeight: CGFloat {
        let font = nsFont
        return ceil(font.ascender - font.descender + font.leading)
    }

    private var computedHeight: CGFloat {
        guard containerWidth > 0 else { return singleLineHeight }
        let allLines = lines(containerWidth: containerWidth)
        guard !allLines.isEmpty else { return singleLineHeight }
        return CGFloat(allLines.count) * singleLineHeight + CGFloat(max(0, allLines.count - 1)) * rowSpacing
    }

    private var tokens: [GuideFlowToken] {
        var result: [GuideFlowToken] = []
        var nextId = 0
        for segment in segments {
            let name = GuideCardText.displayName(for: segment)
            let cardId: String?
            switch segment {
            case .plain:
                cardId = nil
            case .card(let name, let dbfId):
                if let dbfId = dbfId {
                    cardId = Cards.by(dbfId: dbfId, collectible: false)?.id
                } else {
                    // API omitted the dbfId — try resolving by English name
                    // across all cards (collectible and BG).
                    cardId = Cards.by(englishNameCaseInsensitive: name)?.id
                        ?? Cards.cards.first(where: {
                            $0.enName.caseInsensitiveCompare(name) == .orderedSame
                                || $0.name.caseInsensitiveCompare(name) == .orderedSame
                        })?.id
                }
            }
            let isCard: Bool
            if case .card = segment { isCard = true } else { isCard = false }
            for word in name.split(separator: " ") {
                result.append(GuideFlowToken(id: nextId, text: String(word), isCard: isCard, cardId: cardId))
                nextId += 1
            }
        }
        return result
    }

    private func width(of text: String, bold: Bool) -> CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: bold ? nsFontBold : nsFont]).width)
    }

    private func lines(containerWidth: CGFloat) -> [[GuideFlowToken]] {
        let allTokens = tokens
        guard containerWidth > 0 else { return [allTokens] }
        let spaceWidth = width(of: " ", bold: false)

        var lines: [[GuideFlowToken]] = []
        var current: [GuideFlowToken] = []
        var currentWidth: CGFloat = 0
        for token in allTokens {
            let tokenWidth = width(of: token.text, bold: token.isCard)
            let candidateWidth = current.isEmpty ? tokenWidth : currentWidth + spaceWidth + tokenWidth
            if !current.isEmpty && candidateWidth > containerWidth {
                lines.append(current)
                current = [token]
                currentWidth = tokenWidth
            } else {
                current.append(token)
                currentWidth = candidateWidth
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Invisible zero-height reader just to capture the available
            // width from the parent — the height is computed mathematically
            // from line count × font metrics, breaking the self-referential
            // sizing loop a GeometryReader-based measurement creates.
            GeometryReader { geo in
                Color.clear.preference(key: GuideFlowWidthKey.self, value: geo.size.width)
            }
            .frame(height: 0)

            if containerWidth > 0 {
                content(containerWidth: containerWidth)
            }
        }
        .frame(height: computedHeight)
        .onPreferenceChange(GuideFlowWidthKey.self) { w in
            if abs(w - containerWidth) > 0.5 {
                containerWidth = w
            }
        }
    }

    private func content(containerWidth: CGFloat) -> some View {
        VStack(alignment: alignment, spacing: rowSpacing) {
            ForEach(Array(lines(containerWidth: containerWidth).enumerated()), id: \.offset) { _, line in
                HStack(spacing: 0) {
                    if alignment == .center { Spacer(minLength: 0) }
                    ForEach(Array(line.enumerated()), id: \.element.id) { index, token in
                        if index > 0 {
                            Text(" ").font(.system(size: fontSize))
                        }
                        word(token)
                    }
                    if alignment != .trailing { Spacer(minLength: 0) }
                }
            }
        }
    }

    @ViewBuilder
    private func word(_ token: GuideFlowToken) -> some View {
        let text = Text(token.text)
            .font(.system(size: fontSize, weight: token.isCard ? .bold : .regular))
            .foregroundColor(color)
            .fixedSize()
        if token.isCard {
            text.cardImageTooltip(cardId: token.cardId)
        } else {
            text
        }
    }
}
