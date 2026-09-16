//
//  CardMarkerViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/16/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's CardMarker: the age badge drawn over one card in the opponent's hand,
// with the icon and source-card tile that say where the card came from.
// Replaces the CardHud NSView the CardHudContainer panel held ten of.
@available(macOS 10.15, *)
final class CardMarkerViewModel: ObservableObject {
    // CardMarker.SourceType, which decides what the tooltip says about the card
    // the source tile shows.
    enum SourceType {
        case known
        case drawnBy
        case createdBy
    }

    // Visibility on the marker itself.
    @Published var isShown = false

    // CardAge / CardAgeVisibility: nil collapses the 36x36 badge, which takes
    // the whole top half of the control with it.
    @Published var cardAge: Int?

    // Icon: the asset name for the card's CardMark, or nil for none.
    @Published var icon: String?

    // CostReduction / CostReductionVisibility. Stored already negated, as HDT
    // stores it - UpdateCostReduction assigns -costReduction and shows it only
    // while the reduction is positive.
    @Published var costReduction: Int?

    // SourceCard, which drives the tile badge and the hover tooltip.
    @Published var sourceCard: Card?

    // CardSourceType. Recorded but not yet shown: HDT turns it into the
    // "Created by X" / "Drawn by X" line its CardTooltip carries alongside the
    // card image, and the tooltip panel this port hands the marker to shows the
    // image only. Kept so updateSource still says what it means, and so the
    // line has something to read when it is ported.
    @Published var sourceType: SourceType?

    // UpdateIcon: HDT reads the asset name off an attribute on the CardMark
    // enum; the names are spelled out here as the AppKit marker spelled them.
    func updateIcon(_ mark: CardMark) {
        switch mark {
        case .coin: icon = "coin"
        case .kept: icon = "kept"
        case .mulliganed: icon = "mulliganed"
        case .returned: icon = "returned"
        case .created: icon = "created"
        case .forged: icon = "card-icon-forged"
        case .drawnByEntity: icon = "card-icon-drawn"
        case .shattered: icon = "shatter-split"
        case .shatterCombined: icon = "shatter-combined"
        case .prepared: icon = "prepare"
        default: icon = nil
        }
    }

    func updateCardAge(_ cardAge: Int?) {
        self.cardAge = cardAge
    }

    func updateCostReduction(_ costReduction: Int) {
        self.costReduction = costReduction > 0 ? -costReduction : nil
    }

    func updateSource(_ card: Card?, _ sourceType: SourceType?) {
        self.sourceType = sourceType
        guard sourceCard !== card else { return }
        sourceCard = card
    }
}

// The ten markers and the hand they describe - OverlayWindow's _cardMarks list
// and the part of UpdateOverlay that fills it. Replaces CardHudContainer.
@available(macOS 10.15, *)
final class OpponentHandMarkersViewModel: ObservableObject {
    static let maxHandSize = 10

    // Game.updateCardHud's gate.
    @Published var isShown = false

    // Opponent.HandCount, which picks the row of the position table.
    @Published var handCount = 0

    let markers = (0 ..< maxHandSize).map { _ in CardMarkerViewModel() }

    // OverlayWindow's _cardMarkPos, normalised against the 1024x768 the table
    // was measured at. Indexed by hand count, then by position in hand.
    static let positions: [[CGPoint]] = {
        let w: CGFloat = 1024, h: CGFloat = 768
        func row(_ pairs: [(CGFloat, CGFloat)]) -> [CGPoint] {
            pairs.map { CGPoint(x: $0.0 / w, y: $0.1 / h) }
        }
        return [
            row([(480, 48)]),
            row([(439, 47), (520, 48)]),
            row([(392, 33), (479, 47), (569, 40)]),
            row([(382, 21), (446, 41), (512, 47), (580, 43)]),
            row([(375, 23), (427, 39), (479, 47), (533, 46), (586, 36)]),
            row([(371, 12), (414, 30), (458, 43), (502, 48), (546, 47), (591, 39)]),
            row([(368, 15), (405, 31), (442, 41), (479, 48), (517, 47), (555, 41), (594, 31)]),
            row([(365, 4), (397, 22), (430, 35), (462, 45), (496, 48), (530, 48), (563, 43), (597, 33)]),
            row([(363, 7), (392, 23), (421, 35), (450, 43), (479, 48), (508, 47), (539, 43), (569, 35),
                 (599, 23)]),
            row([(364, 4), (388, 13), (414, 28), (440, 38), (467, 45), (492, 48), (520, 48), (546, 44),
                 (573, 37), (600, 27)])
        ]
    }()

    private var drawDisallowList = [Int]()

    // The block of UpdateOverlay that fills the ten markers. HSTracker's own
    // version of this already followed HDT's closely; the two settings HDT gates
    // parts of it on - HideOpponentCardAge and HideOpponentCardMarks - have no
    // counterpart here, so those branches are simply always taken.
    func update(hand: [Entity], handCount: Int, game: Game) {
        self.handCount = min(handCount, Self.maxHandSize)

        for i in 0 ..< Self.maxHandSize {
            let marker = markers[i]
            guard i < self.handCount,
                  let entity = hand.first(where: { $0[.zone_position] == i + 1 }) else {
                if marker.isShown {
                    marker.isShown = false
                }
                continue
            }

            marker.updateCardAge(entity.info.turn)

            if entity.hasCardId && !entity.info.hidden && entity.info.cardMark != .coin {
                marker.updateSource(entity.card, .known)
                if entity.info.cardMark == .returned {
                    marker.updateIcon(entity.info.cardMark)
                } else if entity.info.copyOfCardId != nil {
                    marker.updateIcon(.none)
                }
            } else {
                marker.updateIcon(entity.info.cardMark)
                if entity.info.cardMark == .created {
                    let creatorId = entity.info.getCreatorId()
                    if creatorId > 0, let creator = game.entities[creatorId] {
                        marker.updateSource(creator.card, .createdBy)
                    } else {
                        marker.updateSource(nil, nil)
                    }
                } else if let drawerId = entity.info.getDrawerId() {
                    if drawerId > 0, let drawer = game.entities[drawerId] {
                        if !disallowList().contains(drawer.card.dbfId) {
                            marker.updateSource(drawer.card, .drawnBy)
                        } else {
                            marker.updateSource(nil, nil)
                            marker.updateIcon(.none)
                        }
                    } else {
                        marker.updateSource(nil, nil)
                    }
                } else {
                    marker.updateSource(nil, nil)
                }
            }
            marker.updateCostReduction(entity.info.costReduction)

            let shown = !game.isInMenu && !game.isBattlegroundsMatch() && game.isMulliganDone()
            if marker.isShown != shown {
                marker.isShown = shown
            }
        }
    }

    func hide() {
        guard isShown else { return }
        isShown = false
    }

    private func disallowList() -> [Int] {
        if let list = RemoteConfig.data?.draw_card_blacklist, drawDisallowList.count == 0 {
            drawDisallowList = list.compactMap { $0.dbf_id }
        }
        return drawDisallowList
    }
}
