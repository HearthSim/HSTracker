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
    
    // Get the title bar height
    // I could fix it at 22, but IDK if it's change on retina ie
    private static var titleBarHeight: CGFloat = {
        return NSHeight(NSWindow.frameRectForContentRect(NSMakeRect(0, 0, 100, 100), styleMask: NSTitledWindowMask)) - CGFloat(100)
    }()

    // Get the frame of the Hearthstone window.
    // The size is reduced with the title bar height
    private static var hearthstoneFrame: NSRect = {
        let options = CGWindowListOption(arrayLiteral: .ExcludeDesktopElements, .OptionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        if let info = (windowListInfo as NSArray? as? [[String: AnyObject]])?.filter({
            !$0.filter({ $0.0 == "kCGWindowName" && $0.1 as? String == "Hearthstone" }).isEmpty
        }).first?["kCGWindowBounds"] {
            if let x = info["X"] as? CGFloat, y = info["Y"] as? CGFloat,
                width = info["Width"] as? CGFloat, height = info["Height"] as? CGFloat {
                var bounds = NSMakeRect(x, y, width, height)
                // remove the titlebar from the height
                bounds.size.height -= titleBarHeight
                // add the titlebar to y
                bounds.origin.y += titleBarHeight
                
                Log.verbose?.message("HSFrame : \(bounds)")
                return bounds
            }
        }

        return NSZeroRect
    }()

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
        
        let screenRect = NSScreen.mainScreen()!.frame
        
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
        let offset: CGFloat = 70
        let frame = NSMakeRect(NSWidth(hearthstoneFrame) - CGFloat(width), 0, CGFloat(width), NSHeight(hearthstoneFrame) - offset)
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
        let offset: CGFloat = 70
        let frame = NSMakeRect(0, 0, CGFloat(width), NSHeight(hearthstoneFrame) - offset)
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
        
        let frame = NSMakeRect(200, 50, CGFloat(width), 300)
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
        
        
        
        8: [NSMakePoint(545.5, -11), NSMakePoint(581.5, -3), NSMakePoint(616.5, 9), NSMakePoint(652.5, 17), NSMakePoint(686.5, 20), NSMakePoint(723.5, 18), NSMakePoint(759.5, 11), NSMakePoint(797.5, 0)],
        9: [NSMakePoint(541.5, -10), NSMakePoint(573.5, 0), NSMakePoint(603.5, 10), NSMakePoint(633.5, 19), NSMakePoint(665.5, 20), NSMakePoint(697.5, 20), NSMakePoint(728.5, 13), NSMakePoint(762.5, 3), NSMakePoint(795.5, -12)],
        10: [NSMakePoint(529.5, -10), NSMakePoint(560.5, -9), NSMakePoint(590.5, 0), NSMakePoint(618.5, 9), NSMakePoint(646.5, 16), NSMakePoint(675.5, 20), NSMakePoint(704.5, 17), NSMakePoint(732.5, 10), NSMakePoint(762.5, 3), NSMakePoint(797.5, -11)]
    ]

    static func opponentCardHudFrame(position: Int, _ cardCount: Int) -> NSRect {
        var frame = NSMakeRect(0, 0, 36, 45)
        if let pos = points[cardCount]?[position] {
            frame.origin.x = pos.x
            frame.origin.y = pos.y
        }
        
        return frameRelativeToHearthstone(frame, true)
    }
}