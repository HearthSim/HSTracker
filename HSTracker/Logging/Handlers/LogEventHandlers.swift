//
//  EventHandlers.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 28/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol PowerEventHandler: AnyObject {
    
    var proposedAttackerEntityId: Int { get set }
    var proposedDefenderEntityId: Int { get set }
    
    // TODO: remove set on most properties to ensure encapsulation
    var entities: SynchronizedDictionary<Int, Entity> { get }
    var tmpEntities: SynchronizedArray<Entity> { get set }
    
    func add(entity: Entity)
    
    func set(playerHero cardId: String)
    func set(opponentHero cardId: String)
    func set(activeDeckId: String?, autoDetected: Bool)
    func set(activeDeck: Deck, autoDetected: Bool)
    func set(buildNumber: Int)
    func add(playerName: String, for ID: Int)
    func playerName(for ID: Int) -> String?
    
    var player: Player! { get set }
    var opponent: Player! { get set }
    
    var currentMode: Mode? { get set }
    var currentGameMode: GameMode { get }
    
    var gameTriggerCount: Int { get set }
    
    var lastId: Int { get set }
    
    // swiftlint:disable large_tuple
    var knownCardIds: SynchronizedDictionary<Int, [(String, DeckLocation, String?, EntityInfo?)]> { get set }
    // swiftlint:enable large_tuple

	var currentEntityHasCardId: Bool { get set }
	
	var currentEntityZone: Zone { get set }
	
	func determinedPlayers() -> Bool
	
	var wasInProgress: Bool { get set }
	
	var lastCardPlayed: Int { get set }
    
    var lastEntityChosenOnDiscover: Int { get set }
	
	var playerUsedHeroPower: Bool { get set }
	
	var opponentUsedHeroPower: Bool { get set }
	
	var gameEnded: Bool { get set }
	
	func gameStart(at timestamp: LogDate)
	
	func gameEnd()
	
	func concede()
	
	func win()
	
	func loss()
	
	func tied()
	
	var setupDone: Bool { get set }
	
	var joustReveals: Int { get set }
	
	func defending(entity: Entity?)
	
	func attacking(entity: Entity?)
		
	var playerEntity: Entity? { get }
	
	var opponentEntity: Entity? { get }
	
	var gameEntity: Entity? { get }
	
	var isMinionInPlay: Bool { get }
	
	var isInMenu: Bool { get set }
	
	var isOpponentMinionInPlay: Bool { get }
	
	var opponentMinionCount: Int { get }
	
	var playerMinionCount: Int { get }
	
    func playerMinionPlayed(entity: Entity)
    
    func playerMinionDeath(entity: Entity)
    
    func entityPredamage(entity: Entity, damage: Int)
    
    func entityDamage(dealer: Entity, entity: Entity, damage: Int)
    
    func handleChameleosReveal(cardId: String)
    
    func handleCardCopy()
    
    func turnsInPlayChange(entity: Entity, turn: Int)
    
    func turnNumber() -> Int
    
    func turn() -> Int
    
    func handleBeginMulligan()
    
    @available(macOS 10.15.0, *)
    func handlePlayerMulliganDone() async
    
    func playerFatigue(value: Int)
    
    func playerHeroPower(cardId: String, turn: Int)
    
    func playerPlay(entity: Entity, cardId: String?, turn: Int, parentCardId: String)
    
    func playerGet(entity: Entity, cardId: String?, turn: Int)
    
    func playerRemoveFromDeck(entity: Entity, turn: Int)
    
    func playerDeckDiscard(entity: Entity, cardId: String?, turn: Int)
    
    func playerHandDiscard(entity: Entity, cardId: String?, turn: Int)
    
    func playerDeckToPlay(entity: Entity, cardId: String?, turn: Int)
    
    func playerPlayToGraveyard(entity: Entity, cardId: String?, turn: Int, playersTurn: Bool)
    
    func playerJoust(entity: Entity, cardId: String?, turn: Int)
    
    func playerGetToDeck(entity: Entity, cardId: String?, turn: Int)
    
    func playerCreateInPlay(entity: Entity, cardId: String?, turn: Int)
    
    func playerStolen(entity: Entity, cardId: String?, turn: Int)
    
    func playerSecretPlayed(entity: Entity, cardId: String?, turn: Int, fromZone: Zone, parentCardId: String)
    
    func playerSecretTrigger(entity: Entity, cardId: String?, turn: Int, otherId: Int)
    
    func playerBackToHand(entity: Entity, cardId: String?, turn: Int)
    
    func playerPlayToDeck(entity: Entity, cardId: String?, turn: Int)
    
    func playerMulligan(entity: Entity, cardId: String?)
    
    func playerDraw(entity: Entity, cardId: String?, turn: Int)
    
    func playerCreateInSetAside(entity: Entity, turn: Int)
    
    func playerRemoveFromPlay(entity: Entity, turn: Int)
    
    func opponentGet(entity: Entity, turn: Int, id: Int)
    
    func opponentHandToDeck(entity: Entity, cardId: String?, turn: Int)
	
	func opponentPlayToHand(entity: Entity, cardId: String?, turn: Int, id: Int)
	
	func opponentPlayToDeck(entity: Entity, cardId: String?, turn: Int)
	
	func opponentPlay(entity: Entity, cardId: String?, from: Int, turn: Int)
	
	func opponentHandDiscard(entity: Entity, cardId: String?, from: Int, turn: Int)
	
	func opponentSecretPlayed(entity: Entity, cardId: String?, from: Int, turn: Int, fromZone: Zone, otherId: Int, creatorId: Int?)
	
	func opponentMulligan(entity: Entity, from: Int)
	
    func opponentDraw(entity: Entity, turn: Int, cardId: String, drawerId: Int?)
    
    func opponentRemoveFromDeck(entity: Entity, turn: Int)
    
    func opponentDeckDiscard(entity: Entity, cardId: String?, turn: Int)
    
    func opponentDeckToPlay(entity: Entity, cardId: String?, turn: Int)
    
    func opponentPlayToGraveyard(entity: Entity, cardId: String?,
                                 turn: Int, playersTurn: Bool)
    
    func opponentJoust(entity: Entity, cardId: String?, turn: Int)
    
    func opponentGetToDeck(entity: Entity, turn: Int)
    
    func opponentSecretTrigger(entity: Entity, cardId: String?, turn: Int, otherId: Int)
    
    func opponentFatigue(value: Int)
    
    func opponentCreateInPlay(entity: Entity, cardId: String?, turn: Int)
    
    func opponentStolen(entity: Entity, cardId: String?, turn: Int)
    
    func opponentRemoveFromPlay(entity: Entity, turn: Int)
    
    func opponentCreateInSetAside(entity: Entity, turn: Int)
    
    func opponentHeroPower(cardId: String, turn: Int)
    
    func snapshotBattlegroundsBoardState()
    
    var chameleosReveal: (Int, String)? { get set }
    
    func handlePlayerTechLevel(entity: Entity, techLevel: Int)
    
    func handlePlayerTriples(entity: Entity, triples: Int)
    
    func handlePlayerBuddiesGained(entity: Entity, num: Int)
    
    func handlePlayerHeroPowerQuestRewardDatabaseId(entity: Entity, num: Int)
    func handlePlayerHeroPowerQuestRewardCompleted(entity: Entity, num: Int)
    func handlePlayerHeroQuestRewardDatabaseId(entity: Entity, num: Int)
    func handlePlayerHeroQuestRewardCompleted(entity: Entity, num: Int)
    
    func handlePlayerLibramReduction(change: Int)
    
    func handleOpponentLibramReduction(change: Int)
    
    func handlePlayerAbyssalCurse(value: Int)
    
    func handleOpponentAbyssalCurse(value: Int)
    
    func handlePlayerHandCostReduction(value: Int)
    
    func handleOpponentHandCostReduction(value: Int)
    
    func handleEntityLostArmor(entity: Entity, value: Int)
    
    func handleMercenariesStateChange()
    
    func handleProposedAttackerChange(entity: Entity)
    
    func handlePlayerDredge()
    
    func handlePlayerUnknownCardAddedToDeck()
    
    var dredgeCounter: Int { get set }
    
    func handleOpponentSecretRemove(entity: Entity, cardId: String?, turn: Int)
    
    func handleQuestRewardDatabaseId(id: Int, value: Int)
    
    var gameId: String { get }
    
    var lastPlagueDrawn: Stack<String> { get }
    
    func isBattlegroundsSoloMatch() -> Bool
    
    func isBattlegroundsDuosMatch() -> Bool
    
    var isTraditionalHearthstoneMatch: Bool { get }
    
    func duosResetHeroTracking()
    
    func duosSetHeroModified(_ isPlayer: Bool)
    
    var duosWasOpponentHeroModified: Bool { get }
    
    var triangulatePlayed: Bool { get set }
    
    func handleBattlegroundsHeroReroll(entity: Entity, oldCardId: String?)
    
    var starshipLaunchBlockIds: SynchronizedArray<Int?> { get }
    
    var minionsInPlay: SynchronizedArray<String> { get }
    
    var minionsInPlayByPlayer: SynchronizedDictionary<Int, SynchronizedArray<String>> { get }
    
    func handlePlayerHandToPlay(entity: Entity, cardId: String?, turn: Int)
    
    func handleOpponentHandToPlay(entity: Entity, cardId: String?, turn: Int)
    
    func handlePlayerHandToDeck(entity: Entity, cardId: String?)
    
    var isBattlegroundsCombatPhase: Bool { get set }

    func handlePlayerMaxHealthChange(_ value: Int)
    func handleOpponentMaxHealthChange(_ value: Int)
    func handlePlayerMaxManaChange(_ value: Int)
    func handleOpponentMaxManaChange(_ value: Int)
    func handlePlayerMaxHandSizeChange(_ value: Int)
    func handleOpponentMaxHandSizeChange(_ value: Int)
    func handleOpponentCorpsesLeftChange(_ value: Int)
}
