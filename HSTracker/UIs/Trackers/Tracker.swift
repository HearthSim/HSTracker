/*
* This file is part of the HSTracker package.
* (c) Benjamin Michotte <bmichotte@gmail.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*
* Created on 15/02/16.
*/

import Cocoa

enum HandCountPosition: Int {
    case Tracker,
    Window
}

class Tracker: NSWindowController, NSTableViewDataSource, NSTableViewDelegate, CardCellHover {
    
    @IBOutlet weak var table: NSTableView!
    
    var gameEnded: Bool = false
    var heroCard: Card?
    var cards = [Card]()
    var player: Player?
    var playerType: PlayerType?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Tracker.hearthstoneRunning(_:)), name: "hearthstone_running", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Tracker.hearthstoneActive(_:)), name: "hearthstone_active", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Tracker.opacityChange(_:)), name: "tracker_opacity", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Tracker.cardSizeChange(_:)), name: "card_size", object: nil)
        let options = ["show_opponent_draw", "show_opponent_mulligan", "show_opponent_play",
            "show_player_draw", "show_player_mulligan", "show_player_play", "rarity_colors",
            "remove_cards_from_deck", "highlight_last_drawn", "highlight_cards_in_hand",
            "highlight_discarded", "show_player_get"]
        for option in options {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Tracker.trackerOptionsChange(_:)), name: option, object: nil)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Tracker.windowLockedChange(_:)), name: "window_locked", object: nil)
        
        self.gameEnded = false
        
        var width: Double
        let settings = Settings.instance
        switch settings.cardSize {
        case .Small:
            width = kSmallFrameWidth
            
        case .Medium:
            width = kMediumFrameWidth
            
        default:
            width = kFrameWidth
        }
        
        self.window!.setFrame(NSRect(x: 0, y: 0, width: width, height: 200), display: true)
        self.window!.contentMinSize = NSSize(width: width, height: 200)
        self.window!.contentMaxSize = NSSize(width: width, height: Double(NSHeight(NSScreen.mainScreen()!.frame)))
        
        self.window!.opaque = false
        self.window!.hasShadow = false
        self.window!.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: CGFloat(Settings.instance.trackerOpacity / 100.0))
        
        let locked = settings.windowsLocked
        if locked {
            self.window!.styleMask = NSBorderlessWindowMask
        } else {
            self.window!.styleMask = NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSBorderlessWindowMask
        }
        self.window!.ignoresMouseEvents = locked
        self.window!.acceptsMouseMovedEvents = true
        
        if Hearthstone.instance.isHearthstoneRunning {
            self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))
        }
        
        self.table.intercellSpacing = NSSize(width: 0, height: 0)
        
        self.table.backgroundColor = NSColor.clearColor()
        self.table.autoresizingMask = [NSAutoresizingMaskOptions.ViewWidthSizable, NSAutoresizingMaskOptions.ViewHeightSizable]
        
        let nib = NSNib(nibNamed: "CountTextCellView", bundle: nil)
        self.table.registerNib(nib, forIdentifier: "CountTextCellView")
        
        self.table.reloadData()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func windowLockedChange(notification: NSNotification) {
        let locked = Settings.instance.windowsLocked
        if locked {
            self.window!.styleMask = NSBorderlessWindowMask
        } else {
            self.window!.styleMask = NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSBorderlessWindowMask
        }
        self.window!.ignoresMouseEvents = locked
    }
    
    func hearthstoneRunning(notification: NSNotification) {
        if Hearthstone.instance.isHearthstoneRunning {
            self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))
        }
        else {
            self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.NormalWindowLevelKey))
        }
    }
    
    func hearthstoneActive(notification: NSNotification) {
        let locked = Settings.instance.windowsLocked
        
        if Hearthstone.instance.hearthstoneActive && locked {
            self.window!.styleMask = NSBorderlessWindowMask
            self.window!.ignoresMouseEvents = true
        } else {
            self.window!.styleMask = NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSBorderlessWindowMask
            self.window!.ignoresMouseEvents = false
        }
    }
    
    func trackerOptionsChange(notification: NSNotification) {
        self.table.reloadData()
    }
    
    func cardSizeChange(notification: NSNotification) {
        self.table.reloadData()
    }
    
    func opacityChange(notification: NSNotification) {
        self.window!.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: CGFloat(Settings.instance.trackerOpacity / 100.0))
    }
    
    // MARK: - NSTableViewDelegate / NSTableViewDataSource
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        var count = self.cards.count
        
        /*if ([Settings instance].handCountWindow == HandCountPosition_Tracker) {
        count += 1;
        }*/
        if count > 0 {
            count += 1
        }
        
        if let playerType = self.playerType where self.gameEnded && playerType == .Opponent {
            count += 1
        }
        
        return count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if row >= cards.count {
            let cell = table.makeViewWithIdentifier("CountTextCellView", owner: self) as! CountTextCellView
            cell.setText(countText())
            return cell
        }
        else {
            let card = cards[row]
            let cell = CardCellView()
            cell.card = card
            cell.playerType = self.playerType
            cell.setDelegate(self)
            
            if card.hasChanged {
                card.hasChanged = false
            }
            return cell
        }
    }
    
    func countText() -> String {
        if let player = player {
            var str = "\(NSLocalizedString("Hand", comment: "")) : \(player.handCount)"
                + " / "
                + "\(NSLocalizedString("Deck", comment: "")) : \(player.deckCount)\n"
            
            let cardCount = player.deckCount
            if cardCount > 0 {
                var percent = (1 * 100.0) / Double(cardCount)
                str += String(format: "[1] : %.2f%", percent)
                str += " / "
                percent = (2 * 100.0) / Double(cardCount)
                str += String(format: "[2] : %.2f%", percent)
            }
            
            return str
        }
        return ""
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if row >= cards.count {
            var ratio: CGFloat
            switch Settings.instance.cardSize {
            case .Small: ratio = CGFloat(kRowHeight / kSmallRowHeight)
            case .Medium: ratio = CGFloat(kRowHeight / kMediumRowHeight)
            default: ratio = 1.0
            }
            return 50.0 / ratio
        }
        else {
            switch Settings.instance.cardSize {
            case .Small:
                return CGFloat(kSmallRowHeight)
                
            case .Medium:
                return CGFloat(kMediumRowHeight)
                
            default:
                return CGFloat(kRowHeight)
            }
        }
    }
    
    func selectionShouldChangeInTableView(tableView: NSTableView) -> Bool {
        return false;
    }
    
    // MARK: - CardCellHover
    func hover(card: Card) {
        // DDLogInfo("hovering \(card)")
    }
    
    func out(card: Card) {
        // DDLogInfo(@"out \(card)")
    }
    
    // MARK: - Game
    func gameStart() {
        self.gameEnded = false
        cards.removeAll()
        update()
    }
    
    func gameEnd() {
        self.gameEnded = true
    }
    
    func update() {
        guard let _ = self.table else { return }
        
        if let playerType = self.playerType,
            let player = self.player {
                switch playerType {
                case .Player:
                    self.cards = player.displayCards()
                default:
                    self.cards = player.displayReveleadCards()
                }
                table.reloadData()
        }
    }
}
