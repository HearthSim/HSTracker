//
//  RewoundEntityCreationFilterTests.swift
//  HSTrackerTests
//

import XCTest

@testable import HSTracker

final class RewoundEntityCreationFilterTests: XCTestCase {
    private var filter: RewoundEntityCreationFilter!

    override func setUp() {
        super.setUp()
        filter = RewoundEntityCreationFilter()
    }

    private func power(_ content: String) -> LogLine {
        return LogLine(namespace: .power, line: "D 14:04:05.1234567 " + content)
    }

    private func keptLines(_ contents: String...) -> [String] {
        return contents.filter { filter.keepInPowerLog(power($0)) }
    }

    func testKeepsEntityCreationWithItsTags() {
        let result = keptLines(
            "GameState.DebugPrintPower() -         FULL_ENTITY - Creating ID=221 CardID=",
            "GameState.DebugPrintPower() -             tag=ZONE value=HAND",
            "GameState.DebugPrintPower() -             tag=CONTROLLER value=2",
            "GameState.DebugPrintPower() -             tag=ENTITY_ID value=221",
            "GameState.DebugPrintPower() -             tag=ZONE_POSITION value=7"
        )

        XCTAssertEqual(5, result.count)
    }

    func testDropsTheRewoundPlayBlock() {
        let result = keptLines(
            "GameState.DebugPrintPower() - BLOCK_START BlockType=PLAY Entity=[id=122 zone=HAND cardId= player=2] EffectIndex=0 Target=0 SubOption=-1",
            "GameState.DebugPrintPower() -     TAG_CHANGE Entity=McBanterFace#1422 tag=RESOURCES_USED value=4",
            "GameState.DebugPrintPower() - BLOCK_END"
        )

        XCTAssertEqual(0, result.count)
    }

    func testDropsTagsThatDoNotBelongToACreation() {
        let result = keptLines(
            "GameState.DebugPrintPower() -     SHOW_ENTITY - Updating Entity=218 CardID=MEND_504e",
            "GameState.DebugPrintPower() -         tag=CARDTYPE value=ENCHANTMENT"
        )

        XCTAssertEqual(0, result.count)
    }

    func testStopsKeepingTagsOnceTheCreationEnded() {
        let result = keptLines(
            "GameState.DebugPrintPower() -     FULL_ENTITY - Creating ID=221 CardID=",
            "GameState.DebugPrintPower() -         tag=ZONE value=HAND",
            "GameState.DebugPrintPower() -     TAG_CHANGE Entity=221 tag=ZONE_POSITION value=7",
            "GameState.DebugPrintPower() -         tag=CARDTYPE value=MINION"
        )

        XCTAssertEqual([
            "GameState.DebugPrintPower() -     FULL_ENTITY - Creating ID=221 CardID=",
            "GameState.DebugPrintPower() -         tag=ZONE value=HAND"
        ], result)
    }

    func testDropsTagsIndentedAtOrAboveTheCreation() {
        let result = keptLines(
            "GameState.DebugPrintPower() -         FULL_ENTITY - Creating ID=221 CardID=",
            "GameState.DebugPrintPower() -         tag=ZONE value=HAND",
            "GameState.DebugPrintPower() -     tag=CONTROLLER value=2"
        )

        XCTAssertEqual(1, result.count)
    }

    func testKeepsConsecutiveCreations() {
        let result = keptLines(
            "GameState.DebugPrintPower() -     FULL_ENTITY - Creating ID=221 CardID=",
            "GameState.DebugPrintPower() -         tag=ZONE value=HAND",
            "GameState.DebugPrintPower() -     FULL_ENTITY - Creating ID=222 CardID=",
            "GameState.DebugPrintPower() -         tag=ZONE value=PLAY"
        )

        XCTAssertEqual(4, result.count)
    }

    func testDropsNonGameStateAndNonPowerLines() {
        XCTAssertFalse(filter.keepInPowerLog(
            power("PowerTaskList.DebugPrintPower() -     FULL_ENTITY - Creating ID=221 CardID=")))
        XCTAssertFalse(filter.keepInPowerLog(
            LogLine(namespace: .loadingScreen, line: "D 14:04:05.1234567 LoadingScreen.OnSceneLoaded() - prevMode=GAMEPLAY")))
    }

    func testResetForgetsAnOpenCreation() {
        XCTAssertTrue(filter.keepInPowerLog(
            power("GameState.DebugPrintPower() -     FULL_ENTITY - Creating ID=221 CardID=")))

        filter.reset()

        XCTAssertFalse(filter.keepInPowerLog(
            power("GameState.DebugPrintPower() -         tag=ZONE value=HAND")))
    }
}
