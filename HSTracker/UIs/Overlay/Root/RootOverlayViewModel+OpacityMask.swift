//
//  RootOverlayViewModel+OpacityMask.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// The Set*OpacityMask methods HDT hangs off OverlayWindow
// (Windows/OverlayWindow.xaml.cs), which is what RootOverlay is here: each
// works out where the game is about to draw something of its own and hands the
// rectangles to OverlayOpacityMask under a key it can clear them by again.
//
// All of these touch @Published state, so they run on the main thread - the
// watcher-side callers hop first.
@available(macOS 10.15, *)
extension RootOverlayViewModel {
    // HDT builds one of these per call from the overlay window's own size and
    // screen ratio; RootOverlay covers the same Hearthstone client area, so it
    // is measured the same way.
    private func makeRegionDrawer() -> RegionDrawer {
        let frame = SizeHelper.hearthstoneWindow.frame
        return RegionDrawer(height: frame.height, width: frame.width, screenRatio: SizeHelper.screenRatio)
    }

    func setFriendListOpacityMask(_ visible: Bool) {
        if visible {
            let regionDrawer = makeRegionDrawer()
            let rect = regionDrawer.drawFriendsListRegion()

            opacityMask.addMaskedRegion("FriendsList", rect)
        } else {
            opacityMask.removeMaskedRegion("FriendsList")
        }
    }

    func setGameMenuOpacityMask(_ visible: Bool) {
        if visible {
            let regionDrawer = makeRegionDrawer()
            let rect = regionDrawer.drawGameMenuRegion()

            opacityMask.addMaskedRegion("GameMenu", rect)
        } else {
            opacityMask.removeMaskedRegion("GameMenu")
        }
    }

    func setCardOpacityMask(_ state: BigCardArgs) {
        if battlegroundsHeroPicking.isViewingTeammate {
            return
        }

        opacityMask.batchUpdate {
            let card = Cards.by(cardId: state.cardId)
            let isFriendly = state.side == PlayerSide.friendly.rawValue
            let isHand = state.isHand

            opacityMask.removeMaskedRegion("BigCard")

            let regionDrawer = makeRegionDrawer()
            let tooltipHeight = Double(state.tooltipHeights.reduce(0, +))
            let enchantHeight = Double(state.enchantmentHeights.reduce(0, +))

            // Enemy secret area
            if card == nil && state.zonePosition > 0 && !isFriendly && !isHand {
                let rects = regionDrawer.drawSecretCardRegions(position: state.zonePosition,
                                                               isPlayerBoard: isFriendly,
                                                               tooltipHeight: tooltipHeight)

                for rect in rects {
                    opacityMask.addMaskedRegion("BigCard", rect)
                }
            }

            guard let card else {
                return
            }

            if (card.type == .minion || card.type == .location || card.type == .battleground_spell) && !isHand {
                let rects = regionDrawer.drawBoardCardRegions(minionCount: state.zoneSize,
                                                              position: state.zonePosition,
                                                              isPlayerBoard: isFriendly,
                                                              tooltipHeight: tooltipHeight,
                                                              enchantHeight: enchantHeight)

                for rect in rects {
                    opacityMask.addMaskedRegion("BigCard", rect)
                }
            }

            if card.type == .spell && !isHand {
                let rects = regionDrawer.drawSecretCardRegions(position: state.zonePosition,
                                                               isPlayerBoard: isFriendly,
                                                               tooltipHeight: tooltipHeight)

                for rect in rects {
                    opacityMask.addMaskedRegion("BigCard", rect)
                }
            }

            if card.type == .battleground_trinket && !isHand {
                if card.id == "BG30_Trinket_1st" || card.id == "BG30_Trinket_2nd" {
                    return
                }

                let game = AppDelegate.instance().coreManager.game
                let trinkets = isFriendly ? game.player.trinkets : game.opponent.trinkets

                let trinketEntity = trinkets.first { x in
                    x.has(tag: .tag_script_data_num_6) && x.card.dbfId == card.dbfId
                }

                let hasAttachedCard = trinketEntity?.has(tag: .bacon_evolution_card_id) ?? false

                let position = trinketEntity?[.tag_script_data_num_6] ?? 0

                if position == 0 {
                    return
                }

                let rects = position == 3
                    ? regionDrawer.drawBgHeroTrinketRegions(isPlayerBoard: isFriendly, hasAttachedCard: true,
                                                            tooltipHeight: tooltipHeight)
                    : regionDrawer.drawBgTrinketRegions(position: position, hasAttachedCard: hasAttachedCard,
                                                        isPlayerBoard: isFriendly, tooltipHeight: tooltipHeight)

                for rect in rects {
                    opacityMask.addMaskedRegion("BigCard", rect)
                }
            }

            if card.type == .hero_power && !isHand {
                let rect = regionDrawer.drawHeroPowerRegion(isPlayerBoard: isFriendly)

                opacityMask.addMaskedRegion("BigCard", rect)
            }

            if card.type == .weapon && !isHand {
                let rects = regionDrawer.drawWeaponRegions(isPlayerBoard: isFriendly,
                                                            tooltipHeight: tooltipHeight,
                                                            enchantHeight: enchantHeight)

                for rect in rects {
                    opacityMask.addMaskedRegion("BigCard", rect)
                }
            }

            if isHand {
                let rects = regionDrawer.drawHandCardRegions(cardCount: state.zoneSize,
                                                              position: state.zonePosition,
                                                              isPlayerBoard: isFriendly,
                                                              cardType: card.type,
                                                              tooltipHeight: tooltipHeight,
                                                              enchantHeight: enchantHeight)

                for rect in rects {
                    opacityMask.addMaskedRegion("BigCard", rect)
                }
            }
        }
    }

    func setMulliganAnomalyMask(_ card: Card?) {
        opacityMask.removeMaskedRegion("MulliganAnomaly")

        guard let card else {
            return
        }

        let regionDrawer = makeRegionDrawer()

        let hasAttachedCard = card.baconEvolutionCardId != 0

        let rects = regionDrawer.drawMulliganAnomalyRegions(hasAttachedCard: hasAttachedCard, isTooltip: false)

        opacityMask.batchUpdate {
            for rect in rects {
                opacityMask.addMaskedRegion("MulliganAnomaly", rect)
            }
        }
    }

    func setDiscoverCardOpacityMask(zoneSize: Int, hasDarkGifts: Bool) {
        opacityMask.removeMaskedRegion("DiscoverCard")

        if zoneSize == 0 {
            return
        }

        let regionDrawer = makeRegionDrawer()
        let rects = regionDrawer.drawDiscoverCardRegions(zoneSize: zoneSize, hasDarkGifts: hasDarkGifts)

        opacityMask.batchUpdate {
            for rect in rects {
                opacityMask.addMaskedRegion("DiscoverCard", rect)
            }
        }
    }

    func setTrinketPickingOpacityMask(zoneSize: Int) {
        opacityMask.removeMaskedRegion("DiscoverCard")

        if zoneSize == 0 {
            return
        }

        let regionDrawer = makeRegionDrawer()
        let rects = regionDrawer.drawTrinketPickingRegions(zoneSize: zoneSize)

        opacityMask.batchUpdate {
            for rect in rects {
                opacityMask.addMaskedRegion("DiscoverCard", rect)
            }
        }
    }
}
