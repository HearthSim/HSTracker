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
    
    static func reset() {
        lastScene = nil
        scene = nil
        nextScene = nil
        transitioning = nil
    }
    
    static func onSceneUpdate(prevMode: Mode, mode: Mode, sceneLoaded: Bool, transitioning: Bool) {
        if SceneHandler.transitioning == nil || transitioning {
            onSceneTransitionStart(from: prevMode, to: mode)
            SceneHandler.transitioning = true
        }
        if !transitioning && sceneLoaded {
            // We settled on a new scene without ever observing the transition start
            // (e.g. the transitioning frame was missed, or stale state leaked across a
            // game restart). Run the leave logic for the scene we are coming from so its
            // overlays get hidden.
            if transitioning == false, let scene, scene != mode {
                onSceneTransitionStart(from: scene, to: mode)
            }

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
            Watchers.deckPickerWatcher.stop()
        } else if from == .bacon {
            DispatchQueue.main.async {
                game.updateBattlegroundsSessionVisibility()
                if #available(macOS 10.15, *) {
                    game.updateTier7PreLobbyVisibility()
                }
            }
            Watchers.baconWatcher.stop()
        } else if from == .gameplay {
            game.updateBattlegroundsSessionVisibility()
            Watchers.battlegroundsTeammateBoardStateWatcher.stop()
            Watchers.baconWatcher.stop()
            Watchers.bigCardWatcher.stop()
            Watchers.discoverStateWatcher.stop()
            Watchers.choicesWatcher.stop()
            Watchers.specialShopChoicesStateWatcher.stop()
        }
    }
    
    private static func onSceneTransitionComplete(from: Mode, to: Mode) {
        SceneHandler.scene = to

        guard let core = AppDelegate.instance().coreManager else {
            return
        }
        let game = core.game

        if to == .tournament {
            Watchers.deckPickerWatcher.run()
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
            Watchers.baconWatcher.run()
        } else if to == .gameplay {
            game.updateBattlegroundsSessionVisibility()
            Watchers.bigCardWatcher.run()
            Watchers.choicesWatcher.run()
            Watchers.specialShopChoicesStateWatcher.run()
            Watchers.discoverStateWatcher.run()
            Watchers.baconWatcher.run()
        }
        
        if from == .bacon {
            game.windowManager.tier7PreLobby.viewModel.invalidateUserState()
        }
    }
}
