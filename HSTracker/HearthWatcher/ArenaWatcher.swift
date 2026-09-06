//
//  ArenaWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

enum ArenaSessionState: Int {
    case invalid = -1,
         no_run,
         drafting,
         midrun,
         redrafting,
         editing_deck,
         rewards,
         midrun_redraft_pending
}

struct CompleteDeckEventArgs {
    let info: MirrorArenaInfo
}

struct RewardsEventArgs {
    let info: MirrorArenaInfo
}

final class ArenaWatcher: Watcher {
    private var _prevSlot = -1
    private var _prevRedraftSlot = -1
    private var _prevChoices: [MirrorCard]?
    private var _prevPackages: [[MirrorCard]]?
    private var _prevChoicesVersion = -1
    private var _prevInfo: MirrorArenaInfo?
    private var _prevIsUnderground: Bool?
    private var _prevArenaSessionState = ArenaSessionState.invalid
    private final let maxDeckSize = 30
    private final let maxRedraftDeckSize = 5
    
    private var _isDualClass = false

    public var onCompleteDeck: ((ArenaWatcher, CompleteDeckEventArgs) -> Void)?
    public var onRewards: ((RewardsEventArgs) -> Void)?
    public var onChoicesChanged: ((ArenaWatcher, ChoicesChangedEventArgs) -> Void)?
    public var onRedraftChoicesChanged: ((ArenaWatcher, RedraftChoicesChangedEventArgs) -> Void)?
    public var onCardPicked: ((ArenaWatcher, CardPickedEventArgs) -> Void)?
    public var onRedraftCardPicked: ((ArenaWatcher, RedraftCardPickedEventArgs) -> Void)?

    override init(delay: TimeInterval = 0.500) {
        super.init(delay: delay)
    }

    override func setup() {
        _prevSlot = -1
        _prevRedraftSlot = -1
        _prevInfo = nil
        _prevChoices = nil
        _prevChoicesVersion = -1
        _prevPackages = nil
        _prevIsUnderground = nil
        _prevArenaSessionState = .invalid
        _isDualClass = false
    }

    override func update() -> Bool {
        guard let arenaInfo = DeckImporter.fromArena(false) else {
            return false
        }
        
        if arenaInfo.sessionState.intValue == ArenaSessionState.midrun.rawValue {
            if _prevArenaSessionState == .drafting {
                let numCards = arenaInfo.deck.cards.reduce(0, { $0 + $1.count.intValue })
                if numCards == maxDeckSize {
                    // Dual-class drafts spend an extra slot on the hero power, so the
                    // final card lands one slot later.
                    let lastSlot = _isDualClass ? maxDeckSize + 1 : maxDeckSize
                    if _prevSlot == lastSlot {
                        cardPicked(arenaInfo)
                    }
                }
            }
            onCompleteDeck?(self, CompleteDeckEventArgs(info: arenaInfo))
            if arenaInfo.rewards.count > 0 {
                onRewards?(RewardsEventArgs(info: arenaInfo))
            }
            stop()
            return true
        }
        
        if arenaInfo.sessionState.intValue == ArenaSessionState.editing_deck.rawValue {
            if _prevArenaSessionState == .redrafting || _prevArenaSessionState == .midrun_redraft_pending || _prevArenaSessionState == .invalid {
                let numCards = arenaInfo.redraftDeck.cards.reduce(0, { $0 + $1.count.intValue })
                if numCards == maxDeckSize {
                    if _prevRedraftSlot == maxRedraftDeckSize - 1 {
                        redraftLastCardPicked(arenaInfo)
                        _prevRedraftSlot = -1
                    }
                }
            }
        }
        
        if arenaInfo.sessionState.intValue == ArenaSessionState.redrafting.rawValue || arenaInfo.sessionState.intValue == ArenaSessionState.midrun_redraft_pending.rawValue {
            return updateRedraft(arenaInfo)
        }
        
        // _prevSlot can be related to The arena while currentSlot is Underground and vice-versa
        // so we need to check if _prevIsUnderground is the same as arenaInfo.IsUnderground
        if _prevInfo != nil && arenaInfo.currentSlot.intValue <= _prevSlot && _prevIsUnderground == arenaInfo.isUnderground {
            return false
        }

        guard let choices = MirrorHelper.getArenaDraftChoices(), choices.choices.count > 0 else {
            return false
        }
        
        if _prevChoicesVersion == choices.version.intValue {
            return false
        }
        
        onChoicesChanged?(self, ChoicesChangedEventArgs(choices: choices.choices,
                                                        deck: arenaInfo.deck,
                                                        slot: arenaInfo.currentSlot.intValue,
                                                        isUnderground: arenaInfo.isUnderground,
                                                        packages: choices.packages))

        // In dual-class Arena the player picks a hero power before the hero, so the
        // deck carries a hero power while the hero is still unset.
        _isDualClass = _isDualClass || (!arenaInfo.deck.heroPower.isEmpty && arenaInfo.deck.hero.isEmpty)

        // we need to check _prevIsUnderground == arenaInfo.IsUnderground
        // otherwise changing arena mode would trigger Hero/CardPicked
        if ((_prevSlot == 0 && arenaInfo.currentSlot.intValue == 1)
            || (_isDualClass && _prevSlot == 1 && arenaInfo.currentSlot.intValue == 2))
            && _prevIsUnderground == arenaInfo.isUnderground {
            heroPicked(arenaInfo)
        } else if _prevSlot > 0 && _prevIsUnderground == arenaInfo.isUnderground {
            cardPicked(arenaInfo)
        }
        _prevSlot = arenaInfo.currentSlot.intValue
        _prevRedraftSlot = -1
        _prevInfo = arenaInfo
        _prevChoices = choices.choices
        _prevChoicesVersion = choices.version.intValue
        _prevPackages = choices.packages
        _prevIsUnderground = arenaInfo.isUnderground
        _prevArenaSessionState = ArenaSessionState(rawValue: arenaInfo.sessionState.intValue) ?? .invalid
        return false
    }
    
    private func updateRedraft(_ arenaInfo: MirrorArenaInfo) -> Bool {
        let redraftSlot = arenaInfo.redraftCurrentSlot.intValue
        
        guard let choices = MirrorHelper.getArenaDraftChoices(), choices.choices.count > 0 else {
            return false
        }
        
        if _prevInfo != nil && redraftSlot <= _prevRedraftSlot && _prevIsUnderground == arenaInfo.isUnderground && _prevChoicesVersion == choices.version.intValue {
            return false
        }
        onRedraftChoicesChanged?(self, RedraftChoicesChangedEventArgs(choices: choices.choices,
                                                                      deck: arenaInfo.deck,
                                                                      redraftDeck: arenaInfo.redraftDeck,
                                                                      slot: redraftSlot,
                                                                      losses: arenaInfo.losses.intValue,
                                                                      isUnderground: arenaInfo.isUnderground))
        
        if _prevRedraftSlot >= 0 && _prevIsUnderground == arenaInfo.isUnderground {
            redraftCardPicked(arenaInfo)
        }
        
        _prevSlot = -1
        _prevRedraftSlot = redraftSlot
        _prevInfo = arenaInfo
        _prevChoices = choices.choices
        _prevChoicesVersion = choices.version.intValue
        _prevIsUnderground = arenaInfo.isUnderground
        _prevArenaSessionState = ArenaSessionState(rawValue: arenaInfo.sessionState.intValue) ?? .invalid
        return false
    }
    
    private func heroPicked(_ arenaInfo: MirrorArenaInfo) {
        guard let prevChoices = _prevChoices else { return }

        if let hero = prevChoices.first(where: { $0.cardId == arenaInfo.deck.hero }) {
            onCardPicked?(self, CardPickedEventArgs(picked: ArenaPickedCard(mirror: hero),
                                                    choices: prevChoices,
                                                    deck: arenaInfo.deck,
                                                    slot: arenaInfo.currentSlot.intValue - 1,
                                                    isUnderground: arenaInfo.isUnderground,
                                                    pickedPackage: nil))
            return
        }

        // No choice matched the deck's hero, so this was the hero-power half of a
        // dual-class draft.
        _isDualClass = true
        if let heroPower = prevChoices.first(where: { $0.cardId == arenaInfo.deck.heroPower }) {
            onCardPicked?(self, CardPickedEventArgs(picked: ArenaPickedCard(mirror: heroPower),
                                                    choices: prevChoices,
                                                    deck: arenaInfo.deck,
                                                    slot: arenaInfo.currentSlot.intValue - 1,
                                                    isUnderground: arenaInfo.isUnderground,
                                                    pickedPackage: nil))
        }
    }

    private func cardPicked(_ arenaInfo: MirrorArenaInfo) {
        let prevDeck = _prevInfo?.deck.cards ?? [MirrorCard]()
        let currDeck = arenaInfo.deck.cards

        var addedCards = currDeck.filter { cd in
            !prevDeck.contains(where: { pd in pd.cardId == cd.cardId && pd.count.intValue == cd.count.intValue })
        }

        // A package pick adds several cards at once. Find the package that was fully
        // added and take it out of the running, so the card the player actually
        // clicked is what remains.
        var usedPackage: [MirrorCard]?
        if let packages = _prevPackages {
            for package in packages {
                let packageFullyAdded = package.allSatisfy { pkgCard in
                    let currCount = currDeck.first(where: { $0.cardId == pkgCard.cardId })?.count.intValue ?? 0
                    let prevCount = prevDeck.first(where: { $0.cardId == pkgCard.cardId })?.count.intValue ?? 0
                    return (currCount - prevCount) >= pkgCard.count.intValue
                }
                if packageFullyAdded {
                    usedPackage = package
                    break
                }
            }
        }

        if let usedPackage {
            for card in usedPackage {
                if let index = addedCards.firstIndex(where: { $0.cardId == card.cardId }) {
                    addedCards.remove(at: index)
                }
            }
        }

        guard let picked = addedCards.first else { return }

        onCardPicked?(self, CardPickedEventArgs(picked: ArenaPickedCard(mirror: picked, count: 1),
                                                choices: _prevChoices ?? [MirrorCard](),
                                                deck: arenaInfo.deck,
                                                slot: arenaInfo.currentSlot.intValue - 1,
                                                isUnderground: arenaInfo.isUnderground,
                                                pickedPackage: usedPackage))
    }

    private func redraftCardPicked(_ arenaInfo: MirrorArenaInfo) {
        guard let pick = newRedraftCard(arenaInfo) else { return }

        onRedraftCardPicked?(self, RedraftCardPickedEventArgs(picked: ArenaPickedCard(mirror: pick, count: 1),
                                                              choices: _prevChoices ?? [MirrorCard](),
                                                              deck: arenaInfo.deck,
                                                              redraftDeck: arenaInfo.redraftDeck,
                                                              slot: arenaInfo.redraftCurrentSlot.intValue - 1,
                                                              losses: arenaInfo.losses.intValue,
                                                              isUnderground: arenaInfo.isUnderground))
    }

    private func redraftLastCardPicked(_ arenaInfo: MirrorArenaInfo) {
        guard let pick = newRedraftCard(arenaInfo) else { return }

        // On the last redraft pick the game has already folded the redrafted cards
        // into arenaInfo.deck, giving a 35-card deck. _prevInfo still holds the deck
        // as it was before the pick, which is what consumers expect.
        let deck = _prevInfo?.deck ?? arenaInfo.deck

        onRedraftCardPicked?(self, RedraftCardPickedEventArgs(picked: ArenaPickedCard(mirror: pick, count: 1),
                                                              choices: _prevChoices ?? [MirrorCard](),
                                                              deck: deck,
                                                              redraftDeck: arenaInfo.redraftDeck,
                                                              slot: arenaInfo.redraftCurrentSlot.intValue - 1,
                                                              losses: arenaInfo.losses.intValue,
                                                              isUnderground: arenaInfo.isUnderground))
    }

    private func newRedraftCard(_ arenaInfo: MirrorArenaInfo) -> MirrorCard? {
        guard let prevRedraft = _prevInfo?.redraftDeck.cards else { return nil }
        return arenaInfo.redraftDeck.cards.first { card in
            !prevRedraft.contains(where: { $0.cardId == card.cardId && $0.count.intValue == card.count.intValue })
        }
    }
}
