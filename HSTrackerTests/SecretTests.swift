//
//  SecretTests.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/03/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

class SecretTests: HSTrackerTests {
    private var entityId = 1
    private var game: Game!

    private var gameEntity: Entity!,
    heroPlayer: Entity!,
    heroOpponent: Entity!,
    playerSpell1: Entity!,
    playerSpell2: Entity!,
    playerMinion1: Entity!,
    playerMinion2: Entity!,
    opponentMinion1: Entity!,
    opponentMinion2: Entity!,
    opponentDivineShieldMinion: Entity!,
    secretHunter1: Entity!,
    secretHunter2: Entity!,
    secretMage1: Entity!,
    secretMage2: Entity!,
    secretMage3: Entity!,
    secretPaladin1: Entity!,
    secretPaladin2: Entity!,
    secretRogue1: Entity!,
    secretRogue2: Entity!,
    opponentEntity: Entity!,
    opponentCardInHand1: Entity!

    var database: Database!

    override func setUp() {
        super.setUp()

        database = Database()
        database.loadDatabase(splashscreen: nil, withLanguages: [.enUS])

        game = Game(hearthstoneRunState: HearthstoneRunState(isRunning: false, isActive: false))
        gameEntity = createNewEntity(cardId: "")
        gameEntity.name = "GameEntity"
        heroPlayer = createNewEntity(cardId: "HERO_01");
        heroPlayer[.cardtype] = CardType.hero.rawValue
        heroPlayer[.controller] = heroPlayer.id
        heroPlayer[.mulligan_state] = Mulligan.done.rawValue
        heroPlayer[.player_id] = heroPlayer.id
        heroOpponent = createNewEntity(cardId: "HERO_02");
        heroOpponent[.cardtype] = CardType.hero.rawValue
        heroOpponent[.controller] = heroOpponent.id
        opponentEntity = createNewEntity(cardId: "")
        opponentEntity[.player_id] = heroOpponent.id
        opponentEntity[.mulligan_state] = Mulligan.done.rawValue

        game.entities[0] = gameEntity
        game.entities[1] = heroPlayer
        game.player.id = heroPlayer.id
        game.entities[2] = heroOpponent
        game.opponent.id = heroOpponent.id
        game.entities[3] = opponentEntity

        playerMinion1 = createNewEntity(cardId: "EX1_010")
        playerMinion1[.cardtype] = CardType.minion.rawValue
        playerMinion1[.controller] = heroPlayer.id
        playerMinion2 = createNewEntity(cardId: "EX1_011")
        playerMinion2[.cardtype] = CardType.minion.rawValue
        playerMinion2[.controller] = heroPlayer.id
        opponentMinion1 = createNewEntity(cardId: "EX1_020")
        opponentMinion1[.cardtype] = CardType.minion.rawValue
        opponentMinion1[.controller] = heroOpponent.id
        opponentMinion2 = createNewEntity(cardId: "EX1_021")
        opponentMinion2[.cardtype] = CardType.minion.rawValue
        opponentMinion2[.controller] = heroOpponent.id
        opponentDivineShieldMinion = createNewEntity(cardId: "EX1_008")
        opponentDivineShieldMinion[.cardtype] = CardType.minion.rawValue
        opponentDivineShieldMinion[.controller] = heroOpponent.id
        opponentDivineShieldMinion[.divine_shield] = 1
        playerSpell1 = createNewEntity(cardId: "CS2_029")
        playerSpell1[.cardtype] = CardType.spell.rawValue
        playerSpell1[.card_target] = opponentMinion1.id
        playerSpell1[.controller] = heroPlayer.id
        playerSpell2 = createNewEntity(cardId: "CS2_025")
        playerSpell2[.cardtype] = CardType.spell.rawValue
        playerSpell2[.controller] = heroPlayer.id

        game.entities[4] = playerMinion1
        game.entities[5] = playerMinion2
        game.entities[6] = opponentMinion1
        game.entities[7] = opponentMinion2
        
        opponentCardInHand1 = createNewEntity(cardId: "")
        opponentCardInHand1[.controller] = heroOpponent.id
        opponentCardInHand1[.zone] = Zone.hand.rawValue
        game.entities[opponentCardInHand1.id] = opponentCardInHand1

        secretHunter1 = createNewEntity(cardId: "")
        secretHunter1[.class] = TagClass.hunter.rawValue
        secretHunter1[.secret] = 1
        secretHunter2 = createNewEntity(cardId: "")
        secretHunter2[.class] = TagClass.hunter.rawValue
        secretHunter2[.secret] = 1
        secretMage1 = createNewEntity(cardId: "")
        secretMage1[.class] = TagClass.mage.rawValue
        secretMage1[.secret] = 1
        secretMage2 = createNewEntity(cardId: "")
        secretMage2[.class] = TagClass.mage.rawValue
        secretMage2[.secret] = 1
        secretMage3 = createNewEntity(cardId: "")
        secretMage3[.class] = TagClass.mage.rawValue
        secretMage3[.secret] = 1
        secretPaladin1 = createNewEntity(cardId: "")
        secretPaladin1[.class] = TagClass.paladin.rawValue
        secretPaladin1[.secret] = 1
        secretPaladin2 = createNewEntity(cardId: "")
        secretPaladin2[.class] = TagClass.paladin.rawValue
        secretPaladin2[.secret] = 1
        secretRogue1 = createNewEntity(cardId: "")
        secretRogue1[.class] = TagClass.rogue.rawValue
        secretRogue1[.secret] = 1
        secretRogue2 = createNewEntity(cardId: "")
        secretRogue2[.class] = TagClass.rogue.rawValue
        secretRogue2[.secret] = 1

        game.opponentSecretPlayed(entity: secretHunter1, cardId: "",
                                  from: 0, turn: 0,
                                  fromZone: .hand, otherId: secretHunter1.id)
        game.opponentSecretPlayed(entity: secretMage1, cardId: "",
                                  from: 0, turn: 0,
                                  fromZone: .hand, otherId: secretMage1.id)
        game.opponentSecretPlayed(entity: secretPaladin1, cardId: "",
                                  from: 0, turn: 0,
                                  fromZone: .hand, otherId: secretPaladin1.id)
        game.opponentSecretPlayed(entity: secretRogue1, cardId: "",
                                  from: 0, turn: 0,
                                  fromZone: .hand, otherId: secretRogue1.id)
    }

    override func tearDown() {
        super.tearDown()
    }

    private func createNewEntity(cardId: String) -> Entity {
        let entity = Entity(id: entityId)
        entityId += 1
        entity.cardId = cardId
        return entity
    }

    private func verifySecrets(secretIndex: Int, allSecrets: [String], triggered: [String] = []) {
        let secrets = game.secretsManager?.secrets[secretIndex]
        XCTAssertNotNil(secrets, "Secrets are nil")
        allSecrets.forEach {
            let card = Cards.any(byId: $0)?.name ?? $0
            XCTAssertEqual(secrets?.isExcluded(cardId: $0), triggered.contains($0), "\(card)")
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
        // without minions on board
        playerMinion1[.zone] = Zone.hand.rawValue
        heroPlayer[.health] = 10
        game.secretsManager?.handleAttack(attacker: heroPlayer, defender: heroOpponent)

        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.BearTrap,
                                  CardIds.Secrets.Hunter.ExplosiveTrap,
                                  CardIds.Secrets.Hunter.WanderingMonster])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.IceBarrier])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.NobleSacrifice])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
        
        // with minions on board
        playerMinion1[.zone] = Zone.play.rawValue
        playerMinion2[.zone] = Zone.play.rawValue
        game.secretsManager?.handleAttack(attacker: heroPlayer, defender: heroOpponent)
        
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.BearTrap,
                                  CardIds.Secrets.Hunter.ExplosiveTrap,
                                  CardIds.Secrets.Hunter.Misdirection,
                                  CardIds.Secrets.Hunter.WanderingMonster])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.IceBarrier])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.NobleSacrifice])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }

    func testSingleSecret_MinionToHero_PlayerAttack() {
        // with only one friendly minion on board
        playerMinion1[.zone] = Zone.play.rawValue
        playerMinion1[.health] = 1
        game.secretsManager?.handleAttack(attacker: playerMinion1, defender: heroOpponent)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.BearTrap,
                                  CardIds.Secrets.Hunter.ExplosiveTrap,
                                  CardIds.Secrets.Hunter.FreezingTrap,
                                  CardIds.Secrets.Hunter.Misdirection,
                                  CardIds.Secrets.Hunter.WanderingMonster])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.FlameWard,
                                  CardIds.Secrets.Mage.IceBarrier,
                                  CardIds.Secrets.Mage.Vaporize])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.NobleSacrifice])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
        
        // with more than one friendly minions on board
        playerMinion2[.zone] = Zone.play.rawValue
        game.secretsManager?.handleAttack(attacker: playerMinion1, defender: heroOpponent)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.BearTrap,
                                  CardIds.Secrets.Hunter.ExplosiveTrap,
                                  CardIds.Secrets.Hunter.FreezingTrap,
                                  CardIds.Secrets.Hunter.Misdirection,
                                  CardIds.Secrets.Hunter.WanderingMonster])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.FlameWard,
                                  CardIds.Secrets.Mage.IceBarrier,
                                  CardIds.Secrets.Mage.Vaporize])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.NobleSacrifice])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All,
                      triggered: [CardIds.Secrets.Rogue.SuddenBetrayal])
    }

    func testSingleSecret_HeroToMinion_PlayerAttack() {
        game.secretsManager?.handleAttack(attacker: heroPlayer, defender: opponentMinion1)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.SnakeTrap,
                                  CardIds.Secrets.Hunter.VenomstrikeTrap])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.SplittingImage])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.NobleSacrifice,
                                  CardIds.Secrets.Paladin.AutodefenseMatrix])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }

    func testSingleSecret_MinionToMinion_PlayerAttack() {
        game.secretsManager?.handleAttack(attacker: playerMinion1, defender: opponentMinion1)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.FreezingTrap,
                                  CardIds.Secrets.Hunter.SnakeTrap,
                                  CardIds.Secrets.Hunter.VenomstrikeTrap])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.SplittingImage])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.NobleSacrifice,
                                  CardIds.Secrets.Paladin.AutodefenseMatrix])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }
    
    func testSingleSecret_HeroToDivineShieldMinion_PlayerAttackTest() {
        game.secretsManager?.handleAttack(attacker: heroPlayer, defender: opponentDivineShieldMinion)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.SnakeTrap,
                                  CardIds.Secrets.Hunter.VenomstrikeTrap])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.SplittingImage])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.NobleSacrifice])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }
    
    func testSingleSecret_MinionToDivineShieldMinion_PlayerAttackTest() {
        game.secretsManager?.handleAttack(attacker: playerMinion1, defender: opponentDivineShieldMinion)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.FreezingTrap,
                                  CardIds.Secrets.Hunter.SnakeTrap,
                                  CardIds.Secrets.Hunter.VenomstrikeTrap])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.SplittingImage])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.NobleSacrifice])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
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
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All,
                      triggered: [CardIds.Secrets.Rogue.CheatDeath])
    }

    func testSingleSecret_OneMinionDied() {
        opponentMinion2[.zone] = Zone.play.rawValue
        game.opponentMinionDeath(entity: opponentMinion1, turn: 2)
        
        wait(for: game.secretsManager?.avengeDelay ?? 50 + 2)

        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.Duplicate, CardIds.Secrets.Mage.Effigy])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.Avenge,
                                  CardIds.Secrets.Paladin.Redemption,
                                  CardIds.Secrets.Paladin.GetawayKodo])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All,
                      triggered: [CardIds.Secrets.Rogue.CheatDeath])
    }

    func testSingleSecret_MinionPlayed() {
        game.playerMinionPlayed(entity: playerMinion1)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.Snipe])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.ExplosiveRunes,
                                  CardIds.Secrets.Mage.MirrorEntity,
                                  CardIds.Secrets.Mage.PotionOfPolymorph,
                                  CardIds.Secrets.Mage.FrozenClone])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.Repentance])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }

    func testSingleSecret_OpponentDamage() {
        game.opponentDamage(entity: heroOpponent)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All)
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.EyeForAnEye])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All,
                      triggered: [CardIds.Secrets.Rogue.Evasion])
    }

    func testSingleSecret_MinionTarget_SpellPlayed() {
        game.secretsManager?.handleCardPlayed(entity: playerSpell1)

        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.CatTrick])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.Counterspell,
                                  CardIds.Secrets.Mage.Spellbender,
                                  CardIds.Secrets.Mage.ManaBind])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All)
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }

    func testSingleSecret_NoMinionTarget_SpellPlayed() {
        game.secretsManager?.handleCardPlayed(entity: playerSpell2)

        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.CatTrick])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.Counterspell,
                                  CardIds.Secrets.Mage.ManaBind])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All)
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }
    
    func testSingleSecret_MinionOnBoard_NoMinionTarget_SpellPlayed() {
        opponentMinion1[.zone] = Zone.play.rawValue
        game.secretsManager?.handleCardPlayed(entity: playerSpell2)
        
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.CatTrick])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.Counterspell,
                                  CardIds.Secrets.Mage.ManaBind])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.NeverSurrender])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }

    func testSingleSecret_MinionInPlay_OpponentTurnStart() {
        opponentEntity[.current_player] = 1
        game.turnsInPlayChange(entity: opponentMinion1, turn: 1)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All)
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.CompetitiveSpirit])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }

    func testSingleSecret_NoMinionInPlay_OpponentTurnStart() {
        game.turnsInPlayChange(entity: heroOpponent, turn: 1)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All)
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All)
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }
    
    func testSingleSecret_Retarget_FriendlyHitsFriendly() {
        game.secretsManager?.handleAttack(attacker: playerMinion1, defender: heroPlayer)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All)
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All)
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
        
        game.secretsManager?.handleAttack(attacker: playerMinion1, defender: playerMinion1)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All)
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All)
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }
    
    func testSingleSecret_OpponentAttack_Retarget_OpponentHitsOpponent() {
        game.secretsManager?.handleAttack(attacker: opponentMinion1, defender: heroOpponent)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All)
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All)
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
        
        game.secretsManager?.handleAttack(attacker: opponentMinion1, defender: opponentMinion2)
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All)
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All)
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }
    
    func testMultipleSecrets_MinionToHero_ExplosiveTrapTriggered_MinionDied_PlayerAttackTest() {
        playerMinion1[.zone] = Zone.play.rawValue
        playerMinion1[.health] = -1
        game.secretsManager?.handleAttack(attacker: playerMinion1, defender: heroOpponent)
        
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.ExplosiveTrap,
                                  CardIds.Secrets.Hunter.Misdirection,
                                  CardIds.Secrets.Hunter.WanderingMonster])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.IceBarrier,
                                  CardIds.Secrets.Mage.Vaporize,
                                  CardIds.Secrets.Mage.FlameWard])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.NobleSacrifice])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }
    
    func testMultipleSecrets_MinionPlayed_MinionDied() {
        game.playerMinionPlayed(entity: playerMinion1)
        game.playerMinionDeath(entity: playerMinion1)
        
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.FrozenClone])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All)
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }
    
    func testMultipleSecrets_MinionPlayed_SecretTriggered_MinionDied() {
        game.opponentSecretPlayed(entity: secretMage2, cardId: "", from: 0, turn: 0, fromZone: Zone.hand, otherId: secretMage2.id)
        secretMage2.cardId = CardIds.Secrets.Mage.ExplosiveRunes
        game.playerMinionPlayed(entity: playerMinion1)
        game.opponentSecretTrigger(entity: secretMage2, cardId: "", turn: 2, otherId: secretMage2.id)
        game.playerMinionDeath(entity: playerMinion1)
        
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.ExplosiveRunes,
                                  CardIds.Secrets.Mage.FrozenClone])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All)
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }
    
    func testMultipleSecrets_MinionPlayed_MultipleSecretsTriggered_MinionDied() {
        game.opponentSecretPlayed(entity: secretMage2, cardId: "", from: 0, turn: 0, fromZone: Zone.hand, otherId: secretMage2.id)
        game.opponentSecretPlayed(entity: secretMage3, cardId: "", from: 0, turn: 0, fromZone: Zone.hand, otherId: secretMage3.id)
        secretMage2.cardId = CardIds.Secrets.Mage.PotionOfPolymorph
        secretMage3.cardId = CardIds.Secrets.Mage.ExplosiveRunes
        game.playerMinionPlayed(entity: playerMinion1)
        game.opponentSecretTrigger(entity: secretMage2, cardId: "", turn: 2, otherId: secretMage2.id)
        game.opponentSecretTrigger(entity: secretMage3, cardId: "", turn: 2, otherId: secretMage3.id)
        game.playerMinionDeath(entity: playerMinion1)
        
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All)
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.ExplosiveRunes,
                                  CardIds.Secrets.Mage.FrozenClone,
                                  CardIds.Secrets.Mage.PotionOfPolymorph])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All)
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }
    
    func testMultipleSecrets_MinionPlayed_MinionDiedNextTurn() {
        game.playerMinionPlayed(entity: playerMinion1)
        game.turnStart(player: PlayerType.player, turn: 2)
        wait(for: 2)
        game.playerMinionDeath(entity: playerMinion1)
        
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.Snipe])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.ExplosiveRunes,
                                  CardIds.Secrets.Mage.FrozenClone,
                                  CardIds.Secrets.Mage.MirrorEntity,
                                  CardIds.Secrets.Mage.PotionOfPolymorph])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.Repentance])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }
    
    func testMultipleSecrets_MinionPlayed_AnotherMinionDied() {
        game.playerMinionPlayed(entity: playerMinion1)
        game.playerMinionDeath(entity: playerMinion2)
        
        verifySecrets(secretIndex: 0, allSecrets: CardIds.Secrets.Hunter.All,
                      triggered: [CardIds.Secrets.Hunter.Snipe])
        verifySecrets(secretIndex: 1, allSecrets: CardIds.Secrets.Mage.All,
                      triggered: [CardIds.Secrets.Mage.ExplosiveRunes,
                                  CardIds.Secrets.Mage.FrozenClone,
                                  CardIds.Secrets.Mage.MirrorEntity,
                                  CardIds.Secrets.Mage.PotionOfPolymorph])
        verifySecrets(secretIndex: 2, allSecrets: CardIds.Secrets.Paladin.All,
                      triggered: [CardIds.Secrets.Paladin.Repentance])
        verifySecrets(secretIndex: 3, allSecrets: CardIds.Secrets.Rogue.All)
    }
    
    // TODO: Add test for Rat Trap, Hidden Wisdom, Sacred Trial, etc.
}
