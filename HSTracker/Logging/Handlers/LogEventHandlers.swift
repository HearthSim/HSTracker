//
//  EventHandlers.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 28/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol PowerEventHandler: class {
	
	// TODO: should absolutely be removed
	func blockStart()
	func blockEnd()
	
	// TODO: remove set on most properties to ensure encapsulation
	var entities: [Int: Entity] { get set }
	var tmpEntities: [Entity] { get set }
	
	func add(entity: Entity)
	
	func set(currentEntity id: Int)
	func set(playerHero cardId: String)
	func set(opponentHero cardId: String)
	func set(activeDeckId: String?, autoDetected: Bool)
	
	var player: Player! { get set }
	var opponent: Player! { get set }
	
	var currentMode: Mode? { get set }
	
	func proposeKeyPoint(type: KeyPointType, id: Int, player: PlayerType)
	var proposedKeyPoint: ReplayKeyPoint? { get set }
	
	var gameTriggerCount: Int { get set }
	
	var lastId: Int { get set }
	
	var knownCardIds: [Int: [String]] { get set }
	
	var currentEntityHasCardId: Bool { get set }
	
	func resetCurrentEntity()
	
	var currentEntityId: Int { get set }
	var currentEntityZone: Zone { get set }
	
	var currentBlock: Block? { get }
	
	func gameEndKeyPoint(victory: Bool, id: Int)
	
	func determinedPlayers() -> Bool
	
	func setArenaOptions(cards: [Card])
	
	var wasInProgress: Bool { get set }
	
	var lastCardPlayed: Int? { get set }
	
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
	
	var opponentSecrets: OpponentSecrets? { get set }
	
	var playerEntity: Entity? { get }
	
	var opponentEntity: Entity? { get }
	
	var gameEntity: Entity? { get }
	
	var isMinionInPlay: Bool { get }
	
	var isInMenu: Bool { get set }
	
	var isOpponentMinionInPlay: Bool { get }
	
	var opponentMinionCount: Int { get }
	
	var playerMinionCount: Int { get }
	
	func playerMinionPlayed()
	
	func opponentDamage(entity: Entity)
	
	func turnsInPlayChange(entity: Entity, turn: Int)
	
	func turnNumber() -> Int
	
	func playerFatigue(value: Int)
	
	func playerHeroPower(cardId: String, turn: Int)
	
	func playerPlay(entity: Entity, cardId: String?, turn: Int)
	
	func playerGet(entity: Entity, cardId: String?, turn: Int)
	
	func playerRemoveFromDeck(entity: Entity, turn: Int)
	
	func playerDeckDiscard(entity: Entity, cardId: String?, turn: Int)
	
	func playerHandDiscard(entity: Entity, cardId: String?, turn: Int)
	
	func playerDeckToPlay(entity: Entity, cardId: String?, turn: Int)
	
	func playerPlayToGraveyard(entity: Entity, cardId: String?, turn: Int)
	
	func playerJoust(entity: Entity, cardId: String?, turn: Int)
	
	func playerGetToDeck(entity: Entity, cardId: String?, turn: Int)
	
	func playerCreateInPlay(entity: Entity, cardId: String?, turn: Int)
	
	func playerStolen(entity: Entity, cardId: String?, turn: Int)
	
	func playerSecretPlayed(entity: Entity, cardId: String?, turn: Int, fromZone: Zone)
	
	func playerBackToHand(entity: Entity, cardId: String?, turn: Int)
	
	func playerPlayToDeck(entity: Entity, cardId: String?, turn: Int)
	
	func playerMulligan(entity: Entity, cardId: String?)
	
	func playerDraw(entity: Entity, cardId: String?, turn: Int)
	
	func playerCreateInSetAside(entity: Entity, turn: Int)
	
	func playerRemoveFromPlay(entity: Entity, turn: Int)
	
	func opponentGet(entity: Entity, turn: Int, id: Int)
	
	func opponentPlayToHand(entity: Entity, cardId: String?, turn: Int, id: Int)
	
	func opponentPlayToDeck(entity: Entity, cardId: String?, turn: Int)
	
	func opponentPlay(entity: Entity, cardId: String?, from: Int, turn: Int)
	
	func opponentHandDiscard(entity: Entity, cardId: String?, from: Int, turn: Int)
	
	func opponentSecretPlayed(entity: Entity, cardId: String?,
	                          from: Int, turn: Int,
	                          fromZone: Zone, otherId: Int)
	
	func opponentMulligan(entity: Entity, from: Int)
	
	func opponentDraw(entity: Entity, turn: Int)
	
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
}
