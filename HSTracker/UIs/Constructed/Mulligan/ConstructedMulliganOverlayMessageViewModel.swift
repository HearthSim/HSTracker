//
//  ConstructedMulliganOverlayMessageViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/7/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

// HDT's OverlayMessageViewModel, the banner the V1 mulligan guide shows under
// the card row.
class ConstructedMulliganOverlayMessageViewModel: ObservableObject {
    // HDT keeps Text and Visibility as separate properties, with the setter for
    // one driving the other; here the visibility is simply derived, which is
    // the same thing with one source of truth.
    @Published var text: String?

    var visibility: Bool {
        text != nil
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
