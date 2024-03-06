//
//  SceneHandler.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/2/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class SceneHandler {
    static private(set) var scene: Mode?
    
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
        SceneHandler.scene = nil
        
        guard let core = AppDelegate.instance().coreManager else {
            return
        }
        let game = core.game
        
        if from == .tournament {
            
            DispatchQueue.main.async {
                game.updateMulliganGuidePreLobby()
            }
            DeckPickerWatcher.stop()
            game.windowManager.constructedMulliganGuidePreLobby.viewModel.invlidateAllDecks()
        }
        
        if from == .bacon {
            if to != .gameplay {
                game.showBattlegroundsSession(false, true)
            }
            if #available(macOS 10.15, *) {
                game.showTier7PreLobby(show: false, checkAccountStatus: false)
                BaconWatcher.stop()
            }
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
        }
        if to == .bacon {
            game.cacheBattlegroundRatingInfo()
            
            game.showBattlegroundsSession(true, true)
            if #available(macOS 10.15, *) {
                game.showTier7PreLobby(show: true, checkAccountStatus: true)
                BaconWatcher.start()
            }
        }
    }
}
