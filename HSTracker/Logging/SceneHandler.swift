//
//  SceneHandler.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/2/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class SceneHandler {
    static private(set) var lastScene: Mode?
    static private(set) var scene: Mode?
    static private(set) var nextScene: Mode?
    
    static private var transitioning: Bool?
    
    static func onSceneUpdate(prevMode: Mode, mode: Mode, sceneLoaded: Bool, transitioning: Bool) {
        if SceneHandler.transitioning == nil || transitioning {
            onSceneTransitionStart(from: prevMode, to: mode)
            SceneHandler.transitioning = true
        }
        if !transitioning && sceneLoaded {
            onSceneTransitionComplete(from: prevMode, to: mode)
            SceneHandler.transitioning = false
        }
    }
    
    private static func onSceneTransitionStart(from: Mode, to: Mode) {
        SceneHandler.lastScene = from
        SceneHandler.nextScene = to
        SceneHandler.scene = nil
        
        let game = AppDelegate.instance().coreManager.game
        
        if from == .tournament {
            
            DispatchQueue.main.async {
                game.updateMulliganGuidePreLobby()
            }
            game.windowManager.constructedMulliganGuidePreLobby.viewModel.invlidateAllDecks()
            DeckPickerWatcher.stop()
        } else if from == .bacon {
            DispatchQueue.main.async {
                game.updateBattlegroundsSessionVisibility()
                if #available(macOS 10.15, *) {
                    game.updateTier7PreLobbyVisibility()
                }
            }
            BaconWatcher.stop()
        } else if from == .gameplay {
            game.updateBattlegroundsSessionVisibility()
            BattlegroundsTeammateBoardStateWatcher.stop()
        }
    }
    
    private static func onSceneTransitionComplete(from: Mode, to: Mode) {
        SceneHandler.scene = to

        guard let core = AppDelegate.instance().coreManager else {
            return
        }
        let game = core.game

        if to == .tournament {
            DeckPickerWatcher.start()
            DispatchQueue.main.async {
                game.updateMulliganGuidePreLobby()
            }
        } else if to == .bacon {
            game.cacheBattlegroundRatingInfo()
            
            DispatchQueue.main.async {
                game.updateBattlegroundsSessionVisibility()
                if #available(macOS 10.15, *) {
                    game.updateTier7PreLobbyVisibility()
                }
            }
            BaconWatcher.start()
        } else if to == .gameplay {
            game.updateBattlegroundsSessionVisibility()
        } else if from == .bacon {
            game.windowManager.tier7PreLobby.viewModel.invalidateUserState()
        }
    }
}
