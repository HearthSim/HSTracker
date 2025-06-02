//
//  PlayedSpellSchoolsCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/29/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class PlayedSpellSchoolsCounter: NumericCounter {
    override var localizedName: String {
        return String.localizedString("Counter_PlayedSpellSchools", comment: "")
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Mage.DiscoveryOfMagic
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Neutral.Multicaster,
            CardIds.Collectible.Shaman.SirenSong,
            CardIds.Collectible.Shaman.CoralKeeper,
            CardIds.Collectible.Shaman.RazzleDazzler,
            CardIds.Collectible.Mage.DiscoveryOfMagic,
            CardIds.Collectible.Mage.InquisitiveCreation,
            CardIds.Collectible.Mage.WisdomOfNorgannon,
            CardIds.Collectible.Mage.Sif,
            CardIds.Collectible.Mage.ElementalInspiration,
            CardIds.Collectible.Mage.MagisterDawngrasp
        ]
    }

    private var playedSpellSchools = Set<SpellSchool>()

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 1 && opponentMayHaveRelevantCards(ignoreNeutral: true)
    }

    override func getCardsToDisplay() -> [String] {
        return isPlayerCounter ?
        getCardsInDeckOrKnown(cardIds: relatedCards) :
        filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
    }

    override var isDisplayValueLong: Bool {
        return true
    }

    override func valueToShow() -> String {
        if counter == 0 {
            return String.localizedString("Counter_Spell_School_None", comment: "")
        }
        return playedSpellSchools.compactMap { $0.localizedText() }
            .sorted()
            .joined(separator: ", ")
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        let controller = entity[.controller]
        if !((controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter)) {
            return
        }
        if discountIfCantPlay(tag: tag, value: value, entity: entity) {
            if let schoolTag = SpellSchool(rawValue: entity[.spell_school]) {
                playedSpellSchools.remove(schoolTag)
            }
            return
        }
        guard tag == .zone else { return }
        guard value == Zone.play.rawValue || value == Zone.secret.rawValue else { return }
        guard AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.type == "PLAY" else { return }
        guard entity.isSpell else { return }

        let spellSchoolTag = entity[.spell_school]
        if spellSchoolTag > 0, let spellSchool = SpellSchool(rawValue: spellSchoolTag) {
            playedSpellSchools.insert(spellSchool)
            lastEntityToCount = entity
            counter = playedSpellSchools.count
        }
    }
}
