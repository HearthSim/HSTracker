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
    
    var message = OverlayMessageViewModel()
    
    func reset() {
        cardStats = nil
        visibility = false
        statsVisibility = false
        message.clear()
    }
    
    var scaling: Double {
        get {
            return getProp(1.0)
        }
        set {
            setProp(newValue)
        }
    }
    
    func setMulliganData(stats: [SingleCardStats]?, maxRank: Int?) {
        cardStats = stats?.compactMap { x in ConstructedMulliganSingleCardViewModel(stats: x, maxRank: maxRank) }
        
        // TODO values
        //Message.Mmr(scoreData.SelectedParams. stats[0].MmrFilterValue, stats[0].MinMmr, anomalyAdjusted);
        
        visibility = true
        statsVisibility =  true // FIXME: Config.Instance.ShowMulliganGuideAutomatically ? Visible : Collapsed;
    }
}
