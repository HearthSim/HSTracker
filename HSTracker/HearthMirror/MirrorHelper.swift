//
//  MirrorHelper.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 23/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import HearthMirror
import CleanroomLogger

/**
 * MirrorHelper takes care of all Mirror-related activities
 */
struct MirrorHelper {
	
	private static var _mirror: HearthMirror?
	private static var _waitingForMirror = false
	
	static func initMirror(pid: Int32, blocking: Bool) {
		
		// get rights to attach
		if acquireTaskportRight() != 0 {
			Log.error?.message("acquireTaskportRight() failed!")
		}
		
		self._mirror = HearthMirror(pid: pid,
		                           blocking: true)
		
		// waiting for mirror to be up and running
		_waitingForMirror = true
		while _waitingForMirror {
			if let battleTag = self._mirror?.getBattleTag() {
				Log.verbose?.message("Getting BattleTag from HearthMirror : \(battleTag)")
				_waitingForMirror = false
				break
			} else {
				// mirror might be partially initialized, reset
				_mirror = HearthMirror(pid: pid,
				                           blocking: true)
				Thread.sleep(forTimeInterval: 0.5)
			}
		}
	}
	
	/**
	 * De-initializes the current mirror object, thus any further mirror calls will fail until the next initMirror
	 */
	static func destroy() {
		_waitingForMirror = false
		_mirror = nil
	}
	
	// MARK: - get player decks
	
	static func getDecks() -> [MirrorDeck]? {
		return _mirror?.getDecks()
	}
	
	static func getSelectedDeck() -> Int64? {
		return _mirror?.getSelectedDeck() as Int64?
	}
	
	static func getArenaDeck() -> MirrorArenaInfo? {
		return _mirror?.getArenaDeck()
	}
	
	static func getEditedDeck() -> MirrorDeck? {
		return _mirror?.getEditedDeck()
	}
	
	// MARK: - card collection
	
	static func getCardCollection() -> [MirrorCard]? {
		return _mirror?.getCardCollection()
	}
	
	// MARK: - game mode
	static func isSpectating() -> Bool? {
		return _mirror?.isSpectating()
	}
	
	static func getGameType() -> Int? {
		return _mirror?.getGameType() as Int?
	}
	
	static func getMatchInfo() -> MirrorMatchInfo? {
		return _mirror?.getMatchInfo()
	}
	
	static func getFormat() -> Int? {
		return _mirror?.getFormat() as Int?
	}
	
	static func getGameServerInfo() -> MirrorGameServerInfo? {
		return _mirror?.getGameServerInfo()
	}
	
	// MARK: - arena
	
	static func getArenaDraftChoices() -> [MirrorCard]? {
		return _mirror?.getArenaDraftChoices()
	}
	
	// MARK: - brawl
	
	static func getBrawlInfo() -> MirrorBrawlInfo? {
		return _mirror?.getBrawlInfo()
	}
	
}
