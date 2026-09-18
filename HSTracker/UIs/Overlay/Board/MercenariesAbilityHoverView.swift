//
//  MercenariesAbilityHoverView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/16/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's MercAbility1/2/3: the three CardImages in the StackPanel at
// Canvas.Top="0" Canvas.Right="0", filled by ShowMercHover while a Mercenaries
// board minion is hovered and emptied again by ClearMercHover.
//
// Replaces the three FloatingCard windows HSTracker used to drive through
// show_floating_card notifications with hand-computed screen frames.
final class MercenariesAbilityHoverViewModel: ObservableObject {
    // One CardImage's worth of state: CardId, and the ShowQuestionmark that
    // marks an ability whose tier could not be read off the board.
    struct Ability: Identifiable, Equatable {
        let id: Int
        let card: Card
        let showQuestionmark: Bool

        static func == (lhs: Ability, rhs: Ability) -> Bool {
            lhs.id == rhs.id && lhs.card === rhs.card && lhs.showQuestionmark == rhs.showQuestionmark
        }
    }

    @Published var abilities: [Ability] = []

    func show(_ abilities: [Ability]) {
        guard self.abilities != abilities else { return }
        self.abilities = abilities
    }

    // ClearMercHover, which sets all three CardImages back to a null card.
    func clear() {
        guard !abilities.isEmpty else { return }
        abilities = []
    }
}

struct MercenariesAbilityHoverView: View {
    @ObservedObject var viewModel: MercenariesAbilityHoverViewModel
    // The overlay's real, post-scale size. OverlayWindow sizes the stack from
    // MercAbilityHeight, a plain fraction of the client height, and never gives
    // it a ScaleTransform - so this belongs in the fixed-pixel layer.
    let canvasSize: CGSize

    // OverlayWindow.MercAbilityHeight, the Height each CardImage in the stack
    // is bound to.
    private static func slotHeight(_ canvasSize: CGSize) -> CGFloat { canvasSize.height * 0.3 }

    // Config.CardImageSize defaults to 1, and CardImageSizeConverter multiplies
    // it by the card render's own 256x388 - so the image is capped at its
    // native size however tall the client is.
    private static let cardSize = CGSize(width: 256, height: 388)

    // Margin="0 12 0 0" on the image inside CardImage.
    private static let imageTopMargin: CGFloat = 12

    // StoryboardExpand: a 200ms scale from 0 to 1 about the centre, which HDT
    // runs as each card's asset arrives.
    private static let expandDuration = 0.2

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it; it renders nothing while no minion is hovered.
        ZStack(alignment: .topTrailing) {
            Color.clear
            VStack(spacing: 0) {
                ForEach(viewModel.abilities) { ability in
                    cardImage(ability)
                        .frame(height: Self.slotHeight(canvasSize))
                        .transition(.scale)
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topTrailing)
        .allowsHitTesting(false)
        .animation(.linear(duration: Self.expandDuration), value: viewModel.abilities)
    }

    // CardImage: the card render inset from the top of its slot, with the
    // unknown-tier badge over it.
    private func cardImage(_ ability: MercenariesAbilityHoverViewModel.Ability) -> some View {
        let height = min(Self.slotHeight(canvasSize) - Self.imageTopMargin, Self.cardSize.height)
        let width = height * Self.cardSize.width / Self.cardSize.height
        return ZStack(alignment: .topLeading) {
            Color.clear
            MercenariesAbilityHoverImage(card: ability.card)
                .frame(width: width, height: height)
                .padding(.top, Self.imageTopMargin)
            if ability.showQuestionmark {
                questionmark(controlSize: CGSize(width: width, height: Self.slotHeight(canvasSize)))
            }
        }
        .frame(width: width, alignment: .topLeading)
    }

    // The "?" badge: a Canvas pinned to the middle cell of a 12/1/0.1 by
    // 6.6/1/4 grid over the card, holding a 40pt disc offset half its own size
    // so it straddles that corner, scaled by IconScaling.
    private func questionmark(controlSize: CGSize) -> some View {
        // IconScaling = Math.Min(1, ActualHeight / 500) on the CardImage.
        let scale = min(1, controlSize.height / 500)
        let anchor = CGPoint(x: controlSize.width * 12 / 13.1,
                             y: controlSize.height * 6.6 / 11.6)
        return ZStack {
            Circle().fill(Color(hex: "#141617")).frame(width: 40, height: 40)
            Circle().fill(Color(hex: "#23272A")).frame(width: 36, height: 36)
            Text(verbatim: "?")
                .chunkFive(size: 28)
                .outlinedText()
                .fixedSize()
        }
        .frame(width: 40, height: 40)
        .scaleEffect(scale)
        // Canvas.Top="-20" Canvas.Left="-20" on a 40pt box centres it on the
        // cell's own top-left corner, and the Canvas scales about that corner.
        .offset(x: anchor.x - 20 * scale, y: anchor.y - 20 * scale)
    }
}

// The card render itself. HDT shows a class-coloured placeholder while the
// asset downloads; HSTracker has no such art, so the slot stays empty until the
// image arrives.
private struct MercenariesAbilityHoverImage: View {
    let card: Card

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
        .onAppear(perform: load)
    }

    private func load() {
        if let cached = ImageUtils.cachedCardArt(cardId: card.id) {
            image = cached
            return
        }
        ImageUtils.cardArt(for: card.id) { img in
            DispatchQueue.main.async {
                self.image = img
            }
        }
    }
}
