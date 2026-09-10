//
//  MulliganToastViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

// The state behind HDT's MulliganPanel.xaml.cs - the toast offering the deck's
// mulligan guide on HSReplay.net, which appears at the start of a constructed
// match and either links to the deck's page or says there is nothing to link to.
@available(macOS 10.15, *)
class MulliganToastViewModel: ObservableObject {
    @Published private(set) var isShown = false
    // HasData: there is a deck page to open.
    @Published private(set) var hasData = false
    @Published private(set) var showingMulliganStats = false

    private var shortId: String?
    private var dbfIds: [Int]?
    private var parameters: [String: String]?

    // HDT's EntranceAnimation/ExitAnimation = Slide.
    static let slideDuration = 0.2

    var noDataLabel: String {
        return String.localizedString(showingMulliganStats ? "Toast_Mulligan_NotOnWebsite" : "Toast_Mulligan_Unavailable",
                                      comment: "")
    }

    // OverlayWindow.ShowMulliganToast: update, then show only if the panel
    // itself says it is worth showing.
    func show(shortId: String, dbfIds: [Int], parameters: [String: String]?, showingMulliganStats: Bool) {
        onMain {
            self.shortId = shortId
            self.dbfIds = dbfIds
            self.parameters = parameters
            self.hasData = !shortId.isEmpty && parameters != nil
            self.showingMulliganStats = showingMulliganStats

            if self.shouldShow() {
                withAnimation(.easeInOut(duration: Self.slideDuration)) {
                    self.isShown = true
                }
            }
        }
    }

    func hide() {
        onMain {
            withAnimation(.easeInOut(duration: Self.slideDuration)) {
                self.isShown = false
            }
        }
    }

    // MulliganPanel.UserControl_MouseLeftButtonUp: the toast always dismisses
    // itself, and opens the deck's page when it has one.
    func click() {
        if hasData, let shortId, let dbfIds {
            var fragmentParams = parameters?.compactMap { kv in "\(Helper.urlEncode(kv.key))=\(Helper.urlEncode(kv.value))" } ?? [String]()
            fragmentParams.append("mulliganIds=\(dbfIds.compactMap { x in String(x) }.joined(separator: ","))")
            if let url = URL(string: Helper.buildHsReplayNetUrl("/decks/\(shortId)", "mulligan_toast", nil, fragmentParams)) {
                NSWorkspace.shared.open(url)
            }
        }
        AppDelegate.instance().coreManager.game.hideMulliganToast()
    }

    // MulliganPanel.ShouldShow: a deck with data always earns a toast, while
    // the "no data" one is shown once per deck and then kept quiet.
    private var noDataShown = Set<String>()
    private func shouldShow() -> Bool {
        guard let shortId, !shortId.isEmpty else {
            return false
        }
        if hasData {
            return true
        }
        if noDataShown.contains(shortId) {
            return false
        }
        noDataShown.insert(shortId)
        return true
    }

    // Pushed from the log reader's own thread, and @Published has to be
    // written on the main one.
    private func onMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}
