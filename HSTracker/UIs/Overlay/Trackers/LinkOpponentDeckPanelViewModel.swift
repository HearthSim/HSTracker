//
//  LinkOpponentDeckPanelViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit
import SwiftUI

enum LinkOpponentDeckState {
    case initial, error, inKnownDeckMode
}

/// HDT's `LinkOpponentDeckPanel`, the "know your opponent's deck?" prompt that
/// hangs off the bottom of the opponent stack (`Controls/Overlay/LinkOpponentDeckPanel.xaml`,
/// placed by `OverlayWindow.UpdateElementPositions`).
///
/// It replaces the window controller of the same name; the behaviour - when it
/// shows, what the link and error lines say, what the button does - is that
/// class's, unchanged.
@available(macOS 10.15, *)
class LinkOpponentDeckPanelViewModel: ObservableObject {
    @Published private(set) var isShowing = false
    @Published private(set) var errorMessage = ""
    @Published private(set) var linkMessage = ""

    /// Whether the explanatory paragraph is shown - HDT's `DescriptorVisibility`.
    @Published private(set) var showsDescription = !Settings.interactedWithLinkOpponentDeck

    var isFriendlyMatch = false
    var autoShown = false
    var hasLinkedDeck = false

    private var sessionStartHasInteracted = Settings.interactedWithLinkOpponentDeck
    private var shownByOpponentStack = false
    /// Set by the view while the cursor is on the panel, so a hover that started
    /// on the opponent stack survives the trip down to the button.
    var mouseIsOver = false

    private var state: LinkOpponentDeckState = .initial {
        didSet { updateLinkMessage() }
    }

    init() {
        updateLinkMessage()
    }

    private func updateLinkMessage() {
        if !Settings.interactedWithLinkOpponentDeck {
            linkMessage = String.localizedString("LinkOpponentDeck_Dismiss", comment: "")
            return
        }
        switch state {
        case .inKnownDeckMode:
            linkMessage = String.localizedString("LinkOpponentDeck_Clear", comment: "")
        default:
            linkMessage = ""
        }
    }

    // MARK: - Show / hide

    func showByOpponentStack() {
        shownByOpponentStack = true
        show()
    }

    func hideByOpponentStack() {
        shownByOpponentStack = false
        hide()
    }

    func show() {
        guard isFriendlyMatch || Settings.enableLinkOpponentDeckInNonFriendly else { return }
        isShowing = true
    }

    func hide(_ force: Bool = false) {
        if force || !mouseIsOver {
            isShowing = false
        }
        autoShown = false
        errorMessage = ""
    }

    func mouseExited() {
        mouseIsOver = false
        if !shownByOpponentStack {
            hide()
        }
    }

    // MARK: - Actions

    func linkDeckFromClipboard() {
        Settings.interactedWithLinkOpponentDeck = true
        showsDescription = !Settings.interactedWithLinkOpponentDeck || !sessionStartHasInteracted

        if let deck = ClipboardImporter.clipboardImport() {
            Player.knownOpponentDeck = deck.cards
            state = .inKnownDeckMode
            hasLinkedDeck = true
            errorMessage = ""
            AppDelegate.instance().coreManager.game.updateTrackers()
        } else {
            state = .error
            errorMessage = String.localizedString("LinkOpponentDeck_NoValidDeckOnClipboardMessage", comment: "")
        }
        updateLinkMessage()
    }

    func linkTapped() {
        if !Settings.interactedWithLinkOpponentDeck {
            Settings.interactedWithLinkOpponentDeck = true
            updateLinkMessage()
            hide(true)
        } else {
            Player.knownOpponentDeck = nil
            AppDelegate.instance().coreManager.game.updateTrackers()
            state = .initial
            hasLinkedDeck = false
        }
    }
}
