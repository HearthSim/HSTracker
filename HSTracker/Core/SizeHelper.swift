//
//  SizeHelper.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

struct SizeHelper {
    
    class HearthstoneWindow {
        var frame = NSZeroRect
        var windowId: Int?
        var screen: NSScreen {
            let hsFrame = frame
            for screen in NSScreen.screens()! {
                let screenBounds = screen.frame
                if screenBounds.contains(hsFrame) {
                    return screen
                }
            }
            return NSScreen.mainScreen()!
        }
        
        init() {
            reload()
        }
        
        // Get the title bar height
        // I could fix it at 22, but IDK if it's change on retina ie
        private var titleBarHeight: CGFloat = {
            let height: CGFloat = 100
            return NSHeight(NSWindow.frameRectForContentRect(NSMakeRect(0, 0, height, height), styleMask: NSTitledWindowMask)) - height
        }()
        
        func reload() {
            let options = CGWindowListOption(arrayLiteral: .ExcludeDesktopElements)
            let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
            if let info = (windowListInfo as NSArray? as? [[String: AnyObject]])?.filter({
                !$0.filter({ $0.0 == "kCGWindowName" && $0.1 as? String == "Hearthstone" }).isEmpty
            }).first {
                if let id = info["kCGWindowNumber"] as? Int {
                    self.windowId = id
                }
                var rect = NSRect()
                let bounds = info["kCGWindowBounds"] as! CFDictionary
                CGRectMakeWithDictionaryRepresentation(bounds, &rect)
                
                // remove the titlebar from the height
                rect.size.height -= titleBarHeight
                // add the titlebar to y
                rect.origin.y += titleBarHeight
                self.frame = rect
            }
        }
    }
    
    private static let hearthstoneWindow = HearthstoneWindow()

    /**
     * Get a frame relative to Hearthstone window
     * All size are taken from a resolution of 1404*840 (my MBA resolution)
     * and translated to your resolution
     */
    static func frameRelativeToHearthstone(frame: NSRect, _ relative: Bool = false) -> NSRect {
        var pointX = frame.origin.x
        var pointY = frame.origin.y
        let width = NSWidth(frame)
        let height = NSHeight(frame)
        
        let hearthstoneFrame = hearthstoneWindow.frame
        let screenRect = hearthstoneWindow.screen.frame
        
        if relative {
            pointX = pointX / 1404.0 * NSWidth(hearthstoneFrame)
            pointY = pointY / 840.0 * NSHeight(hearthstoneFrame)
        }
        
        let x = hearthstoneFrame.origin.x + pointX
        let y = NSHeight(screenRect) - hearthstoneFrame.origin.y - height - pointY
        
        return NSMakeRect(x, y, width, height)
    }

    static func playerTrackerFrame() -> NSRect {
        var width: Double
        switch Settings.instance.cardSize {
        case .Small:
            width = kSmallFrameWidth
        case .Medium:
            width = kMediumFrameWidth
        default:
            width = kFrameWidth
        }

        // game menu
        let offset: CGFloat = 50
        let frame = NSMakeRect(NSWidth(hearthstoneWindow.frame) - CGFloat(width), 0, CGFloat(width), NSHeight(hearthstoneWindow.frame) - offset)
        return frameRelativeToHearthstone(frame)
    }

    static func opponentTrackerFrame() -> NSRect {
        var width: Double
        switch Settings.instance.cardSize {
        case .Small:
            width = kSmallFrameWidth
        case .Medium:
            width = kMediumFrameWidth
        default:
            width = kFrameWidth
        }

        // friend list button
        let offset: CGFloat = 50
        let frame = NSMakeRect(0, 0, CGFloat(width), NSHeight(hearthstoneWindow.frame) - offset)
        return frameRelativeToHearthstone(frame)
    }

    static func secretTrackerFrame() -> NSRect {
        var width: Double
        switch Settings.instance.cardSize {
        case .Small:
            width = kSmallFrameWidth
        case .Medium:
            width = kMediumFrameWidth
        default:
            width = kFrameWidth
        }
        
        let frame = NSMakeRect(200, 50, CGFloat(width), 450)
        return frameRelativeToHearthstone(frame, true)
    }

    static func timerHudFrame() -> NSRect {
        let frame = NSMakeRect(1042.0, 337.0, 160.0, 115.0)
        return frameRelativeToHearthstone(frame, true)
    }
    
    static let points: [Int: [NSPoint]] = [
        1: [NSMakePoint(647.5, 27.0)],
        2: [NSMakePoint(608.5, 30.0), NSMakePoint(699.5, 30.0)],
        3: [NSMakePoint(554.5, 8.0), NSMakePoint(652.5, 22.0), NSMakePoint(753.5, 19.0)],
        4: [NSMakePoint(538.5, 1.0), NSMakePoint(612.5, 22.0), NSMakePoint(689.5, 25.0), NSMakePoint(761.5, 24.0)],
        5: [NSMakePoint(533.5, 2.0), NSMakePoint(594.5, 21.0), NSMakePoint(651.5, 26.0), NSMakePoint(712.5, 26.0), NSMakePoint(770.5, 13.0)],
        6: [NSMakePoint(530.5, -7.0), NSMakePoint(573.5, 11.0), NSMakePoint(624.5, 27.0), NSMakePoint(673.5, 30.0), NSMakePoint(723.5, 30.0), NSMakePoint(774.5, 24.0)],
        7: [NSMakePoint(527.5, -1.0), NSMakePoint(562.5, 13.0), NSMakePoint(606.5, 25.0), NSMakePoint(651.5, 33.0), NSMakePoint(691.5, 31.0), NSMakePoint(735.5, 22.0), NSMakePoint(776.5, 9.0)],
        8: [NSMakePoint(535.5, -10.0), NSMakePoint(574.5, 1.0), NSMakePoint(613.5, 10.0), NSMakePoint(649.5, 19.0), NSMakePoint(685.5, 26.0), NSMakePoint(721.5, 23.0), NSMakePoint(758.5, 17.0), NSMakePoint(800.5, 5.0)],
        9: [NSMakePoint(536.5, -15.0), NSMakePoint(572.5, 1.0), NSMakePoint(604.5, 10.0), NSMakePoint(633.5, 19.0), NSMakePoint(664.5, 26.0), NSMakePoint(698.5, 24.0), NSMakePoint(731.5, 18.0), NSMakePoint(763.5, 7.0), NSMakePoint(796.5, -5.0)],
        10: [NSMakePoint(537.5, -18.0), NSMakePoint(562.5, -10.0), NSMakePoint(591.5, -1.0), NSMakePoint(620.5, 8.0), NSMakePoint(645.5, 15.0), NSMakePoint(675.5, 19.0), NSMakePoint(705.5, 16.0), NSMakePoint(734.5, 9.0), NSMakePoint(765.5, 2.0), NSMakePoint(799.5, -12.0)]
    ]

    static func opponentCardHudFrame(position: Int, _ cardCount: Int) -> NSRect {
        var frame = NSMakeRect(0, 0, 36, 45)
        
        if let numCards = points[cardCount] where numCards.count > position {
            let pos = points[cardCount]![position]
            frame.origin.x = pos.x
            frame.origin.y = pos.y
        }
        
        return frameRelativeToHearthstone(frame, true)
    }
}