//
//  ArenaBottomPanelView.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

/// The panel along the bottom of the draft screen: the cards an offered pick
/// generates (or a class's signature cards, when hovering a hero), plus any
/// advisory messages. Port of the bottom half of HDT's `ArenaPickHelper.xaml`.
@available(macOS 10.15, *)
struct ArenaBottomPanelView: View {
    @ObservedObject var viewModel: ArenaPickHelperViewModel

    /// HDT: Margin="60,0,60,99", VerticalAlignment=Bottom, inner Grid Height=312.
    static let height: CGFloat = 312
    static let horizontalInset: CGFloat = 60
    static let bottomInset: CGFloat = 99
    private static let messagesWidth: CGFloat = 280

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
            if viewModel.showBottom {
                panel
                    .frame(height: Self.height)
                    .padding(.horizontal, Self.horizontalInset)
                    .padding(.bottom, Self.bottomInset)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: ArenaBottomPanelHoverKey.self,
                                            value: proxy.frame(in: .rootOverlayCanvas))
                                // HDT marks this panel IsOverlayHitTestVisible while
                                // ShowBottom is true, so the card list can actually be
                                // scrolled. Without it the overlay stays click-through
                                // here and any row past the first is unreachable.
                                .preference(key: InteractiveRegionPreferenceKey.self,
                                            value: [proxy.frame(in: .rootOverlayCanvas)])
                        }
                    )
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: viewModel.showBottom)
    }

    private var panel: some View {
        VStack(spacing: 0) {
            header
            body_
        }
        // HDT layers a blurred screen capture of the game behind this
        // (PanelBackground). That needs Screen Recording permission, which
        // HSTracker does not currently ask for, so the panel is opaque-dark
        // instead - see ArenaPickHelperViewModel for the rest of that note.
        .background(Color.black.opacity(0.82))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.13), lineWidth: 1))
        .cornerRadius(4)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(verbatim: viewModel.bottomPanelTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
            if viewModel.isRelatedCardsSorted {
                Text(String.localizedString("ArenaPick_SortedByWinrate", comment: ""))
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.53))
                    .fixedSize()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.5))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.13))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var body_: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                cardList(width: geometry.size.width - (viewModel.showMessages ? Self.messagesWidth + 16 : 0))
                if viewModel.showMessages {
                    messages
                        .frame(width: Self.messagesWidth)
                        .padding(8)
                }
            }
            .overlay(
                // HDT's 12pt gradient under the header, so the content reads as
                // sitting below a lip rather than butting into it.
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.31), Color.black.opacity(0)]),
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 12)
                    .allowsHitTesting(false),
                alignment: .top
            )
        }
    }

    private func cardList(width: CGFloat) -> some View {
        GeometryReader { geometry in
            ZStack {
                if viewModel.hasBottomPanelCards {
                    // The grid's scale is solved against the available *width*
                    // only (HDT passes MaxCardGridHeight=10000), so anything past
                    // one row overflows by design and scrolls - a related-cards
                    // set of 8 at 4 columns is two rows deep. minHeight centres
                    // a short grid instead of pinning it to the top.
                    ScrollView(.vertical, showsIndicators: false) {
                        ArenaCardImageGridView(cards: viewModel.bottomPanelCards,
                                               columns: viewModel.bottomPanelColumnCount,
                                               maxWidth: max(1, width))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: geometry.size.height, alignment: .center)
                    }
                } else {
                    Text(String.localizedString("ArenaPick_NoRelatedCards", comment: ""))
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(width: max(1, width))
        .clipped()
    }

    private var messages: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array((viewModel.messages ?? []).enumerated()), id: \.offset) { _, message in
                Text(verbatim: message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black.opacity(0.5))
        .cornerRadius(4)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.13), lineWidth: 1))
        .shadow(color: .black.opacity(0.6), radius: 7, x: 4, y: 4)
    }
}

/// Frame of the bottom panel, so `RootOverlayWindow` can tell when the cursor is
/// over it. Separate from `HoverRegionPreferenceKey`, which is wired straight to
/// the Battlegrounds minion browser's filter button.
/// The direction funnel, in canvas pixels. A polygon, so unlike the panel's own
/// frame it cannot be expressed as a rect - a bounding box here would keep the
/// panel open for any sideways movement, which is exactly what it must not do.
@available(macOS 10.15, *)
struct ArenaDirectionTriggerKey: PreferenceKey {
    static var defaultValue: [CGPoint] = []
    static func reduce(value: inout [CGPoint], nextValue: () -> [CGPoint]) {
        let next = nextValue()
        if !next.isEmpty { value = next }
    }
}

/// The three wedges running from each choice across to the deck rail, in canvas
/// pixels. Always three entries; a disabled wedge reports as empty, which is how
/// it stops being enterable.
@available(macOS 10.15, *)
struct ArenaCardListDirectionKey: PreferenceKey {
    static var defaultValue: [[CGPoint]] = []
    static func reduce(value: inout [[CGPoint]], nextValue: () -> [[CGPoint]]) {
        let next = nextValue()
        if !next.isEmpty { value = next }
    }
}

/// The deck rail's own frame, for the same reason the bottom panel reports one.
@available(macOS 10.15, *)
struct ArenaCardListTriggerKey: PreferenceKey {
    static var defaultValue: CGRect?
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        if let next = nextValue() {
            value = value?.union(next) ?? next
        }
    }
}

@available(macOS 10.15, *)
struct ArenaBottomPanelHoverKey: PreferenceKey {
    static var defaultValue: CGRect?
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        if let next = nextValue() {
            value = value?.union(next) ?? next
        }
    }
}
