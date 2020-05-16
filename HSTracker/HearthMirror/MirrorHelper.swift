//
//  MirrorHelper.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 23/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import HearthMirror

/**
 * MirrorHelper takes care of all Mirror-related activities
 */
struct MirrorHelper {
    
    /** Internal represenation of the mirror object, do not access it directly */
    private static var _mirror: HearthMirror?
    
    private static let accessQueue = DispatchQueue(label: "net.hearthsim.hstracker.mirrorQueue", attributes: [])
	
    private static var mirror: HearthMirror? {
        
        if MirrorHelper._mirror == nil {
            // disable until we can fix memory reading
            if false, let hsApp = CoreManager.hearthstoneApp {
                logger.verbose("Initializing HearthMirror with pid \(hsApp.processIdentifier)")
                
                MirrorHelper._mirror = MirrorHelper.initMirror(pid: hsApp.processIdentifier, blocking: false)
            } else {
                //logger.error("Failed to initialize HearthMirror: game is not running")
            }
        }
        
        return MirrorHelper._mirror
    }
    
	private static func initMirror(pid: Int32, blocking: Bool) -> HearthMirror {
        
		// get rights to attach
		if acquireTaskportRight() != 0 {
			logger.error("acquireTaskportRight() failed!")
		}
		
		var mirror = HearthMirror(pid: pid,
		                           blocking: true)
		
		// waiting for mirror to be up and running
		var _waitingForMirror = true
		while _waitingForMirror {
			if let battleTag = mirror.getBattleTag() {
				logger.verbose("Getting BattleTag from HearthMirror : \(battleTag)")
				_waitingForMirror = false
				break
			} else {
				// mirror might be partially initialized, reset
                logger.error("Mirror is not working, trying again...")
				mirror = HearthMirror(pid: pid,
				                           blocking: true)
				Thread.sleep(forTimeInterval: 0.5)
			}
		}
        
        return mirror
	}
	
	/**
	 * De-initializes the current mirror object, thus any further mirror calls will fail until the next initMirror
	 */
	static func destroy() {
        logger.verbose("Deinitializing mirror")
        MirrorHelper.accessQueue.sync {
            MirrorHelper._mirror = nil
        }
	}
    
    // MARK: - Account information
    
    static func getBattleTag() -> String? {
        var result: String?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getBattleTag()
        }
        return result
    }
    
    static func getAccountId() -> MirrorAccountId? {
        var result: MirrorAccountId?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getAccountId()
        }
        return result
    }
	
	// MARK: - get player decks
	
	static func getDecks() -> [MirrorDeck]? {
        var result: [MirrorDeck]?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getDecks()
        }
		return result
	}
    
    static func getTemplateDecks() -> [MirrorTemplateDeck]? {
        var result: [MirrorTemplateDeck]?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getTemplateDecks()
        }
        return result
    }
	
	static func getSelectedDeck() -> Int64? {
        var result: Int64?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getSelectedDeck() as? Int64? ?? nil
        }
		return result
	}
	
	static func getArenaDeck() -> MirrorArenaInfo? {
        var result: MirrorArenaInfo?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getArenaDeck()
        }
        return result
	}
	
	static func getEditedDeck() -> MirrorDeck? {
        var result: MirrorDeck?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getEditedDeck()
        }
        return result
	}
	
	// MARK: - collection
	
	static func getCollection() -> MirrorCollection? {
        var result: MirrorCollection?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getCollection()
        }
        return result
	}
	
	// MARK: - game mode
	static func isSpectating() -> Bool? {
        var result: Bool?
        MirrorHelper.accessQueue.sync {
            result = mirror?.isSpectating()
        }
        return result
	}
	
	static func getGameType() -> Int? {
        var result: Int?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getGameType() as? Int? ?? nil
        }
        return result
	}
	
	static func getMatchInfo() -> MirrorMatchInfo? {
        var result: MirrorMatchInfo?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getMatchInfo()
        }
        return result
	}
	
	static func getFormat() -> Int? {
        var result: Int?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getFormat() as? Int? ?? nil
        }
        return result
	}
	
	static func getGameServerInfo() -> MirrorGameServerInfo? {
        var result: MirrorGameServerInfo?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getGameServerInfo()
        }
        return result
	}
	
	// MARK: - arena
	
	static func getArenaDraftChoices() -> [MirrorCard]? {
        var result: [MirrorCard]?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getArenaDraftChoices()
        }
        return result
	}
	
	// MARK: - brawl
	
	static func getBrawlInfo() -> MirrorBrawlInfo? {
        var result: MirrorBrawlInfo?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getBrawlInfo()
        }
        return result
	}
    
    // MARK: - dungeon
    
    static func getDungeonRunInfo() -> MirrorDungeonInfo? {
        var result: MirrorDungeonInfo?
        MirrorHelper.accessQueue.sync {
            result = mirror?.getDungeonInfo()
        }
        return result
    }
	
}
