//
//  ArenaWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation
import Atomics

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

final class ArenaWatcher {
    private let delay: TimeInterval

    private var _running = ManagedAtomic<Bool>(false)
    private var _watch = ManagedAtomic<Bool>(false)
    internal var queue: DispatchQueue?
    
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
    
    public var onCompleteDeck: ((ArenaWatcher, CompleteDeckEventArgs) -> Void)?
    public var onRewards: ((RewardsEventArgs) -> Void)?

    init(delay: TimeInterval = 0.500) {
        self.delay = delay
    }
    
    func run() {
        _watch.store(true, ordering: .sequentiallyConsistent)
        if _running.load(ordering: .sequentiallyConsistent) {
            return
        }
        if queue == nil {
            queue = DispatchQueue(label: "\(type(of: self))",
                                  attributes: [])
        }
        if let queue = queue {
            queue.async {
                Thread.current.name = queue.label
                self.watch()
            }
        }
    }
    
    func stop() {
        _watch.store(false, ordering: .sequentiallyConsistent)
    }

    func watch() {
        _running.store(true, ordering: .sequentiallyConsistent)
        _prevSlot = -1
        _prevRedraftSlot = -1
        _prevInfo = nil
        _prevChoices = nil
        _prevChoicesVersion = -1
        _prevPackages = nil
        _prevIsUnderground = nil
        _prevArenaSessionState = .invalid
        while _watch.load(ordering: .sequentiallyConsistent) {
            Thread.sleep(forTimeInterval: delay)

            if !_watch.load(ordering: .sequentiallyConsistent) {
                break
            }
            if update() {
                break
            }
        }
        _running .store(false, ordering: .sequentiallyConsistent)
    }
    
    func update() -> Bool {
        guard let arenaInfo = DeckImporter.fromArena(false) else {
            return false
        }
        
        if arenaInfo.sessionState.intValue == ArenaSessionState.midrun.rawValue {
            if _prevArenaSessionState == .drafting {
                let numCards = arenaInfo.deck.cards.reduce(0, { $0 + $1.count.intValue })
                if numCards == maxDeckSize {
                    if _prevSlot == maxDeckSize {
                        cardPicked(arenaInfo)
                    }
                }
            }
            onCompleteDeck?(self, CompleteDeckEventArgs(info: arenaInfo))
            if arenaInfo.rewards.count > 0 {
                onRewards?(RewardsEventArgs(info: arenaInfo))
            }
            _watch.store(false, ordering: .sequentiallyConsistent)
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
        
        // TODO
//        onChoicesChanged?(ChoicesChangedEventArgs(choices.choices, arenaInfo.deck, arenaInfo.currentSlot, arenaInfo.isUnderground, choices.packages))
        
        // we need to check _prevIsUnderground == arenaInfo.IsUnderground
        // otherwise changing arena mode would trigger Hero/CardPicked
        if _prevSlot == 0 && arenaInfo.currentSlot.intValue == 1 && _prevIsUnderground == arenaInfo.isUnderground {
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
//        let redraftDeck = arenaInfo.redraftDeck
        let redraftSlot = arenaInfo.redraftCurrentSlot.intValue
        
        guard let choices = MirrorHelper.getArenaDraftChoices(), choices.choices.count > 0 else {
            return false
        }
        
        if _prevInfo != nil && redraftSlot <= _prevRedraftSlot && _prevIsUnderground == arenaInfo.isUnderground && _prevChoicesVersion == choices.version.intValue {
            return false
        }
        // TODO
//        onRedraftChoicesChanged?(RedraftChoicesChangedEventArgs(choices.choices, arenaInfo.deck, redraftDeck, redraftSlot, arenaInfo.losses.intValue, arenaInfo.isUnderground))
        
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
        // TODO
    }
    
    private func cardPicked(_ arenaInfo: MirrorArenaInfo) {
        // TODO
    }
    
    private func redraftCardPicked(_ arenaInfo: MirrorArenaInfo) {
        // TODO
    }
    
    private func redraftLastCardPicked(_ arenaInfo: MirrorArenaInfo) {
        // TODO
    }
}
