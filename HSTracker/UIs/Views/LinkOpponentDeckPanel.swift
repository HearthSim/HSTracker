//
//  LinkOpponentDeckPanel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/1/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

enum LinkOpponentDeckState {
    case initial, error, inKnownDeckMode
}

class LinkOpponentDeckStateConverter {
    static func getLinkMessage(state: LinkOpponentDeckState) -> String {
        if !Settings.interactedWithLinkOpponentDeck {
            return String.localizedString("LinkOpponentDeck_Dismiss", comment: "")
        }
        switch state {
        case .inKnownDeckMode:
            return String.localizedString("LinkOpponentDeck_Clear", comment: "")
        default:
            return ""
        }
    }
}

class LinkOpponentDeckPanel: OverWindowController, NSTextViewDelegate {
    @objc dynamic var errorMessageVisibility = false
    @objc dynamic var errorMessage: String = "" {
        didSet {
            errorMessageVisibility = !errorMessage.isBlank
        }
    }
    @objc dynamic var descriptorVisibility: Bool {
        return !Settings.interactedWithLinkOpponentDeck || !sessionStartHasInteracted ? true : false
    }
    @objc dynamic var linkMessageVisibility = true
    @objc dynamic var linkMessage: String = ""
    
    private var sessionStartHasInteracted = Settings.interactedWithLinkOpponentDeck
    private var shownByOpponentStack = false
    private var mouseIsOver = false
    
    var isFriendlyMatch = false
    var autoShown = false
    var hasLinkedDeck = false
    
    var isShowing = false
    
    private lazy var trackingArea: NSTrackingArea = NSTrackingArea(rect: NSRect.zero,
                                                                   options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                          owner: self,
                          userInfo: nil)

    private var linkOpponentDeckState: LinkOpponentDeckState = .initial {
        didSet {
            updateLinkMessage()
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.contentView?.addTrackingArea(trackingArea)
    }
    
    private func updateLinkMessage() {
        linkMessage = LinkOpponentDeckStateConverter.getLinkMessage(state: linkOpponentDeckState)
    }
    
    override func updateFrames() {
        window?.ignoresMouseEvents = false
    }
    
    @IBAction func linkOpponentDeckClick(_ sender: Any) {
        willChangeValue(for: \.descriptorVisibility)
        Settings.interactedWithLinkOpponentDeck = true
        didChangeValue(for: \.descriptorVisibility)
        
        if let deck = ClipboardImporter.clipboardImport() {
            Player.knownOpponentDeck = deck.cards
            linkOpponentDeckState = .inKnownDeckMode
            hasLinkedDeck = true
            errorMessage = ""
            AppDelegate.instance().coreManager.game.updateTrackers()
        } else {
            linkOpponentDeckState = .error
            errorMessage = String.localizedString("LinkOpponentDeck_NoValidDeckOnClipboardMessage", comment: "")
        }
    }
    
    func hideByOpponentStack() {
        shownByOpponentStack = false
        hide(false)
    }
    
    func hide(_ force: Bool = false) {
        if force || !mouseIsOver {
            DispatchQueue.main.async {
                self.isShowing = false
                let wm = AppDelegate.instance().coreManager.game.windowManager
                wm.show(controller: wm.linkOpponentDeckPanel, show: false)
            }
        }
        autoShown = false
        errorMessage = ""
    }
    
    func showByOpponentStack() {
        shownByOpponentStack = true
        show()
    }
    
    func show() {
        if isFriendlyMatch || Settings.enableLinkOpponentDeckInNonFriendly {
            DispatchQueue.main.async {
                self.isShowing = true
                let wm = AppDelegate.instance().coreManager.game.windowManager
                let rect = wm.opponentTracker.window?.frame
                wm.show(controller: wm.linkOpponentDeckPanel, show: true,
                        frame: NSRect(x: rect?.origin.x ?? 0,
                                      y: (rect?.minY ?? 0) + wm.opponentTracker.bottomY - 125 - 10,
                                      width: WindowManager.cardWidth,
                                      height: 125))
            }
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        mouseIsOver = true
    }

    override func mouseExited(with event: NSEvent) {
        mouseIsOver = false
        if !shownByOpponentStack {
            hide()
        }
    }

    @IBAction func hyperlinkMouseDown(_ sender: Any) {
        if !Settings.interactedWithLinkOpponentDeck {
            Settings.interactedWithLinkOpponentDeck = true
            hide(true)
        } else {
            Player.knownOpponentDeck = nil
            AppDelegate.instance().coreManager.game.updateTrackers()
            linkOpponentDeckState = .initial
            hasLinkedDeck = false
        }
    }
}
