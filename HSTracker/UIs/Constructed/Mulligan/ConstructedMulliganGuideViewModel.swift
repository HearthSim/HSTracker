//
//  ConstructedMulliganGuideViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/19/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ConstructedMulliganGuideViewModel: ViewModel {
    var visibility: Bool {
        get {
            return getProp(false)
        }
        set {
            setProp(newValue)
        }
    }
    
    var statsVisibility: Bool {
        get {
            return getProp(false)
        }
        set {
            setProp(newValue)
        }
    }
    
    var visibilityToggleIcon: String {
        return statsVisibility ? "eye_slash" : "eye"
    }
    
    var visibilityToggleText: String {
        return statsVisibility ? String.localizedString("ConstructedMulliganGuide_VisibilityToggle_Hide", comment: "") : String.localizedString("ConstructedMulliganGuide_VisibilityToggle_Show", comment: "")
    }
    
    var cardStats: [ConstructedMulliganSingleCardViewModel]? {
        get {
            return getProp(nil)
        }
        set {
            setProp(newValue)
        }
    }
    
    let overlayMesageViewModel = ConstructedMulliganOverlayMessageViewModel()
        
    func reset() {
        cardStats = nil
        visibility = false
        statsVisibility = false
        overlayMesageViewModel.text = nil
    }
    
    var scaling: Double {
        get {
            return getProp(1.0)
        }
        set {
            setProp(newValue)
        }
    }
    
    func setMulliganData(stats: [SingleCardStats]?, maxRank: Int?, selectedParams: [String: String?]?) {
        cardStats = stats?.compactMap { x in ConstructedMulliganSingleCardViewModel(stats: x, maxRank: maxRank) }

        if let selectedParams {
            var opponentClass: CardClass?
            if let opponentClassString = selectedParams["opponent_class"] {
                opponentClass = CardClass(rawValue: opponentClassString ?? "")
                }
            var initiative: ConstructedMulliganOverlayMessageViewModel.PlayerInitiative?
            if let initiativeString = selectedParams["PlayerInitiative"] {
                initiative = ConstructedMulliganOverlayMessageViewModel.PlayerInitiative(rawValue: initiativeString?.lowercased() ?? "")
            }
            
            if let opponentClass, let initiative {
                overlayMesageViewModel.scope(cardClass: opponentClass, initiative: initiative)
            }
        }
        
        visibility = true
        statsVisibility =  Settings.autoShowMulliganGuide
    }
}
