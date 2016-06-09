//
//  SizeHelper.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

// swiftlint:disable line_length
struct SizeHelper {

    class HearthstoneWindow {
        var frame = NSZeroRect
        var windowId: Int?
        var screen = NSScreen.mainScreen()!
        var screenFrame = NSZeroRect

        init() {
            reload()
        }

        // Get the title bar height
        // I could fix it at 22, but IDK if it's change on retina ie
        private var titleBarHeight: CGFloat = {
            let height: CGFloat = 100
            return NSHeight(NSWindow.frameRectForContentRect(NSRect(x: 0, y: 0, width: height, height: height),
                styleMask: NSTitledWindowMask)) - height
        }()

        func reload() {
            let options = CGWindowListOption(arrayLiteral: .ExcludeDesktopElements)
            let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
            if let info = (windowListInfo as NSArray? as? [[String: AnyObject]])?.filter({
                !$0.filter({ $0.0 == "kCGWindowName" && $0.1 as? String == Hearthstone.instance.applicationName }).isEmpty
            }).first {
                if let id = info["kCGWindowNumber"] as? Int {
                    self.windowId = id
                }
                var rect = NSRect()
                // swiftlint:disable force_cast
                let bounds = info["kCGWindowBounds"] as! CFDictionary
                // swiftlint:enable force_cast
                CGRectMakeWithDictionaryRepresentation(bounds, &rect)

                let maxDisplays: UInt32 = 16
                var onlineDisplays = [CGDirectDisplayID](count: Int(maxDisplays), repeatedValue: 0)
                var displayCount: UInt32 = 0
                CGGetOnlineDisplayList(maxDisplays, &onlineDisplays, &displayCount)

                for currentDisplay in onlineDisplays[0 ..< Int(displayCount)] {
                    let bounds = CGDisplayBounds(currentDisplay)
                    if bounds.contains(rect) {
                        screenFrame = bounds
                        for screen in NSScreen.screens()! {
                            var displays = [CGDirectDisplayID](count: Int(maxDisplays), repeatedValue: 0)
                            let frame = screen.frame

                            CGGetDisplaysWithRect(frame, maxDisplays, &displays, &displayCount)
                            if displays.first == currentDisplay {
                                self.screen = screen
                                break
                            }
                        }
                    }
                }

                // cgwindow 0,0 is top:left, convert to bottom:left
                rect.origin.y = NSHeight(screenFrame) - NSMinY(rect) - NSHeight(rect)
                if NSMinY(screenFrame) < 0 {
                    rect.origin.y += NSMinY(screenFrame)
                }

                // remove the titlebar from the height
                rect.size.height -= titleBarHeight
                self.frame = rect
            }
        }
    }

    static let hearthstoneWindow = HearthstoneWindow()

    //
    // Get a frame relative to Hearthstone window
    // All size are taken from a resolution of 1404*840 (my MBA resolution)
    // and translated to your resolution
    //
    static func frameRelativeToHearthstone(frame: NSRect, relative: Bool = false) -> NSRect {
        var pointX = NSMinX(frame)
        var pointY = NSMinY(frame)
        let width = NSWidth(frame)
        let height = NSHeight(frame)

        let hearthstoneFrame = hearthstoneWindow.frame
        //let screenRect = hearthstoneWindow.screen.frame

        if relative {
            pointX = pointX / 1404.0 * NSWidth(hearthstoneFrame)
            pointY = pointY / 840.0 * NSHeight(hearthstoneFrame)
        }

        let x: CGFloat = NSMinX(hearthstoneFrame) + pointX
        let y: CGFloat = NSMaxY(hearthstoneFrame) - pointY - height

        let relativeFrame = NSRect(x: x, y: y, width: width, height: height)
        //Log.verbose?.message("FR: \(frame) -> HS: \(hearthstoneFrame) -> SC:\(screenRect) -> POS:\(relativeFrame)")
        return relativeFrame
    }

    static func overHearthstoneFrame() -> NSRect {
        let frame = hearthstoneWindow.frame

        return frameRelativeToHearthstone(frame)
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
        let frame = NSRect(x: NSWidth(hearthstoneWindow.frame) - CGFloat(width),
                           y: 0,
                           width: CGFloat(width),
                           height: NSHeight(hearthstoneWindow.frame) - offset)
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
        let frame = NSRect(x: 0,
                           y: 0,
                           width: CGFloat(width),
                           height: NSHeight(hearthstoneWindow.frame) - offset)
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

        let frame = NSRect(x: 200,
                           y: 50,
                           width: CGFloat(width),
                           height: 450)
        return frameRelativeToHearthstone(frame, relative: true)
    }

    static func timerHudFrame() -> NSRect {
        let frame = NSRect(x: 1042.0,
                           y: 337.0,
                           width: 160.0,
                           height: 115.0)
        return frameRelativeToHearthstone(frame, relative: true)
    }

    static let points: [Int: [NSPoint]] = [
        1: [NSPoint(x: 647.5, y: 27.0)],
        2: [NSPoint(x: 608.5, y: 30.0), NSPoint(x: 699.5, y: 30.0)],
        3: [NSPoint(x: 554.5, y: 8.0), NSPoint(x: 652.5, y: 22.0), NSPoint(x: 753.5, y: 19.0)],
        4: [NSPoint(x: 538.5, y: 1.0), NSPoint(x: 612.5, y: 22.0), NSPoint(x: 689.5, y: 25.0), NSPoint(x: 761.5, y: 24.0)],
        5: [NSPoint(x: 533.5, y: 2.0), NSPoint(x: 594.5, y: 21.0), NSPoint(x: 651.5, y: 26.0), NSPoint(x: 712.5, y: 26.0), NSPoint(x: 770.5, y: 13.0)],
        6: [NSPoint(x: 530.5, y: -7.0), NSPoint(x: 573.5, y: 11.0), NSPoint(x: 624.5, y: 27.0), NSPoint(x: 673.5, y: 30.0), NSPoint(x: 723.5, y: 30.0), NSPoint(x: 774.5, y: 24.0)],
        7: [NSPoint(x: 527.5, y: -1.0), NSPoint(x: 562.5, y: 13.0), NSPoint(x: 606.5, y: 25.0), NSPoint(x: 651.5, y: 33.0), NSPoint(x: 691.5, y: 31.0), NSPoint(x: 735.5, y: 22.0), NSPoint(x: 776.5, y: 9.0)],
        8: [NSPoint(x: 535.5, y: -10.0), NSPoint(x: 574.5, y: 1.0), NSPoint(x: 613.5, y: 10.0), NSPoint(x: 649.5, y: 19.0), NSPoint(x: 685.5, y: 26.0), NSPoint(x: 721.5, y: 23.0), NSPoint(x: 758.5, y: 17.0), NSPoint(x: 800.5, y: 5.0)],
        9: [NSPoint(x: 536.5, y: -15.0), NSPoint(x: 572.5, y: 1.0), NSPoint(x: 604.5, y: 10.0), NSPoint(x: 633.5, y: 19.0), NSPoint(x: 664.5, y: 26.0), NSPoint(x: 698.5, y: 24.0), NSPoint(x: 731.5, y: 18.0), NSPoint(x: 763.5, y: 7.0), NSPoint(x: 796.5, y: -5.0)],
        10: [NSPoint(x: 537.5, y: -18.0), NSPoint(x: 562.5, y: -10.0), NSPoint(x: 591.5, y: -1.0), NSPoint(x: 620.5, y: 8.0), NSPoint(x: 645.5, y: 15.0), NSPoint(x: 675.5, y: 19.0), NSPoint(x: 705.5, y: 16.0), NSPoint(x: 734.5, y: 9.0), NSPoint(x: 765.5, y: 2.0), NSPoint(x: 799.5, y: -12.0)]
    ]

    static func opponentCardHudFrame(position: Int, cardCount: Int) -> NSRect {
        var frame = NSRect(x: 0, y: 0, width: 36, height: 45)

        if let numCards = points[cardCount] where numCards.count > position {
            let pos = points[cardCount]![position]
            frame.origin.x = pos.x
            frame.origin.y = pos.y
        }

        return frameRelativeToHearthstone(frame, relative: true)
    }
}
