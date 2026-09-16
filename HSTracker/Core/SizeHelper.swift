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
    
    static var minionWidth: CGFloat {
        return hearthstoneWindow.width * 0.63 / 7 * screenRatio
    }
    
    static var mercenariesMinionMargin: CGFloat {
        return hearthstoneWindow.width * screenRatio * 0.01
    }
    
    static var minionMargin: CGFloat {
        return hearthstoneWindow.width * screenRatio * 0.0029
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
    
    static func playerTrackerFrame() -> NSRect {
        return trackerFrame(xOffset: hearthstoneWindow.frame.width - trackerWidth)
    }
    
    static func opponentTrackerFrame() -> NSRect {
        var yOffset: CGFloat = 0
        if Settings.preventOpponentNameCovering {
            yOffset = hearthstoneWindow.frame.height * 0.125 // name height ratio
        }
        return trackerFrame(xOffset: 0, yOffset: yOffset)
    }
    
    static func secretTrackerFrame(height: CGFloat) -> NSRect {
        let yOffset: CGFloat = hearthstoneWindow.isFullscreen() ? 0 : 50
        
        let frame = NSRect(x: trackerWidth + 25,
                           y: hearthstoneWindow.frame.height - height - yOffset,
                           width: trackerWidth,
                           height: height)
        
        return hearthstoneWindow.relativeFrame(frame, relative: false)
    }
    
    static func bobsPanelOverlayFrame() -> NSRect {
        let trackerFrame = playerTrackerFrame()
        let height = CGFloat(52)
        let width = CGFloat(404)
        let x = hearthstoneWindow.frame.minX + (hearthstoneWindow.width - width) / 2
        
        return NSRect(x: x, y: trackerFrame.minY + trackerFrame.height - height, width: width, height: height)
    }
    
    static func boardOverlayHeight() -> Double {
        return hearthstoneWindow.height * 0.158
    }
    
    static func abilitySize() -> Double {
        return boardOverlayHeight() * 0.28
    }
    
    static func opponentBoardOverlay() -> NSRect {
        let width = hearthstoneWindow.width
        let height = hearthstoneWindow.height
        let frame = hearthstoneWindow.frame
        let game = AppDelegate.instance().coreManager.game
        let step = game.gameEntity?[.step] ?? 0
        let isMainAction = step == Step.main_action.rawValue || step == Step.main_post_action.rawValue || step == Step.main_pre_action.rawValue
        let mercsToNominate = game.gameEntity?.has(tag: .allow_move_minion) ?? false
        
        let overlayHeight = boardOverlayHeight()
        let margin = overlayHeight * 0.12
        let opponentBoardOffset = game.isMercenariesMatch() && isMainAction && !mercsToNominate ? height * 0.142 : height * 0.045
        let result = NSRect(x: frame.minX, y: frame.minY + height - (height / 2 - overlayHeight - opponentBoardOffset) - overlayHeight, width: width, height: overlayHeight + abilitySize() + margin)
        return result
    }
    
    static func playerBoardOverlay() -> NSRect {
        let width = hearthstoneWindow.width
        let height = hearthstoneWindow.height
        let frame = hearthstoneWindow.frame
        let game = AppDelegate.instance().coreManager.game
        let step = game.gameEntity?[.step] ?? 0
        let isMainAction = step == Step.main_action.rawValue || step == Step.main_post_action.rawValue || step == Step.main_pre_action.rawValue
        let mercsToNominate = game.gameEntity?.has(tag: .allow_move_minion) ?? false
        
        let overlayHeight = boardOverlayHeight()
        let margin = overlayHeight * 0.14
        let playerBoardOffset = game.isMercenariesMatch() ? isMainAction && !mercsToNominate ? height * -0.09 : height * 0.003 : height * 0.03
        let result = NSRect(x: frame.minX, y: frame.minY + height - (height / 2 - playerBoardOffset) - overlayHeight - abilitySize() - margin, width: width, height: overlayHeight + abilitySize() + margin)
        return result
    }
    
    static func mercenariesButtonOffset() -> Double {
        let h = hearthstoneWindow.height
        if AppDelegate.instance().coreManager.game.isInMenu && screenRatio > 0.9 {
            return h * 0.104
        }
        return h * 0.05
    }
    
    static func mercenariesTaskListButton() -> NSRect {
        let w = 150.0
        let h = 60.0
        let height = hearthstoneWindow.height
        let bottom = hearthstoneWindow.frame.minY + mercenariesButtonOffset()
        let right = hearthstoneWindow.frame.maxX - height * 0.01
        let frame = NSRect(x: right - w, y: bottom, width: w, height: h)
        return frame
    }
    
    static func mercenariesTaskListView() -> NSRect {
        let frame = mercenariesTaskListButton()
        let height = hearthstoneWindow.height
        let width = hearthstoneWindow.width / 2.0
        let bottom = hearthstoneWindow.frame.minY + frame.height + mercenariesButtonOffset() + 8
        
        return NSRect(x: frame.maxX - width, y: bottom, width: width, height: height - bottom)
    }
    
    static func flavorTextFrame() -> NSRect {
        let hs = hearthstoneWindow.frame
        
        let ft = AppDelegate.instance().coreManager.game.windowManager.flavorText.window?.frame ?? NSRect.zero
        let w = ft.width
        let h = ft.height
        let frame = NSRect(x: hs.maxX - w - 10.0, y: hs.minY + 10.0, width: w, height: h)
        return frame
    }
    
    static let cardHudContainerWidth: CGFloat = 400
    static let cardHudContainerHeight: CGFloat = 90
    static func cardHudContainerFrame() -> NSRect {
        let w = SizeHelper.cardHudContainerWidth * hearthstoneWindow.scaleX
        let h = SizeHelper.cardHudContainerHeight * hearthstoneWindow.scaleY
        let frame = NSRect(x: (hearthstoneWindow.frame.width / 2) - (w / 2),
                           y: hearthstoneWindow.frame.height - h,
                           width: w, height: h)
        return hearthstoneWindow.relativeFrame(frame, relative: false)
    }
    

}
