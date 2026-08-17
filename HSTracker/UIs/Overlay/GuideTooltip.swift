//
//  GuideTooltip.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's ToolTip template (OutlinedTextBlock title, bold/13pt with a
// 6pt bottom margin; MultiLineTextBlock body, regular/12pt with an 8pt bottom
// margin when a footer follows; OutlinedTextBlock footer lines, bold/12pt,
// flush against each other with no margin).
//
// Originally built for the Mulligan V2 overlay (still its main consumer) but
// generic to any RootOverlayView content - Battlegrounds Guides reuses it for
// its own small text tooltips (e.g. difficulty/tier explanations). Not a fit
// for card-preview tooltips (a full card image, like HDT's CardTooltip) -
// those are a different visual and aren't built yet.
@available(macOS 10.15, *)
struct GuideTooltipContent: Equatable {
    var title: String?
    var body: String?
    var footer: [String] = []
}

// RootOverlayWindow is a non-activating floating panel that never becomes key
// (so it doesn't steal focus from Hearthstone) - AppKit's native tooltip
// mechanism (NSView.toolTip) needs the window to be key to ever display, so
// it never fires here, hence rolling our own via .onHover.
//
// The bubble renders in place, which means it sits inside the RootOverlayView
// child's own scaled subtree and scales with the rest of the overlay -
// matching HDT, which deliberately applies the same ScaleTransform to its
// tooltips via the LayoutTransform setter in the consuming XAML.
@available(macOS 10.15, *)
private struct GuideTooltipModifier: ViewModifier {
    let content: GuideTooltipContent?

    @SwiftUI.State private var isHovering = false

    // HDT: Placement="Top" with VerticalOffset="-4", plus the template Border's
    // own 10pt bottom margin.
    private static let gap: CGFloat = 14

    func body(content viewContent: Content) -> some View {
        viewContent
            .onHover { hovering in
                guard content != nil else { return }
                isHovering = hovering
            }
            .overlay(bubble, alignment: .top)
    }

    @ViewBuilder
    private var bubble: some View {
        if isHovering, let content {
            // Zero-height marker pinned to the anchor's top edge, with the
            // bubble bottom-aligned onto it so it grows *upward* (HDT's
            // Placement="Top") without this view needing to know the bubble's
            // height, and horizontally centered on the anchor (HDT's
            // CenteredTooltipConverter).
            Color.clear
                .frame(height: 0)
                .overlay(GuideTooltipBubble(content: content), alignment: .bottom)
                .offset(y: -Self.gap)
                .allowsHitTesting(false)
        }
    }
}

@available(macOS 10.15, *)
private struct GuideTooltipBubble: View {
    let content: GuideTooltipContent

    // HDT's ConstructedTooltipStyle caps its Border at MaxWidth=230 (inclusive
    // of the 8pt horizontal padding) and lets it hug narrower content; this
    // pins the width at that cap, which every tooltip here wraps to anyway.
    private static let textWidth: CGFloat = 214

    var body: some View {
        text
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            // fixedSize only vertically, against a definite width: a Text's
            // *ideal* size is a single unwrapped line, so fixing it
            // horizontally too would size the box to one line's height while
            // the text itself wraps to several - and .cornerRadius() below
            // clips to that box, which is what was cutting off lines.
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: Self.textWidth, alignment: .leading)
            .padding(EdgeInsets(top: 5, leading: 8, bottom: 6, trailing: 8))
            .background(Color(red: 0x14 / 255, green: 0x16 / 255, blue: 0x17 / 255))
            .cornerRadius(2)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(white: 0x33 / 255.0).opacity(0.8), lineWidth: 1))
    }

    // Built as a single concatenated Text (SwiftUI's `+` operator preserves
    // each segment's own font/weight) rather than a VStack of separate Text
    // children, whose height computation proved unreliable under fixedSize.
    private var text: Text {
        var result: Text?
        func append(_ next: Text) {
            result = result.map { $0 + next } ?? next
        }

        if let title = content.title {
            append(Text(title).font(.system(size: 13, weight: .bold)))
        }
        if let body = content.body {
            if result != nil { append(Text("\n\n")) }
            append(Text(body).font(.system(size: 12, weight: .regular)))
        }
        if !content.footer.isEmpty {
            if result != nil { append(Text("\n\n")) }
            for (index, line) in content.footer.enumerated() {
                if index > 0 { append(Text("\n")) }
                append(Text(line).font(.system(size: 12, weight: .bold)))
            }
        }
        return result ?? Text("")
    }
}

@available(macOS 10.15, *)
extension View {
    func guideTooltip(_ content: GuideTooltipContent?) -> some View {
        modifier(GuideTooltipModifier(content: content))
    }

    // Convenience for tooltips with no title/footer, just a body line (e.g.
    // the low-data warning triangle).
    func guideTooltip(_ text: String?) -> some View {
        modifier(GuideTooltipModifier(content: text.map { GuideTooltipContent(body: $0) }))
    }
}
