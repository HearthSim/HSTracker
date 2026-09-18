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

    // HDT's SetArenaCardOpacityMask, fed by ArenaStateWatcher.OnTrayBigCardChanged:
    // the card blown up out of the arena deck tray, which the game draws over
    // its own draft screen and so over the pick helper with it.
    //
    // HDT starts its debounce before the null check and only awaits it past
    // that. A C# async method runs synchronously up to its first await, so the
    // debounce counter is bumped by every call - card or no card - whether or
    // not the caller ever awaits the result, and that is load-bearing: it is
    // how a card arriving cancels a removal still waiting out its 30ms, and how
    // the tooltip going away cancels an add still waiting out its 240ms.
    //
    // Swift's `await` has no such synchronous prefix, so the bump happens in a
    // task of its own. It is a main-actor task on purpose: these arrive on the
    // main queue already (ArenaStateEvent raises there), so hopping back to the
    // same actor keeps the bumps both serialized and in call order, which the
    // global executor guarantees for neither.
    func setArenaCardOpacityMask(_ bigCard: ArenaBigCard?) {
        let calledAgain = debounceArenaMask(milliseconds: 30, key: "setArenaCardOpacityMask")

        guard let bigCard else {
            Task { @MainActor in
                if await calledAgain.value {
                    return
                }
                opacityMask.removeMaskedRegion("ArenaTrayBigCard")
            }
            return
        }

        opacityMask.batchUpdate {
            opacityMask.removeMaskedRegion("ArenaTrayBigCard")

            let regionDrawer = makeRegionDrawer()

            // PositionY is a unity-space coordinate. Remap it into the screen
            // space range we expect the top of the card to be.
            let y = MathUtil.remap(bigCard.positionY, 0.27, -0.27, 0, 0.54)
            let rect = regionDrawer.drawCardRegion(offsetX: 0.55, offsetY: y,
                                                   cardHeight: 450.0 / 1080.0)
            opacityMask.addMaskedRegion("ArenaTrayBigCard", rect)
        }
    }

    // HDT's SetArenaTooltipOpacityMask, fed by ArenaStateWatcher.OnTooltipChanged:
    // the tooltip the game puts under a hovered draft choice, which lands right
    // where the pick helper draws its scores.
    //
    // The removal is immediate and only the add waits - the reverse of the tray
    // card above, and HDT's own asymmetry.
    func setArenaTooltipOpacityMask(_ tooltip: ([Float], Int)?) {
        opacityMask.removeMaskedRegion("ArenaChoiceTooltip")

        let calledAgain = debounceArenaMask(milliseconds: 240, key: "setArenaTooltipOpacityMask")

        guard let tooltip else {
            return
        }

        Task { @MainActor in
            if await calledAgain.value {
                return
            }

            let regionDrawer = makeRegionDrawer()

            let x: Double
            switch tooltip.1 {
            case 0: x = 0.2975
            case 1: x = 0.49
            default: x = 0.324
            }
            let rect = regionDrawer.drawCardTooltipRegion(offsetX: x, offsetY: 0.195,
                                                          height: Double(tooltip.0.reduce(0, +)) * 1.01)
            opacityMask.addMaskedRegion("ArenaChoiceTooltip", rect)
        }
    }

    // The half of HDT's `var calledAgain = Debounce.WasCalledAgain(n)` that runs
    // at the call site: bump the counter now, and hand back the wait for the
    // caller to await where HDT awaits it. The key is passed explicitly because
    // Debounce keys on #function, which both callers would otherwise share
    // through this one helper.
    private func debounceArenaMask(milliseconds: Int, key: String) -> Task<Bool, Never> {
        return Task { @MainActor in
            await Debounce.wasCalledAgain(milliseconds: milliseconds, callerMemberName: key)
        }
    }

    func setCardOpacityMask(_ state: BigCardArgs) {
        if battlegroundsHeroPicking.isViewingTeammate {
            return
        }

        opacityMask.batchUpdate {
            // Cards.any(byId:), not Cards.by(cardId:): the latter filters out
            // hero powers and hero skins, so the hero power branch below could
            // never run and the nil it returned instead fell through to the
            // enemy-secret branch. HDT's Database.GetCardFromId, which this
            // stands in for, hands back whatever the id names.
            let card = Cards.any(byId: state.cardId)
            let isFriendly = state.side == PlayerSide.friendly.rawValue
            let isHand = state.isHand

            OverlayOpacityMask.trace("setCardOpacityMask card=\(state.cardId)"
                                     + " type=\(card?.type.rawValue.description ?? "nil")"
                                     + " friendly=\(isFriendly) hand=\(isHand)"
                                     + " zone=\(state.zonePosition)/\(state.zoneSize)")

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

    func setHeroPickingTooltipMask(zoneSize: Int, zonePosition: Int, tooltipOnRight: Bool,
                                   numCards: Int, buddiesEnabled: Bool = false) {
        opacityMask.removeMaskedRegion("HeroPickingTooltip")

        if zoneSize == 0 {
            return
        }

        let regionDrawer = makeRegionDrawer()

        let rects = regionDrawer.drawBgHeroPickingTooltipRegion(zoneSize: zoneSize,
                                                                zonePosition: zonePosition,
                                                                tooltipOnRight: tooltipOnRight,
                                                                numCards: numCards,
                                                                buddiesEnabled: buddiesEnabled)

        opacityMask.batchUpdate {
            for rect in rects {
                opacityMask.addMaskedRegion("HeroPickingTooltip", rect)
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
