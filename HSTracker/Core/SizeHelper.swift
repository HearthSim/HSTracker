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
        var _frame = NSRect.zero
        var windowId: CGWindowID?
        var screenrect: NSRect = NSRect()
        
        init() {
            reload()
        }
        
        func reload() {
            let options = CGWindowListOption(arrayLiteral: .ExcludeDesktopElements)
            let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
            if let info = (windowListInfo as NSArray? as? [[String: AnyObject]])?.filter({
                !$0.filter({ $0.0 == "kCGWindowName"
                    && $0.1 as? String == Hearthstone.instance.applicationName }).isEmpty
            }).filter({
                !$0.filter({ $0.0 == "kCGWindowOwnerName"
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
                
                // Warning: this function assumes that the 
                // first screen in the list is the active one
                if let screen = NSScreen.screens()?.first {
                    screenrect = screen.frame
                    rect.origin.y = screen.frame.maxY - rect.maxY
                }
                
                Log.debug?.message("HS Frame is : \(rect)")
                self._frame = rect
            }
        }
        
        private var width: CGFloat {
            return _frame.width
        }
        
        private var height: CGFloat {
            let height = _frame.height
            return isFullscreen() ? height : max(height - 22, 0)
        }
        
        private var left: CGFloat {
            return _frame.minX
        }
        
        private var top: CGFloat {
            return _frame.minY
        }
        
        private func isFullscreen() -> Bool {
            return _frame.minX == 0.0 && _frame.minY == 0.0
                && (Int(_frame.height) & 22) != 22
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
            var pointX = frame.minX
            var pointY = frame.minY
            let width = frame.width
            let height = frame.height
            
            if relative {
                pointX = pointX * scaleX
                pointY = pointY * scaleY
            }
            
            let x: CGFloat = self.frame.minX + pointX
            let y: CGFloat = self.frame.minY + pointY
            
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
        let offset: CGFloat = hearthstoneWindow.isFullscreen() ? 0 : 50
        let width: CGFloat
        switch Settings.instance.cardSize {
        case .Small:
            width = CGFloat(kSmallFrameWidth)
            
        case .Medium:
            width = CGFloat(kMediumFrameWidth)
            
        default:
            width = CGFloat(kFrameWidth)
        }
        
        let frame = NSRect(x: x,
                           y: offset,
                           width: max(trackerWidth, width),
                           height: max(100, hearthstoneWindow.frame.height - offset))
        return hearthstoneWindow.relativeFrame(frame, relative: false)
    }
    
    private static func GetScaledXPos(left: CGFloat, width: CGFloat, ratio: CGFloat) -> CGFloat {
        return ((width) * ratio * left) + (width * (1 - ratio) / 2)
    }
    
    static func searchLocation() -> NSPoint {
        let HsRect = hearthstoneWindow.frame
        let ratio = (4.0 / 3.0) / (HsRect.width / HsRect.height)
        let ExportSearchBoxX: CGFloat = 0.5
        let ExportSearchBoxY: CGFloat = 0.915
        var loc: NSPoint = NSPoint(x: GetScaledXPos(
            ExportSearchBoxX, width: HsRect.width, ratio: ratio),
                                   y:ExportSearchBoxY * HsRect.height)
        
        // correct location with window origin.
        loc.x += HsRect.origin.x
        loc.y = loc.y + (
            hearthstoneWindow.screenrect.height - HsRect.origin.y - HsRect.size.height)
        return loc
    }
    
    static func firstCardLocation() -> NSPoint {
        let HsRect = hearthstoneWindow.frame
        let ratio = (4.0 / 3.0) / (HsRect.width / HsRect.height)
        let CardPosOffset: CGFloat = 50
        let ExportCard1X: CGFloat = 0.04
        let ExportCard1Y: CGFloat = 0.168
        
        let CardPosX: CGFloat = GetScaledXPos(ExportCard1X, width: HsRect.width, ratio: ratio)
        let CardPosY: CGFloat = ExportCard1Y * HsRect.height
        var loc: NSPoint = NSPoint(x: CardPosX+CardPosOffset, y: CardPosY+CardPosOffset)
        
        // correct location with window origin.
        loc.x += HsRect.origin.x
        loc.y = loc.y + (
            hearthstoneWindow.screenrect.height - HsRect.origin.y - HsRect.size.height)
        return loc
    }

    static func playerTrackerFrame() -> NSRect {
        return trackerFrame(hearthstoneWindow.frame.width - trackerWidth)
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
        let frame = NSRect(x: 200, y: hearthstoneWindow.frame.height - 500,
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
        let frame = NSRect(x: (hearthstoneWindow.frame.width / 2) - (w / 2),
                           y: hearthstoneWindow.frame.height - h,
                           width: w, height: h)
        return hearthstoneWindow.relativeFrame(frame, relative: false)
    }
}
