//
//  BaconWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

enum SelectedBattlegroundsGameMode: Int {
    case unknown = 0,
         solo = 1,
         duos = 2
}

struct BaconEventArgs: Equatable {
    let isShopOpen: Bool
    let isJournalOpen: Bool
    let isPopupShowing: Bool
    let isFriendsListOpen: Bool
    let isBlurActive: Bool
    // HDT's UIEventArgs.IsGameMenuShown. Deliberately outside isAnyOpen() below:
    // HDT's own IsGameCriticalUiOpen leaves the escape menu (and the friends
    // list) out, they only drive the overlay's opacity mask.
    let isGameMenuShown: Bool
    let selectedBattlegroundsGameMode: SelectedBattlegroundsGameMode
    
    init(_ isShopOpen: Bool, _ isJournalOpen: Bool, _ isPopupShowing: Bool, _ isFriendsListOpen: Bool, _ isBlurActive: Bool, _ isGameMenuShown: Bool, _ selectedBattlegroundsGameMode: SelectedBattlegroundsGameMode) {
        self.isShopOpen = isShopOpen
        self.isJournalOpen = isJournalOpen
        self.isPopupShowing = isPopupShowing
        self.isFriendsListOpen = isFriendsListOpen
        self.isBlurActive = isBlurActive
        self.isGameMenuShown = isGameMenuShown
        self.selectedBattlegroundsGameMode = selectedBattlegroundsGameMode
    }
    
    func isAnyOpen() -> Bool {
        return isShopOpen || isJournalOpen || isPopupShowing || isFriendsListOpen || isBlurActive
    }
}

class BaconWatcher: Watcher {
    var change: ((_ sender: BaconWatcher, _ args: BaconEventArgs) -> Void)?
    private var _prev: BaconEventArgs?
    
    override init(delay: TimeInterval = 0.200) {
        super.init(delay: delay)
    }
    
    override func cleanup() {
        _prev = nil
    }

    override func update() -> Bool {
        let curr = BaconEventArgs(MirrorHelper.isShopOpen(), MirrorHelper.isJournalOpen(), MirrorHelper.isPopupShowing(), MirrorHelper.isFriendsListVisible(), MirrorHelper.isBlurActive(), MirrorHelper.isGameMenuVisible(), MirrorHelper.getSelectedBattlegroundsGameMode())
        if curr ==  _prev {
            return false
        }
        change?(self, curr)
        _prev = curr
        return false
    }
}
