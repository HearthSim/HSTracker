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
    
    static let BaseWidth: CGFloat = 1440.0
    static let BaseHeight: CGFloat = 922.0

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
               
                if let screen = NSScreen.screens()?.first {
                    rect.origin.y = NSMaxY(screen.frame) - NSMaxY(rect)
                }
                
                Log.debug?.message("HS Frame is : \(rect)")
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
            return NSMinY(_frame)
        }
        
        private func isFullscreen() -> Bool {
            return NSMinX(_frame) == 0.0 && NSMinY(_frame) == 0.0
                && (Int(NSHeight(_frame)) & 22) != 22
        }
        
        var frame: NSRect {
            return NSRect(x: left, y: top, width: width, height: height)
        }
        
        var scaleX: CGFloat {
            return width / SizeHelper.BaseWidth
        }
        
        var scaleY: CGFloat {
            return height / SizeHelper.BaseHeight
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
            
            if relative {
                pointX = pointX * scaleX
                pointY = pointY * scaleY
            }
            
            let x: CGFloat = NSMinX(self.frame) + pointX
            let y: CGFloat = NSMinY(self.frame) + pointY
            
            let relativeFrame = NSRect(x: x, y: y, width: width, height: height)
            //Log.verbose?.message("FR:\(frame) -> HS:\(hearthstoneFrame) -> POS:\(relativeFrame)")
            return relativeFrame
        }
        
        func screenshot() -> NSImage? {
            guard let windowId = self.windowId else { return nil }
            
            if let image = CGWindowListCreateImage(CGRect.null,
                                                   .OptionIncludingWindow,
                                                   windowId,
                                                   [.NominalResolution, .BoundsIgnoreFraming]) {
                
                return NSImage(CGImage: image,
                               size: NSSize(width: CGImageGetWidth(image),
                                height: CGImageGetHeight(image)))
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
                           y: offset,
                           width: trackerWidth,
                           height: NSHeight(hearthstoneWindow.frame) - offset)
        return hearthstoneWindow.relativeFrame(frame, relative: false)
    }

    static func playerTrackerFrame() -> NSRect {
        return trackerFrame(NSWidth(hearthstoneWindow.frame) - trackerWidth)
    }

    static func opponentTrackerFrame() -> NSRect {
        return trackerFrame(0)
    }
    
    static func playerBoardDamageFrame() -> NSRect {
        let frame = NSRect(x: 923.0, y: 225.0, width: 50.0, height: 50.0)
        return hearthstoneWindow.relativeFrame(frame)
    }
    
    static func opponentBoardDamageFrame() -> NSRect {
        let frame = NSRect(x: 915.0, y: 667.0, width: 50.0, height: 50.0)
        return hearthstoneWindow.relativeFrame(frame)
    }

    static func secretTrackerFrame() -> NSRect {
        let frame = NSRect(x: 200, y: NSHeight(hearthstoneWindow.frame) - 500,
                           width: trackerWidth, height: 450)
        
        return hearthstoneWindow.relativeFrame(frame)
    }

    static func timerHudFrame() -> NSRect {
        let frame = NSRect(x: 999.0, y: 423.0, width: 160.0, height: 115.0)
        return hearthstoneWindow.relativeFrame(frame)
    }

    static let cardHudContainerWidth: CGFloat = 400
    static let cardHudContainerHeight: CGFloat = 80
    static func cardHudContainerFrame() -> NSRect {
        let w = SizeHelper.cardHudContainerWidth * hearthstoneWindow.scaleX
        let h = SizeHelper.cardHudContainerHeight * hearthstoneWindow.scaleY
        let frame = NSRect(x: (NSWidth(hearthstoneWindow.frame) / 2) - (w / 2),
                           y: NSHeight(hearthstoneWindow.frame) - h,
                           width: w, height: h)
        return hearthstoneWindow.relativeFrame(frame, relative: false)
    }
}
