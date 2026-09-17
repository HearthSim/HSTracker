//
//  GodfreyOverdrawnTests.swift
//  HSTrackerTests
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

/// The bookkeeping behind the Overdrawn lens - HDT's `Player.GodfreyCards` and the
/// four methods around it.
///
/// Godfrey's Atlas burns a card the player overdraws into the void instead of
/// destroying it. Each burn reaches HSTracker as two separate log events: the
/// enchantment's TRIGGER_VISUAL block creates a new, hidden entity in the void,
/// and the BURNED_CARD metadata that follows names the entity it was copied from.
/// Only the second carries a card id, so only it is worth listing.
class GodfreyOverdrawnTests: HSTrackerTests {

    static var database: Database!

    override class func setUp() {
        super.setUp()
        database = Database()
        database.loadDatabase(splashscreen: nil, withLanguages: [.enUS])
    }

    private var game: Game!
    private var nextEntityId = 10

    override func setUp() {
        super.setUp()
        game = Game(hearthstoneRunState: HearthstoneRunState(isRunning: false, isActive: false))

        let heroPlayer = entity(cardId: "HERO_01")
        heroPlayer[.player_id] = heroPlayer.id
        let heroOpponent = entity(cardId: "HERO_02")
        game.entities[heroPlayer.id] = heroPlayer
        game.entities[heroOpponent.id] = heroOpponent
        game.player.id = heroPlayer.id
        game.opponent.id = heroOpponent.id
    }

    @discardableResult
    private func entity(cardId: String) -> Entity {
        let e = Entity(id: nextEntityId)
        nextEntityId += 1
        e.cardId = cardId
        game.entities[e.id] = e
        return e
    }

    /// A burn, then the metadata naming what it copied: the two pair up, and the
    /// copied entity is what the lens lists.
    func testBurnPairsWithTheCopiedEntity() {
        let void = entity(cardId: "")
        let copied = entity(cardId: "EX1_012")

        game.opponent.addGodfreyNewEntityId(void.id)
        game.opponent.addGodfreyCopiedEntityId(copied.id)

        XCTAssertEqual(game.opponent.godfreyCards.count, 1)
        XCTAssertEqual(game.opponent.getGodfreyCardIdsToDisplay(), [copied.id])
    }

    /// A burn with no metadata yet has nothing to show - the void entity is hidden,
    /// so listing it would show a blank row.
    func testBurnWithoutACopiedEntityShowsNothing() {
        let void = entity(cardId: "")
        game.opponent.addGodfreyNewEntityId(void.id)

        XCTAssertEqual(game.opponent.godfreyCards.count, 1)
        XCTAssertTrue(game.opponent.getGodfreyCardIdsToDisplay().isEmpty)
    }

    /// Copies arriving with no pending burn start their own entries rather than
    /// piling onto one.
    func testCopiesWithoutABurnStartTheirOwnEntries() {
        let first = entity(cardId: "EX1_012")
        let second = entity(cardId: "CS2_234")

        game.opponent.addGodfreyCopiedEntityId(first.id)
        game.opponent.addGodfreyCopiedEntityId(second.id)

        XCTAssertEqual(game.opponent.getGodfreyCardIdsToDisplay(), [first.id, second.id])
    }

    /// Two burns then two copies pair up in order.
    func testMultipleBurnsPairInOrder() {
        let voidA = entity(cardId: ""), voidB = entity(cardId: "")
        let copiedA = entity(cardId: "EX1_012"), copiedB = entity(cardId: "CS2_234")

        game.opponent.addGodfreyNewEntityId(voidA.id)
        game.opponent.addGodfreyNewEntityId(voidB.id)
        game.opponent.addGodfreyCopiedEntityId(copiedA.id)
        game.opponent.addGodfreyCopiedEntityId(copiedB.id)

        XCTAssertEqual(game.opponent.godfreyCards.map { $0.newEntityId }, [voidA.id, voidB.id])
        XCTAssertEqual(game.opponent.godfreyCards.map { $0.copiedEntityId }, [copiedA.id, copiedB.id])
    }

    /// Your own card leaving the void is yours to see, so it goes immediately.
    func testYourOwnReturnedCardLeavesTheVoidAtOnce() {
        let void = entity(cardId: "")
        let copied = entity(cardId: "EX1_012")
        game.player.addGodfreyNewEntityId(void.id)
        game.player.addGodfreyCopiedEntityId(copied.id)

        game.player.returnGodfreyCard(newEntityId: void.id, copiedEntityId: copied.id)

        XCTAssertTrue(game.player.godfreyCards.isEmpty)
        XCTAssertTrue(game.player.getGodfreyCardIdsToDisplay().isEmpty)
    }

    /// The opponent's returned entity is not revealed, so with more than one
    /// candidate every one keeps showing - the user must not learn which left.
    func testOpponentsReturnKeepsAmbiguousCandidatesListed() {
        let voidA = entity(cardId: ""), voidB = entity(cardId: "")
        let copiedA = entity(cardId: "EX1_012"), copiedB = entity(cardId: "CS2_234")
        game.opponent.addGodfreyNewEntityId(voidA.id)
        game.opponent.addGodfreyCopiedEntityId(copiedA.id)
        game.opponent.addGodfreyNewEntityId(voidB.id)
        game.opponent.addGodfreyCopiedEntityId(copiedB.id)

        game.opponent.returnGodfreyCard(newEntityId: voidA.id, copiedEntityId: copiedA.id)

        XCTAssertEqual(game.opponent.godfreyCards.count, 2)
        XCTAssertEqual(Set(game.opponent.getGodfreyCardIdsToDisplay()), [copiedA.id, copiedB.id])
        XCTAssertTrue(game.opponent.godfreyCards[0].returnedToHand)
    }

    /// Once the returned entity is revealed, the candidate it resolved to is
    /// dropped and the rest keep showing.
    func testRevealedReturnedEntityIsPruned() {
        let voidA = entity(cardId: ""), voidB = entity(cardId: "")
        let copiedA = entity(cardId: "EX1_012"), copiedB = entity(cardId: "CS2_234")
        game.opponent.addGodfreyNewEntityId(voidA.id)
        game.opponent.addGodfreyCopiedEntityId(copiedA.id)
        game.opponent.addGodfreyNewEntityId(voidB.id)
        game.opponent.addGodfreyCopiedEntityId(copiedB.id)
        game.opponent.returnGodfreyCard(newEntityId: voidA.id, copiedEntityId: copiedA.id)

        // Hearthstone reveals what came back.
        voidA.cardId = "EX1_012"

        XCTAssertEqual(game.opponent.getGodfreyCardIdsToDisplay(), [copiedB.id])
    }

    /// A lone remaining candidate is no longer ambiguous, so it resolves: the void
    /// entity takes the copied card's id and stops being hidden.
    func testSingleRemainingCandidateResolves() {
        let void = entity(cardId: "")
        let copied = entity(cardId: "EX1_012")
        void.info.hidden = true
        game.opponent.addGodfreyNewEntityId(void.id)
        game.opponent.addGodfreyCopiedEntityId(copied.id)

        game.opponent.returnGodfreyCard(newEntityId: void.id, copiedEntityId: copied.id)

        XCTAssertTrue(game.opponent.godfreyCards.isEmpty)
        XCTAssertEqual(void.cardId, "EX1_012")
        XCTAssertFalse(void.info.hidden)
        XCTAssertEqual(void.info.guessedCardState, .guessed)
        XCTAssertEqual(void.info.costReduction, 1)
    }

    /// When every remaining candidate has gone back to hand the void is empty,
    /// whatever has been revealed.
    func testVoidEmptiesWhenEveryCandidateHasReturned() {
        let voidA = entity(cardId: ""), voidB = entity(cardId: "")
        let copiedA = entity(cardId: "EX1_012"), copiedB = entity(cardId: "CS2_234")
        game.opponent.addGodfreyNewEntityId(voidA.id)
        game.opponent.addGodfreyCopiedEntityId(copiedA.id)
        game.opponent.addGodfreyNewEntityId(voidB.id)
        game.opponent.addGodfreyCopiedEntityId(copiedB.id)

        game.opponent.returnGodfreyCard(newEntityId: voidA.id, copiedEntityId: copiedA.id)
        game.opponent.returnGodfreyCard(newEntityId: voidB.id, copiedEntityId: copiedB.id)

        XCTAssertTrue(game.opponent.getGodfreyCardIdsToDisplay().isEmpty)
        XCTAssertTrue(game.opponent.godfreyCards.isEmpty)
    }

    /// A return naming an entity the void never held changes nothing.
    func testUnknownReturnIsIgnored() {
        let void = entity(cardId: "")
        let copied = entity(cardId: "EX1_012")
        game.opponent.addGodfreyNewEntityId(void.id)
        game.opponent.addGodfreyCopiedEntityId(copied.id)

        game.opponent.returnGodfreyCard(newEntityId: 999, copiedEntityId: 998)

        XCTAssertEqual(game.opponent.getGodfreyCardIdsToDisplay(), [copied.id])
    }

    /// Resetting the player empties the void, so it does not leak into the next game.
    func testResetClearsTheVoid() {
        let void = entity(cardId: "")
        let copied = entity(cardId: "EX1_012")
        game.opponent.addGodfreyNewEntityId(void.id)
        game.opponent.addGodfreyCopiedEntityId(copied.id)

        game.opponent.reset()

        XCTAssertTrue(game.opponent.godfreyCards.isEmpty)
    }
}
