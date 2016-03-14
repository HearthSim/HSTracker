//
//  SizeHelper.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class SizeHelper {
    private static var _hearthstoneFrame: NSRect?

    // Get the frame of the Hearthstone window.
    // The size is reduced with the title bar height
    static func hearthstoneFrame() -> NSRect? {
        // TODO need a way to check moving Hearthstone window and reset @hearthstone_frame
        if let _hearthstoneFrame = _hearthstoneFrame {
            return _hearthstoneFrame
        }

        let options = CGWindowListOption(arrayLiteral: .ExcludeDesktopElements, .OptionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        if let infoList = windowListInfo as NSArray? as? [[String: AnyObject]] {
            if let hearthstone = infoList.filter({
                !$0.filter({
                    $0.0 == "kCGWindowName" && $0.1 as? String == "Hearthstone"
                }).isEmpty
            }).first {
                if let dict = hearthstone["kCGWindowBounds"] {
                    if let x = dict["X"] as? CGFloat, y = dict["Y"] as? CGFloat,
                        width = dict["Width"] as? CGFloat, height = dict["Height"] as? CGFloat {
                            var bounds = NSRect(x: x, y: y, width: width, height: height)
                            // remove the titlebar from the height
                            bounds.size.height -= titleBarHeight()
                            // add the titlebar to y
                            bounds.origin.y += titleBarHeight()

                            _hearthstoneFrame = bounds
                            DDLogVerbose("HSFrame : \(_hearthstoneFrame)")
                            return _hearthstoneFrame
                    }
                }
            }
        }

        return nil
    }

    // Get the title bar height
    // I could fix it at 22, but IDK if it's change on retina ie
    private static var _titleBarHeight: CGFloat?
    private static func titleBarHeight() -> CGFloat {
        if let _titleBarHeight = _titleBarHeight {
            return _titleBarHeight
        }

        _titleBarHeight = NSHeight(NSWindow.frameRectForContentRect(NSMakeRect(0, 0, 100, 100), styleMask: NSTitledWindowMask)) - CGFloat(100)
        return _titleBarHeight!
    }

    /**
     * Get a frame relative to Hearthstone window
     * All size are taken from a resolution of 1404*840 (my MBA resolution)
     * and translated to your resolution
     */
    static func frameRelativeToHearthstone(frame: NSRect, _ relative: Bool = false) -> NSRect? {
        if let hsFrame = hearthstoneFrame() {
            var pointX = frame.origin.x
            var pointY = frame.origin.y
            let width = frame.size.width
            let height = frame.size.height

            let screenRect = NSScreen.mainScreen()!.frame

            if relative {
                pointX = pointX / CGFloat(1404.0) * hsFrame.size.width
                pointY = pointY / CGFloat(840.0) * hsFrame.size.height
            }

            let x = hsFrame.origin.x + pointX
            let y = screenRect.size.height - hsFrame.origin.y - height - pointY

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
        if let hearthstoneWindow = self.hearthstoneFrame() {
            let frame = NSMakeRect(hearthstoneWindow.size.width - CGFloat(width), 0, CGFloat(width), hearthstoneWindow.size.height)
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
        if let hearthstoneWindow = self.hearthstoneFrame() {
            let frame = NSMakeRect(0, 0, CGFloat(width), hearthstoneWindow.size.height)
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
        if let _ = self.hearthstoneFrame() {
            let frame = NSMakeRect(200, 50, CGFloat(width), 300)
            return frameRelativeToHearthstone(frame)
        }
        return nil
    }

    static func timerHudFrame() -> NSRect? {
        if let _ = self.hearthstoneFrame() {
            let frame = NSMakeRect(1000.0, 330.0, 160, 115)
            return frameRelativeToHearthstone(frame, true)
        }
        return nil
    }

    static func playerCardCountFrame() -> NSRect? {
        if let hearthstoneWindow = self.hearthstoneFrame() {
            let frame = NSMakeRect(hearthstoneWindow.size.width - 435 - 225, 275, 225, 60)
            return frameRelativeToHearthstone(frame)
        }
        return nil
    }

    static func opponentCardCountFrame() -> NSRect? {
        if let hearthstoneWindow = self.hearthstoneFrame() {
            let frame = NSMakeRect(415, hearthstoneWindow.size.height - 255, 225, 40)
            return frameRelativeToHearthstone(frame)
        }
        return nil
    }

    static func opponentCardHudFrame(position: Int, _ cardCount: Int) -> NSRect? {
        let points = [
            [[671.5, 20]],
            [[628.5, 20], [715.5, 20]],
            [[578.5, 10], [672.5, 20], [764.5, 7]],
            [[567.5, -2], [637.5, 15], [706.5, 20], [776.5, 11]],
            [[561.5, 5], [616.5, 17], [671.5, 22], [729.5, 16], [786.5, 3]],
            [[554.5, -10], [602.5, 7], [648.5, 16], [696.5, 19], [743.5, 16], [791.5, 5]],
            [[551.5, -6], [591.5, 7], [631.5, 16], [671.5, 20], [711.5, 18], [751.5, 9], [794.5, -3]],
            [[545.5, -11], [581.5, -3], [616.5, 9], [652.5, 17], [686.5, 20], [723.5, 18], [759.5, 11], [797.5, 0]],
            [[541.5, -10], [573.5, 0], [603.5, 10], [633.5, 19], [665.5, 20], [697.5, 20], [728.5, 13], [762.5, 3], [795.5, -12]],
            [[529.5, -10], [560.5, -9], [590.5, 0], [618.5, 9], [646.5, 16], [675.5, 20], [704.5, 17], [732.5, 10], [762.5, 3], [797.5, -11]]
        ]

        let hearthstoneWindow = self.hearthstoneFrame()
        if let _ = hearthstoneWindow {
            var frame = NSMakeRect(0, 0, 70, 80)

            if let pos = points[cardCount - 1]?[position] {
                frame.origin.x = pos[0]
                frame.origin.y = pos[1]
            }

            return frameRelativeToHearthstone(frame, true)
        }

        return nil
    }
}