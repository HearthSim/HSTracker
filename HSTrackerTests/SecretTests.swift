//
//  SecretTests.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/03/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

class SecretTests: XCTestCase {

    private var entityId = 0
    private var game: Game!

    private var heroPlayer: Entity!,
    heroOpponent: Entity!,
    playerSpell1: Entity!,
    playerSpell2: Entity!,
    playerMinion1: Entity!,
    opponentMinion1: Entity!,
    opponentMinion2: Entity!,
    secretHunter1: Entity!,
    secretHunter2: Entity!,
    secretMage1: Entity!,
    secretMage2: Entity!,
    secretPaladin1: Entity!,
    secretPaladin2: Entity!,
    opponentEntity: Entity!

    var database: Database!

    override func setUp() {
        super.setUp()

        database = Database()
        database.loadDatabase(splashscreen: nil)

        game = Game(hearthstoneRunState: HearthstoneRunState(isRunning: false, isActive: false))
        heroPlayer = createNewEntity(cardId: "HERO_01");
        heroPlayer[.cardtype] = CardType.hero.rawValue
        heroOpponent = createNewEntity(cardId: "HERO_02");
        heroOpponent[.cardtype] = CardType.hero.rawValue
        heroOpponent[.controller] = heroOpponent.id
        opponentEntity = createNewEntity(cardId: "")
        opponentEntity[.player_id] = heroOpponent.id

        game.entities[0] = heroPlayer
        game.player.id = heroPlayer.id
        game.entities[1] = heroOpponent
        game.opponent.id = heroOpponent.id
        game.entities[5] = opponentEntity

        playerMinion1 = createNewEntity(cardId: "EX1_010")
        playerMinion1[.cardtype] = CardType.minion.rawValue
        playerMinion1[.controller] = heroPlayer.id
        opponentMinion1 = createNewEntity(cardId: "EX1_020")
        opponentMinion1[.cardtype] = CardType.minion.rawValue
        opponentMinion1[.controller] = heroOpponent.id
        opponentMinion2 = createNewEntity(cardId: "EX1_021")
        opponentMinion2[.cardtype] = CardType.minion.rawValue
        opponentMinion2[.controller] = heroOpponent.id
        playerSpell1 = createNewEntity(cardId: "CS2_029")
        playerSpell1[.cardtype] = CardType.spell.rawValue
        playerSpell1[.card_target] = opponentMinion1.id
        playerSpell1[.controller] = heroPlayer.id
        playerSpell2 = createNewEntity(cardId: "CS2_025")
        playerSpell2[.cardtype] = CardType.spell.rawValue
        playerSpell2[.controller] = heroPlayer.id

        game.entities[2] = playerMinion1
        game.entities[3] = opponentMinion1
        game.entities[4] = opponentMinion2

        secretHunter1 = createNewEntity(cardId: "")
        secretHunter1[.class] = TagClass.hunter.rawValue
        secretHunter2 = createNewEntity(cardId: "")
        secretHunter2[.class] = TagClass.hunter.rawValue
        secretMage1 = createNewEntity(cardId: "")
        secretMage1[.class] = TagClass.mage.rawValue
        secretMage2 = createNewEntity(cardId: "")
        secretMage2[.class] = TagClass.mage.rawValue
        secretPaladin1 = createNewEntity(cardId: "")
        secretPaladin1[.class] = TagClass.paladin.rawValue
        secretPaladin2 = createNewEntity(cardId: "")
        secretPaladin2[.class] = TagClass.paladin.rawValue

        game.opponentSecretPlayed(entity: secretHunter1, cardId: "",
                                  from: 0, turn: 0,
                                  fromZone: .hand, otherId: secretHunter1.id)
        game.opponentSecretPlayed(entity: secretMage1, cardId: "",
                                  from: 0, turn: 0,
                                  fromZone: .hand, otherId: secretMage1.id)
        game.opponentSecretPlayed(entity: secretPaladin1, cardId: "",
                                  from: 0, turn: 0,
                                  fromZone: .hand, otherId: secretPaladin1.id)
    }

    override func tearDown() {
        super.tearDown()
    }

    private func createNewEntity(cardId: String) -> Entity {
        let entity = Entity(id: entityId)
        defer { entityId += 1 }
        entity.cardId = cardId
        return entity
    }

    private func verifySecrets(secretIndex: Int, allSecrets: [String], triggered: [String] = []) {
        let secrets = game.opponentSecrets?.secrets[secretIndex]
        XCTAssertNotNil(secrets, "Secrets are nil")
        allSecrets.forEach {
            let card = Cards.any(byId: $0)?.name ?? $0
            XCTAssertEqual(secrets!.possibleSecrets[$0], !triggered.contains($0), "\(card)")
        }
    }

    private func wait(for duration: TimeInterval) {
        let waitExpectation = expectation(description: "Waiting")

        let when = DispatchTime.now() + duration
        DispatchQueue.main.asyncAfter(deadline: when) {
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: duration + 2)
    }

    func testSingleSecret_HeroToHero_PlayerAttack() {
        playerMinion1[.zone] = Zone.hand.rawValue
        game.opponentSecrets?.zeroFromAttack(attacker: heroPlayer, defender: heroOpponent)

        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.BearTrap,
                                  CardIds.Secrets.Hunter.ExplosiveTrap])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.IceBarrier])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.NobleSacrifice])
    }

    func testSingleSecret_MinionToHero_PlayerAttack() {
        playerMinion1[.zone] = Zone.play.rawValue
        game.opponentSecrets?.zeroFromAttack(attacker: playerMinion1, defender: heroOpponent)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.BearTrap,
                                  CardIds.Secrets.Hunter.ExplosiveTrap,
                                  CardIds.Secrets.Hunter.FreezingTrap,
                                  CardIds.Secrets.Hunter.Misdirection])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.IceBarrier,
                                  CardIds.Secrets.Mage.Vaporize])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.NobleSacrifice])
    }

    func testSingleSecret_HeroToMinion_PlayerAttack() {
        game.opponentSecrets?.zeroFromAttack(attacker: heroPlayer, defender: opponentMinion1)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.SnakeTrap])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All)
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.NobleSacrifice])
    }

    func testSingleSecret_MinionToMinion_PlayerAttack() {
        game.opponentSecrets?.zeroFromAttack(attacker: playerMinion1, defender: opponentMinion1)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.FreezingTrap,
                                  CardIds.Secrets.Hunter.SnakeTrap])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All)
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.NobleSacrifice])
    }

    func testSingleSecret_OnlyMinionDied() {
        opponentMinion2[.zone] = Zone.hand.rawValue
        game.opponentMinionDeath(entity: opponentMinion1, turn: 2)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.Duplicate, CardIds.Secrets.Mage.Effigy])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.Redemption,
                                  CardIds.Secrets.Paladin.GetawayKodo])
    }

    func testSingleSecret_OneMinionDied() {
        opponentMinion2[.zone] = Zone.play.rawValue
        game.opponentMinionDeath(entity: opponentMinion1, turn: 2)

        wait(for: 1)

        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.Duplicate, CardIds.Secrets.Mage.Effigy])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.Avenge,
                                  CardIds.Secrets.Paladin.Redemption,
                                  CardIds.Secrets.Paladin.GetawayKodo])
    }

    func testSingleSecret_MinionPlayed() {
        game.playerMinionPlayed()
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.Snipe])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.MirrorEntity,
                                  CardIds.Secrets.Mage.PotionOfPolymorph])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.Repentance])
    }

    func testSingleSecret_OpponentDamage() {
        game.opponentDamage(entity: heroOpponent)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All)
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.EyeForAnEye])
    }

    func testSingleSecret_MinionTarget_SpellPlayed() {
        game.secretsOnPlay(entity: playerSpell1)

        wait(for: 1)

        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.CatTrick])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.Counterspell,
                                  CardIds.Secrets.Mage.Spellbender])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All)
    }

    func testSingleSecret_NoMinionTarget_SpellPlayed() {
        game.secretsOnPlay(entity: playerSpell2)

        wait(for: 1)

        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.CatTrick])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.Counterspell])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All)
    }

    func testSingleSecret_MinionInPlay_OpponentTurnStart() {
        opponentEntity[.current_player] = 1
        game.turnsInPlayChange(entity: opponentMinion1, turn: 1)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All)
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.CompetitiveSpirit])
    }

    func testSingleSecret_NoMinionInPlay_OpponentTurnStart() {
        game.turnsInPlayChange(entity: heroOpponent, turn: 1)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All)
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All)
    }
}
