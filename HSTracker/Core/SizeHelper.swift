//
//  SizeHelper.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 28/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

struct SizeHelper {
    /*
     * The origin is the bottom left corner
     */
    static let BaseWidth: CGFloat = 1440.0
    static let BaseHeight: CGFloat = 922.0
    
    class HearthstoneWindow {
        var _frame = NSRect.zero
        var windowId: CGWindowID?
        var screenRect = NSRect()
        var fullscreen = false
        
        static var axErrorReported = false
        
        init() {
            reload()
        }
        
        private func area(dict: NSDictionary) -> Int {
            let h = (dict["kCGWindowBounds"] as? NSDictionary)?["Height"] as? Int ?? 0
            let w = (dict["kCGWindowBounds"] as? NSDictionary)?["Width"] as? Int ?? 0

            return w * h
        }

        func reload() {
            let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements)
            let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))

            if let info = (windowListInfo as? [NSDictionary])?.filter({dict in
                dict["kCGWindowOwnerName"] as? String == CoreManager.applicationName && dict["kCGWindowLayer"] as? Int == 0 && dict["kCGWindowIsOnscreen"] as? Int == 1
            }).sorted(by: {
                return area(dict: $1) > area(dict: $0)
            }).last {
                if let id = info["kCGWindowNumber"] as? Int {
                    self.windowId = CGWindowID(id)
                }

                let pid = info["kCGWindowOwnerPID"] as? pid_t ?? 0

                let appRef = AXUIElementCreateApplication(pid)
                var window: CFTypeRef?

                let result: AXError = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &window)
                var calculateFromFrame = false
                // kCGWindowBounds can return a stale Mission Control thumbnail rect for some
                // time after MC dismisses; AX reflects HS's actual NSWindow.frame.
                var axRect: CGRect?
                if result == .success, let axWindow = window {
                    // swiftlint:disable force_cast
                    let axWindowRef = axWindow as! AXUIElement
                    // swiftlint:enable force_cast

                    var fs: CFTypeRef?
                    AXUIElementCopyAttributeValue(axWindowRef, "AXFullScreen" as CFString, &fs)
                    if let nsvalue = fs as? NSNumber {
                        fullscreen = nsvalue.intValue != 0
                    } else {
                        fullscreen = false
                    }

                    var posRef: CFTypeRef?
                    var sizeRef: CFTypeRef?
                    let posResult = AXUIElementCopyAttributeValue(axWindowRef, kAXPositionAttribute as CFString, &posRef)
                    let sizeResult = AXUIElementCopyAttributeValue(axWindowRef, kAXSizeAttribute as CFString, &sizeRef)
                    if posResult == .success, sizeResult == .success,
                       let posValue = posRef, let sizeValue = sizeRef {
                        var pos = CGPoint.zero
                        var size = CGSize.zero
                        // swiftlint:disable force_cast
                        AXValueGetValue(posValue as! AXValue, .cgPoint, &pos)
                        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
                        // swiftlint:enable force_cast
                        axRect = CGRect(origin: pos, size: size)
                    }
                } else {
                    if !SizeHelper.HearthstoneWindow.axErrorReported {
                        logger.error("Accessability error: \(result.rawValue)")
                        SizeHelper.HearthstoneWindow.axErrorReported = true
                    }
                    calculateFromFrame = true
                }

                // swiftlint:disable force_cast
                let bounds = info["kCGWindowBounds"] as! CFDictionary
                // swiftlint:enable force_cast
                if let rect = axRect ?? CGRect(dictionaryRepresentation: bounds) {
                    var frame = rect

                    // Warning: this function assumes that the
                    // first screen in the list is the active one
                    if let screen = NSScreen.screens.first {
                        screenRect = screen.frame
                        frame.origin.y = screen.frame.maxY - rect.maxY
                    }

                    self._frame = frame

                    if calculateFromFrame {
                        var fs = false
                        for scr in NSScreen.screens where scr.frame == frame {
                            fs = true
                            break
                        }
                        fullscreen = fs
                    }
                }
            }
        }
        
        var width: CGFloat {
            return _frame.width
        }
        
        static var titlebarHeight: CGFloat = 0.0
        
        var height: CGFloat {
            let height = _frame.height
            return isFullscreen() ? height : max(height - SizeHelper.HearthstoneWindow.titlebarHeight, 0)
        }
        
        fileprivate var left: CGFloat {
            return _frame.minX
        }
        
        fileprivate var top: CGFloat {
            return _frame.minY
        }
        
        func isFullscreen() -> Bool {
            return fullscreen
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
        func relativeFrame(_ frame: NSRect, relative: Bool = true, keepRatio: Bool = false) -> NSRect {
            var pointX = frame.minX
            var pointY = frame.minY
            var width = frame.width
            var height = frame.height
            
            if relative {
                pointX *= scaleX
                pointY *= scaleY
            }
            if keepRatio {
                width *= scaleX
                height *= scaleY
            }
            
            let x = self.frame.minX + pointX
            let y = self.frame.minY + pointY
            
            let relativeFrame = NSRect(x: x, y: y, width: width, height: height)
            //logger.verbose("FR:\(frame) -> HS:\(hearthstoneFrame) -> POS:\(relativeFrame)")
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
    
    static var hearthstoneBoardWidth: CGFloat {
        return hearthstoneWindow.height * 1.5
    }
    
    static var screenRatio: CGFloat {
        return (4.0 / 3.0) / (hearthstoneWindow.width / hearthstoneWindow.height)
    }
    
    static func overHearthstoneFrame() -> NSRect {
        // hearthstoneWindow.frame is already the window's absolute screen rect -
        // no relativeFrame() translation needed (that's for small widget rects
        // authored in the Base-reference coordinate system, not the HS window's
        // own frame; running it through relativeFrame() here double-applies the
        // scale to the origin, drifting further off the further the window sits
        // from (0,0) on screen).
        return hearthstoneWindow.frame
    }
    
    static var trackerWidth: CGFloat {
        let width: Double
        switch Settings.cardSize {
        case .tiny: width = kTinyFrameWidth
        case .small: width = kSmallFrameWidth
        case .medium: width = kMediumFrameWidth
        case .big: width = kFrameWidth
        case .huge: width = kHighRowFrameWidth
        }
        return CGFloat(width)
    }
    
    static fileprivate func trackerFrame(xOffset: CGFloat, yOffset: CGFloat = 0) -> NSRect {
        // game menu
        let offset: CGFloat = hearthstoneWindow.isFullscreen() ? 0 : 50
        let width = trackerWidth
        
        let frame = NSRect(x: xOffset,
                           y: offset,
                           width: max(trackerWidth, width),
                           height: max(100, hearthstoneWindow.frame.height - offset - yOffset))
        return hearthstoneWindow.relativeFrame(frame, relative: false)
    }
    
    static func getScaledXPos(_ left: CGFloat, width: CGFloat,
                              ratio: CGFloat) -> CGFloat {
        let x = ((width) * ratio * left) + (width * (1 - ratio) / 2)
        // Every caller works its ratio out by dividing by the same width passed
        // here, so a degenerate window makes that ratio infinite and both terms
        // above 0 * inf, which is NaN. A NaN reaching a SwiftUI layout modifier
        // traps the process, so the letterboxing is dropped rather than handed
        // on: the plain position inside the window is the best answer left, and
        // the canvas origin if even that is not finite.
        guard x.isFinite else {
            let unletterboxed = width * left
            return unletterboxed.isFinite ? unletterboxed : 0
        }
        return x
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
        loc.y += (
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
        loc.y += (hearthstoneWindow.screenRect.height - hsRect.origin.y - hsRect.size.height)
        return loc
    }
    
    static func secondCardLocation() -> NSPoint {
        var loc = firstCardLocation()
        
        loc.x += 190
        return loc
    }
    
    // playerTrackerFrame / opponentTrackerFrame / secretTrackerFrame used to
    // frame the three windows those panels had. They are RootOverlay children
    // now, placed from percentages of the canvas - see TrackerPanelViewModel and
    // SecretsPanelViewModel.

    

}
