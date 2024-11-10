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
    let selectedBattlegroundsGameMode: SelectedBattlegroundsGameMode
    
    init(_ isShopOpen: Bool, _ isJournalOpen: Bool, _ isPopupShowing: Bool, _ isFriendsListOpen: Bool, _ isBlurActive: Bool, _ selectedBattlegroundsGameMode: SelectedBattlegroundsGameMode) {
        self.isShopOpen = isShopOpen
        self.isJournalOpen = isJournalOpen
        self.isPopupShowing = isPopupShowing
        self.isFriendsListOpen = isFriendsListOpen
        self.isBlurActive = isBlurActive
        self.selectedBattlegroundsGameMode = selectedBattlegroundsGameMode
    }
    
    func isAnyOpen() -> Bool {
        return isShopOpen || isJournalOpen || isPopupShowing || isFriendsListOpen || isBlurActive
    }
}

class BaconWatcher {
    var change: ((_ sender: BaconWatcher, _ args: BaconEventArgs) -> Void)?
    private let delay: TimeInterval
    private var _running = false
    private var _watch = false
    private var _prev: BaconEventArgs?
    internal var queue: DispatchQueue?
    
    init(delay: TimeInterval = 0.200) {
        self.delay = delay
    }
    
    func run() {
        _watch = true
        if _running {
            return
        }
        if queue == nil {
            queue = DispatchQueue(label: "net.hearthsim.hstracker.watchers.\(type(of: self))",
                                  attributes: [])
        }
        if let queue = queue {
            queue.async { [weak self] in
                Thread.current.name = queue.label
                self?.update()
            }
        }
    }
    
    func stop() {
        _watch = false
    }
    
    private func update() {
        _running = true
        while _watch {
            Thread.sleep(forTimeInterval: delay)
            if !_watch {
                break
            }
            let curr = BaconEventArgs(MirrorHelper.isShopOpen(), MirrorHelper.isJournalOpen(), MirrorHelper.isPopupShowing(), MirrorHelper.isFriendsListVisible(), MirrorHelper.isBlurActive(), MirrorHelper.getSelectedBattlegroundsGameMode())
            if curr ==  _prev {
                continue
            }
            change?(self, curr)
            _prev = curr
        }
        _prev = nil
        _running = false
    }
}
