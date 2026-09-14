//
//  BattlegroundsNotificationsViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

// The two Battlegrounds notification panels HDT keeps on its overlay canvas -
// HeroNotificationPanel and TimewarpNotificationPanel - which offer to open the
// matching HSReplay.net page. They share a view model because they share their
// shape, their placement rule and the single call site each in Game.
@available(macOS 10.15, *)
class BattlegroundsNotificationsViewModel: ObservableObject {
    @Published private(set) var heroPickIsShown = false
    @Published private(set) var timewarpIsShown = false

    private var heroIds: [Int]?
    private var duos = false
    private var anomalyDbfId: Int?
    private var parameters: [String: String]?

    private var boardCards: [MirrorBoardCard]?

    // HDT's EntranceAnimation/ExitAnimation = Slide on both behaviors.
    static let slideDuration = 0.2

    // MARK: - Hero picking

    func showHeroPick(heroIds: [Int], duos: Bool, anomalyDbfId: Int?, parameters: [String: String]?) {
        onMain {
            self.heroIds = heroIds
            self.duos = duos
            self.anomalyDbfId = anomalyDbfId
            self.parameters = parameters
            withAnimation(.easeInOut(duration: Self.slideDuration)) {
                self.heroPickIsShown = true
            }
        }
    }

    func hideHeroPick() {
        onMain {
            withAnimation(.easeInOut(duration: Self.slideDuration)) {
                self.heroPickIsShown = false
            }
        }
    }

    func openHeroPicker() {
        if let heroIds {
            Helper.openBattlegroundsHeroPicker(heroIds: heroIds, duos: duos, anomalyDbfId: anomalyDbfId, parameters: parameters)
        }
        AppDelegate.instance().coreManager.game.hideBattlegroundsHeroPanel()
    }

    // MARK: - Timewarp

    func showTimewarp(boardCards: [MirrorBoardCard]) {
        onMain {
            self.boardCards = boardCards
            withAnimation(.easeInOut(duration: Self.slideDuration)) {
                self.timewarpIsShown = true
            }
        }
    }

    func hideTimewarp() {
        onMain {
            withAnimation(.easeInOut(duration: Self.slideDuration)) {
                self.timewarpIsShown = false
            }
        }
    }

    func openTimewarp() {
        if let boardCards, boardCards.count > 0 {
            Helper.openBattlegroundsTimewarpPage(boardCards)
        }
    }

    // Both panels are pushed from the log reader's own thread, and @Published
    // has to be written on the main one.
    private func onMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}
