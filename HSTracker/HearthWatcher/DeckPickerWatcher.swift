//
//  DeckPickerWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

enum VisualsFormatType: Int {
    case vft_unknown,
         vft_wild,
         vft_standard,
         vft_classic,
         vft_casual,
         vft_twist
}

class CollectionDeckBoxVisual: Equatable {
    static func == (lhs: CollectionDeckBoxVisual, rhs: CollectionDeckBoxVisual) -> Bool {
        return lhs === rhs || (lhs.deckid == rhs.deckid && lhs.isShowingInvalidCardCount == rhs.isShowingInvalidCardCount && lhs.invalidSideboardCardCount == rhs.invalidSideboardCardCount && lhs.missingSideboardCardCount == rhs.missingSideboardCardCount && lhs.isFocused == rhs.isFocused && lhs.isSelected == rhs.isSelected)
        }
    
    let deckid: Int64?
    let isShowingInvalidCardCount: Bool
    let invalidSideboardCardCount: Int
    let missingSideboardCardCount: Int
    let isFocused: Bool
    let isSelected: Bool
    
    init(deckid: Int64?, isShowingInvalidCardCount: Bool, invalidSideboardCardCount: Int, missingSideboardCardCount: Int, isFocused: Bool, isSelected: Bool) {
        self.deckid = deckid
        self.isShowingInvalidCardCount = isShowingInvalidCardCount
        self.invalidSideboardCardCount = invalidSideboardCardCount
        self.missingSideboardCardCount = missingSideboardCardCount
        self.isFocused = isFocused
        self.isSelected = isSelected
    }
}

struct DeckPickerEventArgs: Equatable {
    static func == (lhs: DeckPickerEventArgs, rhs: DeckPickerEventArgs) -> Bool {
        return lhs.selectedFormatType == rhs.selectedFormatType && lhs.selectedDeck == rhs.selectedDeck && lhs.isModalOpen == rhs.isModalOpen && lhs.decksOnPage == rhs.decksOnPage
    }
    
    let selectedFormatType: VisualsFormatType
    let decksOnPage: [CollectionDeckBoxVisual?]
    let selectedDeck: Int64
    let isModalOpen: Bool
}

class DeckPickerWatcher: Watcher {
    var change: ((_ sender: DeckPickerWatcher, _ args: DeckPickerEventArgs) -> Void)?
    private var _prev: DeckPickerEventArgs?
    
    override init(delay: TimeInterval = 0.200) {
        super.init(delay: delay)
    }
    
    override func cleanup() {
        _prev = nil
    }

    override func update() -> Bool {
        let decks = MirrorHelper.getDeckPickerDecksOnPage().map { x in
            var res: CollectionDeckBoxVisual?
            if let x {
                res = CollectionDeckBoxVisual(deckid: x.deckId?.int64Value, isShowingInvalidCardCount: x.isShowingInvalidCardCount, invalidSideboardCardCount: x.invalidSideboardCardCount.intValue, missingSideboardCardCount: x.missingSideboardCardCount.intValue, isFocused: x.isFocused, isSelected: x.isSelected)
            }
            return res
        }
        let state = MirrorHelper.getDeckPickerState()
        let curr = DeckPickerEventArgs(selectedFormatType: VisualsFormatType(rawValue: state?.visualsFormatType.intValue ?? 0) ?? VisualsFormatType.vft_unknown, decksOnPage: decks, selectedDeck: state?.selectedDeck?.int64Value ?? 0, isModalOpen: (state?.isModeSwitching ?? false) || MirrorHelper.isBlurActive() || (state?.setRotationOpen ?? false))
        if curr == _prev {
            return false
        }
        change?(self, curr)
        _prev = curr
        return false
    }
}
