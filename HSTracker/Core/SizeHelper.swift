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
        var screenRect: NSRect = NSRect()
        
        init() {
            reload()
        }
        
        func reload() {
            let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements)
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
                // swiftlint:disable force_cast
                let bounds = info["kCGWindowBounds"] as! CFDictionary
                // swiftlint:enable force_cast
                if let rect = CGRect(dictionaryRepresentation: bounds) {
                    var frame = rect

                    // Warning: this function assumes that the
                    // first screen in the list is the active one
                    if let screen = NSScreen.screens()?.first {
                        screenRect = screen.frame
                        frame.origin.y = screen.frame.maxY - rect.maxY
                    }

                    Log.debug?.message("HS Frame is : \(rect)")
                    self._frame = frame
                }
            }
        }
        
        fileprivate var width: CGFloat {
            return _frame.width
        }
        
        fileprivate var height: CGFloat {
            let height = _frame.height
            return isFullscreen() ? height : max(height - 22, 0)
        }
        
        fileprivate var left: CGFloat {
            return _frame.minX
        }
        
        fileprivate var top: CGFloat {
            return _frame.minY
        }
        
        fileprivate func isFullscreen() -> Bool {
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
        func relativeFrame(_ frame: NSRect, relative: Bool = true) -> NSRect {
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
                                                   .optionIncludingWindow,
                                                   windowId,
                                                   [.nominalResolution, .boundsIgnoreFraming]) {
                
                return NSImage(cgImage: image,
                               size: NSSize(width: image.width,
                                height: image.height))
            }
            
            return nil
        }
    }

    static let hearthstoneWindow = HearthstoneWindow()

    static func overHearthstoneFrame() -> NSRect {
        let frame = hearthstoneWindow.frame

        return hearthstoneWindow.relativeFrame(frame)
    }
    
    static fileprivate var trackerWidth: CGFloat {
        var width: Double
        switch Settings.instance.cardSize {
        case .tiny: width = kTinyFrameWidth
        case .small: width = kSmallFrameWidth
        case .medium: width = kMediumFrameWidth
        case .big: width = kFrameWidth
        case .huge: width = kHighRowFrameWidth
        }
        return CGFloat(width)
    }
    
    static fileprivate func trackerFrame(_ x: CGFloat) -> NSRect {
        // game menu
        let offset: CGFloat = hearthstoneWindow.isFullscreen() ? 0 : 50
        let width: CGFloat
        switch Settings.instance.cardSize {
        case .tiny: width = CGFloat(kTinyFrameWidth)
        case .small: width = CGFloat(kSmallFrameWidth)
        case .medium: width = CGFloat(kMediumFrameWidth)
        case .big: width = CGFloat(kFrameWidth)
        case .huge: width = CGFloat(kHighRowFrameWidth)
        }
        
        let frame = NSRect(x: x,
                           y: offset,
                           width: max(trackerWidth, width),
                           height: max(100, hearthstoneWindow.frame.height - offset))
        return hearthstoneWindow.relativeFrame(frame, relative: false)
    }

    fileprivate static func getScaledXPos(_ left: CGFloat, width: CGFloat,
                                          ratio: CGFloat) -> CGFloat {
        return ((width) * ratio * left) + (width * (1 - ratio) / 2)
    }

    static func searchLocation() -> NSPoint {
        let hsRect = hearthstoneWindow.frame
        let ratio = (4.0 / 3.0) / (hsRect.width / hsRect.height)
        let exportSearchBoxX: CGFloat = 0.5
        let exportSearchBoxY: CGFloat = 0.915
        var loc = NSPoint(x: getScaledXPos(exportSearchBoxX, width: hsRect.width, ratio: ratio),
                          y: exportSearchBoxY * hsRect.height)

        // correct location with window origin.
        loc.x += hsRect.origin.x
        loc.y = loc.y + (
            hearthstoneWindow.screenRect.height - hsRect.origin.y - hsRect.size.height)
        return loc
    }

    static func firstCardFrame() -> NSRect {
        let location = firstCardLocation()
        return NSRect(x: location.x - 100,
                      y: location.y + 180,
                      width: 300,
                      height: 100)
    }

    static func firstCardLocation() -> NSPoint {
        let hsRect = hearthstoneWindow.frame
        let ratio = (4.0 / 3.0) / (hsRect.width / hsRect.height)
        let cardPosOffset: CGFloat = 50
        let exportCard1X: CGFloat = 0.04
        let exportCard1Y: CGFloat = 0.168

        let cardPosX = getScaledXPos(exportCard1X, width: hsRect.width, ratio: ratio)
        let cardPosY = exportCard1Y * hsRect.height
        var loc = NSPoint(x: cardPosX + cardPosOffset, y: cardPosY + cardPosOffset)

        // correct location with window origin.
        loc.x += hsRect.origin.x
        loc.y = loc.y + (hearthstoneWindow.screenRect.height - hsRect.origin.y - hsRect.size.height)
        return loc
    }

    static func secondCardLocation() -> NSPoint {
        var loc = firstCardLocation()

        loc.x += 190
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
        let frame = NSRect(x: 200, y: hearthstoneWindow.frame.height - 550,
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
