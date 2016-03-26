//
//  SizeHelper.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct SizeHelper {
    
    // Get the title bar height
    // I could fix it at 22, but IDK if it's change on retina ie
    private static var titleBarHeight: CGFloat = {
        return NSHeight(NSWindow.frameRectForContentRect(NSMakeRect(0, 0, 100, 100), styleMask: NSTitledWindowMask)) - CGFloat(100)
    }()

    // Get the frame of the Hearthstone window.
    // The size is reduced with the title bar height
    private static var hearthstoneFrame: NSRect? = {
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
                
                DDLogVerbose("HSFrame : \(bounds)")
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
    static func frameRelativeToHearthstone(frame: NSRect, _ relative: Bool = false) -> NSRect? {
        if let hsFrame = hearthstoneFrame {
            var pointX = frame.origin.x
            var pointY = frame.origin.y
            let width = NSWidth(frame)
            let height = NSHeight(frame)

            let screenRect = NSScreen.mainScreen()!.frame

            if relative {
                pointX = pointX / CGFloat(1404.0) * NSWidth(hsFrame)
                pointY = pointY / CGFloat(840.0) * NSHeight(hsFrame)
            }

            let x = hsFrame.origin.x + pointX
            let y = NSHeight(screenRect) - hsFrame.origin.y - height - pointY

            return NSMakeRect(x, y, width, height)
        }
        return nil
    }

    static func playerTrackerFrame() -> NSRect? {
        var width: Double
        switch Settings.instance.cardSize {
        case .Small:
            width = kSmallFrameWidth
        case .Medium:
            width = kMediumFrameWidth
        default:
            width = kFrameWidth
        }
        if let hearthstoneWindow = hearthstoneFrame {
            let frame = NSMakeRect(NSWidth(hearthstoneWindow) - CGFloat(width), 0, CGFloat(width), NSHeight(hearthstoneWindow))
            return frameRelativeToHearthstone(frame)
        }
        return nil
    }

    static func opponentTrackerFrame() -> NSRect? {
        var width: Double
        switch Settings.instance.cardSize {
        case .Small:
            width = kSmallFrameWidth
        case .Medium:
            width = kMediumFrameWidth
        default:
            width = kFrameWidth
        }
        if let hearthstoneWindow = hearthstoneFrame {
            let frame = NSMakeRect(0, 0, CGFloat(width), NSHeight(hearthstoneWindow))
            return frameRelativeToHearthstone(frame)
        }
        return nil
    }

    static func secretTrackerFrame() -> NSRect? {
        var width: Double
        switch Settings.instance.cardSize {
        case .Small:
            width = kSmallFrameWidth
        case .Medium:
            width = kMediumFrameWidth
        default:
            width = kFrameWidth
        }
        if let _ = hearthstoneFrame {
            let frame = NSMakeRect(200, 50, CGFloat(width), 300)
            return frameRelativeToHearthstone(frame)
        }
        return nil
    }

    static func timerHudFrame() -> NSRect? {
        if let _ = hearthstoneFrame {
            let frame = NSMakeRect(1000.0, 330.0, 160, 115)
            return frameRelativeToHearthstone(frame, true)
        }
        return nil
    }

    static func playerCardCountFrame() -> NSRect? {
        if let hearthstoneWindow = hearthstoneFrame {
            let frame = NSMakeRect(NSWidth(hearthstoneWindow) - 435 - 225, 275, 225, 60)
            return frameRelativeToHearthstone(frame)
        }
        return nil
    }

    static func opponentCardCountFrame() -> NSRect? {
        if let hearthstoneWindow = hearthstoneFrame {
            let frame = NSMakeRect(415, NSHeight(hearthstoneWindow) - 255, 225, 40)
            return frameRelativeToHearthstone(frame)
        }
        return nil
    }

    static let points: [Int: [NSPoint]] = [
        1: [NSMakePoint(671.5, 20)],
        2: [NSMakePoint(628.5, 20), NSMakePoint(715.5, 20)],
        3: [NSMakePoint(578.5, 10), NSMakePoint(672.5, 20), NSMakePoint(764.5, 7)],
        4: [NSMakePoint(567.5, -2), NSMakePoint(637.5, 15), NSMakePoint(706.5, 20), NSMakePoint(776.5, 11)],
        5: [NSMakePoint(561.5, 5), NSMakePoint(616.5, 17), NSMakePoint(671.5, 22), NSMakePoint(729.5, 16), NSMakePoint(786.5, 3)],
        6: [NSMakePoint(554.5, -10), NSMakePoint(602.5, 7), NSMakePoint(648.5, 16), NSMakePoint(696.5, 19), NSMakePoint(743.5, 16), NSMakePoint(791.5, 5)],
        7: [NSMakePoint(551.5, -6), NSMakePoint(591.5, 7), NSMakePoint(631.5, 16), NSMakePoint(671.5, 20), NSMakePoint(711.5, 18), NSMakePoint(751.5, 9), NSMakePoint(794.5, -3)],
        8: [NSMakePoint(545.5, -11), NSMakePoint(581.5, -3), NSMakePoint(616.5, 9), NSMakePoint(652.5, 17), NSMakePoint(686.5, 20), NSMakePoint(723.5, 18), NSMakePoint(759.5, 11), NSMakePoint(797.5, 0)],
        9: [NSMakePoint(541.5, -10), NSMakePoint(573.5, 0), NSMakePoint(603.5, 10), NSMakePoint(633.5, 19), NSMakePoint(665.5, 20), NSMakePoint(697.5, 20), NSMakePoint(728.5, 13), NSMakePoint(762.5, 3), NSMakePoint(795.5, -12)],
        10: [NSMakePoint(529.5, -10), NSMakePoint(560.5, -9), NSMakePoint(590.5, 0), NSMakePoint(618.5, 9), NSMakePoint(646.5, 16), NSMakePoint(675.5, 20), NSMakePoint(704.5, 17), NSMakePoint(732.5, 10), NSMakePoint(762.5, 3), NSMakePoint(797.5, -11)]
    ]

    static func opponentCardHudFrame(position: Int, _ cardCount: Int) -> NSRect? {
        if let _ = hearthstoneFrame {
            var frame = NSMakeRect(0, 0, 36, 45)
            if let pos = points[cardCount]?[position] {
                frame.origin.x = pos.x
                frame.origin.y = pos.y
            }

            return frameRelativeToHearthstone(frame, true)
        }

        return nil
    }
}