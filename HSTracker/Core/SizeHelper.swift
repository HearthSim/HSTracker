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
    
    static let BaseWidth: CGFloat = 1420.0
    static let BaseHeight: CGFloat = 840.0

    class HearthstoneWindow {
        var _frame = NSZeroRect
        var windowId: CGWindowID?
        
        init() {
            reload()
        }
        
        func reload() {
            let options = CGWindowListOption(arrayLiteral: .ExcludeDesktopElements)
            let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
            if let info = (windowListInfo as NSArray? as? [[String: AnyObject]])?.filter({
                !$0.filter({ $0.0 == "kCGWindowName"
                    && $0.1 as? String == Hearthstone.instance.applicationName }).isEmpty
            }).first {
                if let id = info["kCGWindowNumber"] as? Int {
                    self.windowId = CGWindowID(id)
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
                
                var screenFrame: NSRect?
                for currentDisplay in onlineDisplays[0 ..< Int(displayCount)] {
                    let bounds = CGDisplayBounds(currentDisplay)
                    if bounds.contains(rect) {
                        screenFrame = bounds
                        for screen in NSScreen.screens()! {
                            var displays = [CGDirectDisplayID](count: Int(maxDisplays),
                                                               repeatedValue: 0)
                            let frame = screen.frame
                            
                            CGGetDisplaysWithRect(frame, maxDisplays, &displays, &displayCount)
                            if displays.first == currentDisplay {
                                screenFrame = screen.visibleFrame
                                break
                            }
                        }
                        break
                    }
                }
                
                //Log.verbose?.message("rect : \(rect) / screenFrame : \(screenFrame)")
                if let screenFrame = screenFrame {
                    // cgwindow 0,0 is top:left, convert to bottom:left
                    rect.origin.y = NSHeight(screenFrame) - NSMinY(rect) - NSHeight(rect)
                    if NSMinY(screenFrame) < 0 {
                        rect.origin.y += NSMinY(screenFrame)
                    }
                }
                self._frame = rect
            }
        }
        
        private var width: CGFloat {
            return NSWidth(_frame)
        }
        
        private var height: CGFloat {
            let height = NSHeight(_frame)
            return isFullscreen() ? height : max(height - 22, 0)
        }
        
        private var left: CGFloat {
            return NSMinX(_frame)
        }
        
        private var top: CGFloat {
            return NSMinY(_frame) + (isFullscreen() ? 0 : 22)
        }
        
        private func isFullscreen() -> Bool {
            // this is not the most elegant solution, but I couldn't find a better way
            return NSMinX(_frame) == 0.0 && NSMinY(_frame) == 0.0
                && (Int(NSHeight(_frame)) & 22) != 22
        }
        
        var frame: NSRect {
            return NSRect(x: left, y: top, width: width, height: height)
        }
        
        //
        // Get a frame relative to Hearthstone window
        // All size are taken from a resolution of BaseWidth*BaseHeight (my MBA resolution)
        // and translated to your resolution
        //
        func relativeFrame(frame: NSRect, relative: Bool = true) -> NSRect {
            var pointX = NSMinX(frame)
            var pointY = NSMinY(frame)
            let width = NSWidth(frame)
            let height = NSHeight(frame)
            
            let hearthstoneFrame = hearthstoneWindow.frame
            
            if relative {
                pointX = pointX / SizeHelper.BaseWidth * NSWidth(hearthstoneFrame)
                pointY = pointY / SizeHelper.BaseHeight * NSHeight(hearthstoneFrame)
            }
            
            let x: CGFloat = NSMinX(hearthstoneFrame) + pointX
            let y: CGFloat = NSMaxY(hearthstoneFrame) - pointY - height
            
            let relativeFrame = NSRect(x: x, y: y, width: width, height: height)
            //Log.verbose?.message("FR:\(frame) -> HS:\(hearthstoneFrame) -> POS:\(relativeFrame)")
            return relativeFrame
        }
        
        func screenshot() -> NSImage? {
            return screenshot(x: 0,
                              y: 0,
                              width: NSWidth(frame),
                              height: NSHeight(frame))
        }
        
        func screenshot(x x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSImage? {
            guard let windowId = self.windowId else { return nil }
            
            let rect = relativeFrame(NSRect(
                x: x + NSMinX(frame),
                y: y + NSMinY(frame), // + 30,
                width: width,
                height: height))
            
            if let image = CGWindowListCreateImage(rect,
                                                   .OptionIncludingWindow,
                                                   windowId,
                                                   [.NominalResolution, .BoundsIgnoreFraming]) {
                return NSImage(CGImage: image, size: NSSize(width: width, height: height))
            }
            
            return nil
        }
    }

    static let hearthstoneWindow = HearthstoneWindow()

    static func overHearthstoneFrame() -> NSRect {
        let frame = hearthstoneWindow.frame

        return hearthstoneWindow.relativeFrame(frame)
    }
    
    static private var trackerWidth: CGFloat {
        var width: Double
        switch Settings.instance.cardSize {
        case .Small:
            width = kSmallFrameWidth
        case .Medium:
            width = kMediumFrameWidth
        default:
            width = kFrameWidth
        }
        return CGFloat(width)
    }
    
    static private func trackerFrame(x: CGFloat) -> NSRect {
        // game menu
        let offset: CGFloat = 50
        let frame = NSRect(x: x,
                           y: 0,
                           width: trackerWidth,
                           height: SizeHelper.BaseHeight - offset)
        return hearthstoneWindow.relativeFrame(frame, relative: false)
    }

    static func playerTrackerFrame() -> NSRect {
        return trackerFrame(NSWidth(hearthstoneWindow.frame) - trackerWidth)
    }

    static func opponentTrackerFrame() -> NSRect {
        return trackerFrame(0)
    }
    
    static func playerBoardDamageFrame() -> NSRect {
        let frame = NSRect(x: 910, y: 580.0, width: 50.0, height: 50.0)
        return hearthstoneWindow.relativeFrame(frame)
    }
    
    static func opponentBoardDamageFrame() -> NSRect {
        let frame = NSRect(x: 910, y: 190.0, width: 50.0, height: 50.0)
        return hearthstoneWindow.relativeFrame(frame)
    }

    static func secretTrackerFrame() -> NSRect {
        let frame = NSRect(x: 200,
                           y: 50,
                           width: trackerWidth,
                           height: 450)
        return hearthstoneWindow.relativeFrame(frame)
    }

    static func timerHudFrame() -> NSRect {
        let frame = NSRect(x: 1042.0,
                           y: 337.0,
                           width: 160.0,
                           height: 115.0)
        return hearthstoneWindow.relativeFrame(frame)
    }

    static let points: [Int: [NSPoint]] = [
        1: [NSPoint(x: 647.5, y: 27.0)],
        2: [NSPoint(x: 608.5, y: 30.0), NSPoint(x: 699.5, y: 30.0)],
        3: [NSPoint(x: 554.5, y: 8.0), NSPoint(x: 652.5, y: 22.0), NSPoint(x: 753.5, y: 19.0)],
        4: [NSPoint(x: 538.5, y: 1.0), NSPoint(x: 612.5, y: 22.0), NSPoint(x: 689.5, y: 25.0),
            NSPoint(x: 761.5, y: 24.0)],
        5: [NSPoint(x: 533.5, y: 2.0), NSPoint(x: 594.5, y: 21.0), NSPoint(x: 651.5, y: 26.0),
            NSPoint(x: 712.5, y: 26.0), NSPoint(x: 770.5, y: 13.0)],
        6: [NSPoint(x: 530.5, y: -7.0), NSPoint(x: 573.5, y: 11.0), NSPoint(x: 624.5, y: 27.0),
            NSPoint(x: 673.5, y: 30.0), NSPoint(x: 723.5, y: 30.0), NSPoint(x: 774.5, y: 24.0)],
        7: [NSPoint(x: 527.5, y: -1.0), NSPoint(x: 562.5, y: 13.0), NSPoint(x: 606.5, y: 25.0),
            NSPoint(x: 651.5, y: 33.0), NSPoint(x: 691.5, y: 31.0), NSPoint(x: 735.5, y: 22.0),
            NSPoint(x: 776.5, y: 9.0)],
        8: [NSPoint(x: 535.5, y: -10.0), NSPoint(x: 574.5, y: 1.0), NSPoint(x: 613.5, y: 10.0),
            NSPoint(x: 649.5, y: 19.0), NSPoint(x: 685.5, y: 26.0), NSPoint(x: 721.5, y: 23.0),
            NSPoint(x: 758.5, y: 17.0), NSPoint(x: 800.5, y: 5.0)],
        9: [NSPoint(x: 536.5, y: -15.0), NSPoint(x: 572.5, y: 1.0), NSPoint(x: 604.5, y: 10.0),
            NSPoint(x: 633.5, y: 19.0), NSPoint(x: 664.5, y: 26.0), NSPoint(x: 698.5, y: 24.0),
            NSPoint(x: 731.5, y: 18.0), NSPoint(x: 763.5, y: 7.0), NSPoint(x: 796.5, y: -5.0)],
        10: [NSPoint(x: 537.5, y: -18.0), NSPoint(x: 562.5, y: -10.0), NSPoint(x: 591.5, y: -1.0),
            NSPoint(x: 620.5, y: 8.0), NSPoint(x: 645.5, y: 15.0), NSPoint(x: 675.5, y: 19.0),
            NSPoint(x: 705.5, y: 16.0), NSPoint(x: 734.5, y: 9.0), NSPoint(x: 765.5, y: 2.0),
            NSPoint(x: 799.5, y: -12.0)]
    ]

    static func opponentCardHudFrame(position: Int, cardCount: Int) -> NSRect {
        var frame = NSRect(x: 0, y: 0, width: 36, height: 45)

        if let numCards = points[cardCount] where numCards.count > position {
            let pos = points[cardCount]![position]
            frame.origin.x = pos.x
            frame.origin.y = pos.y
        }

        return hearthstoneWindow.relativeFrame(frame)
    }
}
