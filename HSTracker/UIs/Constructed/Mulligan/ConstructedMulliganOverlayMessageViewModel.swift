//
//  OverlayMessageViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/7/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class ConstructedMulliganOverlayMessageViewModel: ViewModel {
    
    var text: String? {
        get {
            return getProp(nil)
        }
        set {
            setProp(newValue)
            if newValue == nil {
                visibility = false
            } else {
                visibility = true
            }
        }
    }
    
    var visibility: Bool {
        get {
            return getProp(false)
        }
        set {
            setProp(newValue)
        }
    }
    
    override init() {
    }
    
    func error() {
        let errorText = String.localizedString("ConstructedMulliganGuide_Message_Error", comment: "")
        self.text = errorText
        Thread.sleep(forTimeInterval: 5.0)
        if self.text == errorText {
            self.clear()
        }
    }
    
    enum PlayerInitiative: String {
        case first, coin
    }
    
    func scope(cardClass: CardClass, initiative: PlayerInitiative) {
        let localizedCardClass = String.localizedString("\(cardClass)", comment: "")
        
        if initiative == .first {
            text = String(format: String.localizedString("ConstructedMulliganGuide_Message_VsClass_GoingFirst", comment: ""), localizedCardClass)
        } else {
            text = String(format: String.localizedString("ConstructedMulliganGuide_Message_VsClass_ExtraCard", comment: ""), localizedCardClass)
        }
    }
    
    func clear() {
        text = nil
    }
}
