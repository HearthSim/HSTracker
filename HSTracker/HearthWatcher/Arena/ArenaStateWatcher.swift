//
//  ArenaStateWatcher.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import Atomics

/// A one-to-many callback list.
///
/// Every other watcher in HSTracker exposes a single `change` closure, which is
/// enough when exactly one object cares. The arena state has several independent
/// consumers at once - the pick helper, the pre-draft lobby, and the overlay's own
/// masking - so this watcher needs C#-style multicast events rather than the usual
/// single-assignment closure.
final class ArenaStateEvent<T> {
    private var handlers = [(T) -> Void]()
    private let lock = UnfairLock()

    func subscribe(_ handler: @escaping (T) -> Void) {
        lock.around { handlers.append(handler) }
    }

    func removeAll() {
        lock.around { handlers.removeAll() }
    }

    /// Handlers run on the main queue: they drive `ObservableObject` view models,
    /// and HDT likewise marshals every one of these onto its UI dispatcher.
    fileprivate func raise(_ value: T) {
        let current = lock.around { handlers }
        guard !current.isEmpty else { return }
        DispatchQueue.main.async {
            for handler in current {
                handler(value)
            }
        }
    }
}

struct ArenaDraftChoice: Equatable {
    let index: Int
    let cardId: String
    let packageCardIds: [String]

    init(mirror: MirrorDraftChoice) {
        index = mirror.actor.index.intValue
        cardId = mirror.actor.cardId
        packageCardIds = mirror.packageCardIds
    }
}

struct ArenaActorInfo: Equatable {
    let index: Int
    let cardId: String

    init(mirror: MirrorActorInfo) {
        index = mirror.index.intValue
        cardId = mirror.cardId
    }
}

struct ArenaBigCard: Equatable {
    let positionY: Double

    init(mirror: MirrorBigCardArena) {
        positionY = mirror.positionY.doubleValue
    }
}

struct ArenaClientState: Equatable {
    let clientState: ArenaClientStateType
    let sessionState: ArenaSessionState
}

/// Polls `getArenaState` and publishes the individual changes the Arenasmith
/// overlay reacts to. Port of HDT's `HearthWatcher/ArenaStateWatcher.cs`.
final class ArenaStateWatcher {
    private let delay: TimeInterval

    private var _running = ManagedAtomic<Bool>(false)
    private var _watch = ManagedAtomic<Bool>(false)
    internal var queue: DispatchQueue?

    // Serializes the polling tick against direct `update()` calls, matching the
    // `_updateLock` HDT added for the same reason.
    private let updateLock = UnfairLock()

    let onHeroZoomed = ArenaStateEvent<ArenaActorInfo?>()
    let onIsPackageSelectOpen = ArenaStateEvent<Bool>()
    let onCardHover = ArenaStateEvent<ArenaDraftChoice?>()
    let onScrollChange = ArenaStateEvent<Double>()
    let onDeckListChange = ArenaStateEvent<[MirrorCard]>()
    let onRedraftDeckListChange = ArenaStateEvent<[MirrorCard]>()
    let onChoicesChanged = ArenaStateEvent<[ArenaDraftChoice]>()
    let onClientStateChanged = ArenaStateEvent<ArenaClientState>()
    let onIsAnimatingChanged = ArenaStateEvent<Bool>()
    let onHeroPicked = ArenaStateEvent<String>()
    let onHeroPowerPicked = ArenaStateEvent<String>()
    let onTrayBigCardChanged = ArenaStateEvent<ArenaBigCard?>()
    let onTooltipChanged = ArenaStateEvent<([Float], Int)?>()
    let onIsUndergroundChanged = ArenaStateEvent<Bool>()
    let onArenaSeasonIdChanged = ArenaStateEvent<Int>()
    let onDeckIdChanged = ArenaStateEvent<Int64>()

    private var _choice: ArenaDraftChoice?
    private var _scroll = 0.0
    private var _choices: [ArenaDraftChoice]?
    private var _choicesVersion: Int?
    private var _deckListVersion: Int?
    private var _redraftDeckListVersion: Int?
    private var _hero = ""
    private var _heroPower = ""
    private var _deckId: Int64 = 0
    private var _zoomedHero: ArenaActorInfo?
    private var _isAnimating = false
    private var _isPackageSelectOpen = false
    private var _isUnderground = false
    private var _arenaSeasonId = 0
    private var _trayBigCard: ArenaBigCard?
    private var _clientState = ArenaClientState(clientState: .none, sessionState: .invalid)
    private var _tooltip: ([Float], Int)?

    // The mirror owns the cached Mono handles; all we do from here is tell it when
    // they may have gone stale. HDT nils out its ScryCache at exactly these points.
    private var _resetCache = true
    private var _loggedNilState = false

    init(delay: TimeInterval = 0.016) {
        self.delay = delay
    }

    func run() {
        _watch.store(true, ordering: .sequentiallyConsistent)
        if _running.load(ordering: .sequentiallyConsistent) {
            return
        }
        onLoopStart()
        if queue == nil {
            queue = DispatchQueue(label: "\(type(of: self))", attributes: [])
        }
        if let queue {
            queue.async { [weak self] in
                guard let self else { return }
                Thread.current.name = queue.label
                self.watch()
            }
        }
    }

    func stop() {
        _watch.store(false, ordering: .sequentiallyConsistent)
    }

    private func onLoopStart() {
        updateLock.around {
            _choice = nil
            _scroll = 0
            _choices = nil
            _choicesVersion = nil
            _deckListVersion = nil
            _redraftDeckListVersion = nil
            _hero = ""
            _heroPower = ""
            _deckId = 0
            _zoomedHero = nil
            _isAnimating = false
            _isPackageSelectOpen = false
            _trayBigCard = nil
            _tooltip = nil
            _clientState = ArenaClientState(clientState: .none, sessionState: .invalid)
            _resetCache = true
        }
    }

    private func watch() {
        _running.store(true, ordering: .sequentiallyConsistent)
        while _watch.load(ordering: .sequentiallyConsistent) {
            Thread.sleep(forTimeInterval: delay)
            if !_watch.load(ordering: .sequentiallyConsistent) {
                break
            }
            update()
        }
        updateLock.around { _resetCache = true }
        _running.store(false, ordering: .sequentiallyConsistent)
    }

    func update() {
        updateLock.around { updateCore() }
    }

    //swiftlint:disable cyclomatic_complexity function_body_length
    private func updateCore() {
        guard let state = MirrorHelper.getArenaState(deckListVersion: _deckListVersion,
                                                     redraftDeckListVersion: _redraftDeckListVersion,
                                                     resetCache: _resetCache) else {
            if !_loggedNilState {
                _loggedNilState = true
                logger.debug("getArenaState returned nil - draft screen not loaded yet")
            }
            _resetCache = true
            return
        }
        if _loggedNilState {
            _loggedNilState = false
            logger.debug("getArenaState is live again")
        }
        _resetCache = false

        let clientState = ArenaClientStateType(rawValue: state.clientState.intValue) ?? .none
        let sessionState = ArenaSessionState(rawValue: state.sessionState.intValue) ?? .invalid
        if _clientState.clientState != clientState || _clientState.sessionState != sessionState {
            // The objects the mirror cached hang off the draft screen; a state change
            // can swap them out from under us.
            _resetCache = true
            _clientState = ArenaClientState(clientState: clientState, sessionState: sessionState)
            logger.debug("Arena client state: \(clientState) / \(sessionState)")
            onClientStateChanged.raise(_clientState)
        }

        if _isAnimating != state.isAnimating {
            _isAnimating = state.isAnimating
            onIsAnimatingChanged.raise(_isAnimating)
        }

        if _isUnderground != state.isUnderground {
            // Normal and Underground have entirely separate deck objects.
            _resetCache = true
            _isUnderground = state.isUnderground
            onIsUndergroundChanged.raise(_isUnderground)
        }

        if _arenaSeasonId != state.arenaSeasonId.intValue {
            _arenaSeasonId = state.arenaSeasonId.intValue
            onArenaSeasonIdChanged.raise(_arenaSeasonId)
        }

        if _isPackageSelectOpen != state.isPackageSelectOpen {
            _isPackageSelectOpen = state.isPackageSelectOpen
            onIsPackageSelectOpen.raise(_isPackageSelectOpen)
        }

        let zoomedHero = state.zoomedHero.map { ArenaActorInfo(mirror: $0) }
        if _zoomedHero?.cardId != zoomedHero?.cardId {
            _zoomedHero = zoomedHero
            onHeroZoomed.raise(_zoomedHero)
        }

        if _heroPower != state.chosenHeroPower {
            _heroPower = state.chosenHeroPower
            onHeroPowerPicked.raise(_heroPower)
        }

        if _hero != state.chosenHero {
            _hero = state.chosenHero
            onHeroPicked.raise(_hero)
        }

        if _deckId != state.deckId.int64Value {
            _deckId = state.deckId.int64Value
            onDeckIdChanged.raise(_deckId)
        }

        let bigCard = state.deckListBigCard.map { ArenaBigCard(mirror: $0) }
        if bigCard?.positionY != _trayBigCard?.positionY {
            _trayBigCard = bigCard
            onTrayBigCardChanged.raise(_trayBigCard)
        }

        if abs(state.deckListScroll.doubleValue - _scroll) > 0.001 {
            _scroll = state.deckListScroll.doubleValue
            onScrollChange.raise(_scroll)
        }

        // deckListData is nil when the slot collection's version matches the one we
        // passed in, i.e. nothing changed and the mirror skipped marshalling it.
        if let deckList = state.deckListData {
            _deckListVersion = deckList.version.intValue
            onDeckListChange.raise(deckList.cardIds)
        }

        if let redraftList = state.redraftDeckListData {
            _redraftDeckListVersion = redraftList.version.intValue
            onRedraftDeckListChange.raise(redraftList.cardIds)
        }

        let choices = state.choices.map { ArenaDraftChoice(mirror: $0) }
        if _choices?.count != choices.count || _choicesVersion != state.choicesVersion.intValue {
            // Choices linger in memory outside of drafting (e.g. on the landing
            // screen), so only publish them when the client is actually drafting and
            // the count looks like a real offer.
            let isValidChoiceState = choices.isEmpty || choices.count == 3
            logger.debug("Arena choices changed: \(choices.count) [\(choices.map { $0.cardId }.joined(separator: ", "))] "
                         + "version \(state.choicesVersion.intValue), state \(clientState), "
                         + "publishing: \(clientState.isDrafting && isValidChoiceState)")
            if clientState.isDrafting && isValidChoiceState {
                _choices = choices
                _choicesVersion = state.choicesVersion.intValue
                onChoicesChanged.raise(choices)
            }
        }

        let hovered = state.hoveredChoice.map { ArenaDraftChoice(mirror: $0) }
        if _choice?.cardId != hovered?.cardId || _choice?.index != hovered?.index {
            _choice = hovered
            onCardHover.raise(_choice)
        }

        let tooltipHeights = state.tooltipHeights.map { $0.floatValue }
        let heightsSum = tooltipHeights.reduce(0, +)
        if _tooltip?.1 != _choice?.index || _tooltip?.0.reduce(0, +) != heightsSum {
            _tooltip = _choice == nil ? nil : (tooltipHeights, _choice!.index)
            onTooltipChanged.raise(_tooltip)
        }
    }
    //swiftlint:enable cyclomatic_complexity function_body_length
}
