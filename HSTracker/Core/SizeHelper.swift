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
                if result == .success {
                    var fs: CFTypeRef?
                    // swiftlint:disable force_cast
                    AXUIElementCopyAttributeValue(window as! AXUIElement, "AXFullScreen" as CFString, &fs)
                    // swiftlint:enable force_cast
                    if let nsvalue = fs as? NSNumber {
                        fullscreen = nsvalue.intValue != 0
                    } else {
                        fullscreen = false
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
                if let rect = CGRect(dictionaryRepresentation: bounds) {
                    var frame = rect
                    
                    // Warning: this function assumes that the
                    // first screen in the list is the active one
                    if let screen = NSScreen.screens.first {
                        screenRect = screen.frame
                        frame.origin.y = screen.frame.maxY - rect.maxY
                    }
                    
                    //logger.debug("HS Frame is : \(rect)")
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
        
        fileprivate func isFullscreen() -> Bool {
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
    
    static var battlegroundsTileHeight: CGFloat {
        return (hearthstoneWindow.height * 0.7) / 8.0
    }
    
    static var battlegroundsTileWidth: CGFloat {
        return hearthstoneWindow.height * 0.078
    }
    
    static let battlegroundsDuosTileToSpacingRatio = 0.137
    
    static var battlegroundsDuosTileHeight: CGFloat {
        return hearthstoneWindow.height * 0.69 * (1.0 - battlegroundsDuosTileToSpacingRatio) / 8
    }
    static var battlegroundsDuosSpacingHeight: CGFloat {
        return hearthstoneWindow.height * 0.69 * battlegroundsDuosTileToSpacingRatio / 3
    }

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
        let frame = hearthstoneWindow.frame
        
        return hearthstoneWindow.relativeFrame(frame)
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
    
    static func playerBoardDamageFrame() -> NSRect {
        let hs = hearthstoneWindow.frame
        let w = 50.0
        let h = 50.0
        return NSRect(x: hs.minX + getScaledXPos(25.5 / 100.0, width: hs.width, ratio: screenRatio), y: hs.minY + (hs.height * (100.0 - 67.62) / 100.0) - h, width: w, height: h)
    }
    
    static func opponentBoardDamageFrame() -> NSRect {
        let hs = hearthstoneWindow.frame
        let w = 50.0
        let h = 50.0
        return NSRect(x: hs.minX + getScaledXPos(25.5 / 100.0, width: hs.width, ratio: screenRatio), y: hs.minY + (hs.height * (100.0 - 22.39) / 100.0) - h, width: w, height: h)
    }
    
    static func experienceOverlayFrame() -> NSRect {
        let frame = NSRect(x: 1055.0, y: 0.0, width: 135.0, height: 45.0)
        //NSRect(x: hearthstoneWindow.frame.maxX  - 400, y: hearthstoneWindow.frame.origin.y, width: 150.0, height: 45.0)
        return hearthstoneWindow.relativeFrame(frame, keepRatio: true)
    }
    
    static func secretTrackerFrame(height: CGFloat) -> NSRect {
        let yOffset: CGFloat = hearthstoneWindow.isFullscreen() ? 0 : 50
        
        let frame = NSRect(x: trackerWidth + 25,
                           y: hearthstoneWindow.frame.height - height - yOffset,
                           width: trackerWidth,
                           height: height)
        
        return hearthstoneWindow.relativeFrame(frame, relative: false)
    }
    
    static func timerHudFrame() -> NSRect {
        let frame = NSRect(x: 999.0, y: 423.0, width: 160.0, height: 115.0)
        return hearthstoneWindow.relativeFrame(frame)
    }
    
    static func turnCounterFrame() -> NSRect {
        let frame = battlegroundsTierOverlayFrame()
        let left = frame.minX - 100
        let top = frame.minY
        return NSRect(x: left, y: top, width: 100, height: frame.height)
    }
    
    static func battlegroundsSessionFrame() -> NSRect {
        let bottom = hearthstoneWindow.frame.minY + 0.05 * hearthstoneWindow.height
        let top = hearthstoneWindow.frame.maxY - 0.15 * hearthstoneWindow.height
        
        let left = hearthstoneWindow.frame.minX
        
        let frame = NSRect(x: left, y: bottom, width: 400, height: top - bottom)
        return (frame)
    }
    
    static func battlegroundsOverlayFrame() -> NSRect {
        let top = hearthstoneWindow.frame.minY + 0.85 * hearthstoneWindow.height
        let bottom = hearthstoneWindow.frame.minY + 0.15 * hearthstoneWindow.height
        
        // Looks like the HS board ratio is 1.5, the rest is padding
        let boardWidth = hearthstoneWindow.height * 1.5
        let left = hearthstoneWindow.frame.minX
        let right = hearthstoneWindow.frame.minX + 0.133 * boardWidth + (hearthstoneWindow.width - boardWidth)/2
        
        let frame = NSRect(x: left, y: bottom, width: right - left, height: top - bottom)
        return (frame)
    }
    
    static func battlegroundsTierOverlayFrame() -> NSRect {
        let trackerFrame = playerTrackerFrame()
        let tierOverlay = AppDelegate.instance().coreManager?.game.windowManager.battlegroundsTierOverlay.tierOverlay
        let tiers = (tierOverlay?.showTavernTier7 ?? false) ? 7 : 6
        let height = CGFloat(56)
        let width = CGFloat(tiers * 48 + 8)
        let x = hearthstoneWindow.frame.minX + hearthstoneWindow.frame.width - width
        
        return NSRect(x: x, y: trackerFrame.minY + trackerFrame.height - height, width: width, height: height)
    }
    
    static func bobsPanelOverlayFrame() -> NSRect {
        let trackerFrame = playerTrackerFrame()
        let height = CGFloat(52)
        let width = CGFloat(404)
        let x = hearthstoneWindow.frame.minX + (hearthstoneWindow.width - width) / 2
        
        return NSRect(x: x, y: trackerFrame.minY + trackerFrame.height - height, width: width, height: height)
    }
    
    static func battlegroundsTierDetailFrame() -> NSRect {
        let height = hearthstoneWindow.height - CGFloat(64)
        let width = trackerWidth
        let x = hearthstoneWindow.frame.minX + hearthstoneWindow.frame.width - width
        let y = hearthstoneWindow.frame.minY
        
        return NSRect(x: x, y: y, width: width, height: height)
    }
    
    static func battlegroundsDetailsFrame() -> NSRect {
        let w: CGFloat = 1184
        let h: CGFloat = 270
        
        let x = hearthstoneWindow.frame.minX + (hearthstoneWindow.width - w) / 2
        
        let frame = NSRect(x: x, y: hearthstoneWindow.frame.maxY - h, width: w, height: h)
        return frame
    }
    
    static func toastFrame() -> NSRect {
        let w: CGFloat = 240.0
        let h: CGFloat = 100.0
        
        let frame = NSRect(x: hearthstoneWindow.frame.width - w - trackerWidth - 10, y: 10, width: w, height: h)
        return hearthstoneWindow.relativeFrame(frame, relative: false)
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
    
    static func opponentActiveEffectsFrame() -> NSRect {
        let hs = hearthstoneWindow.frame
        let w = 244.0
        let h = 122.0
        return NSRect(x: hs.minX + getScaledXPos(66.2 / 100.0, width: hs.width, ratio: screenRatio), y: hs.minY + (hs.height * 73.8 / 100.0), width: w, height: h)
    }
    
    static func playerActiveEffectsFrame() -> NSRect {
        let hs = hearthstoneWindow.frame
        let w = 244.0
        let h = 122.0
        return NSRect(x: hs.minX + getScaledXPos(66.2 / 100.0, width: hs.width, ratio: screenRatio), y: hs.minY + (hs.height * (100.0 - 71.6) / 100.0) - h, width: w, height: h)
    }

    static func opponentCountersFrame() -> NSRect {
        let hs = hearthstoneWindow.frame
        let w = 336.0
        let h = 102.0
        return NSRect(x: hs.minX + getScaledXPos(67.7 / 100.0, width: hs.width, ratio: screenRatio), y: hs.minY + hs.height * 70.6 / 100.0, width: w, height: h)
    }
    
    static func playerCountersFrame() -> NSRect {
        let hs = hearthstoneWindow.frame
        let w = 336.0
        let h = 102.0
        return NSRect(x: hs.minX + getScaledXPos(67.7 / 100.0, width: hs.width, ratio: screenRatio), y: hs.minY + (hs.height * (100.0 - 68.4) / 100.0) - h, width: w, height: h)
    }

    static func tier7PreLobbyFrame() -> NSRect {
        let hs = hearthstoneWindow.frame
        let w = 763.0
        let h = 500.0
        return NSRect(x: hs.minX + getScaledXPos(0.079, width: hs.width, ratio: screenRatio), y: hs.minY + (hs.height * (1.0 - 0.103) - h), width: w, height: h)
    }
    
    static func constructedMulliganGuidePreLobbyFrame() -> NSRect {
        let hs = SizeHelper.hearthstoneWindow.frame
        let w = 238.0*3.0
        let h = 224.0*3.0
        let scale = hs.height / 1080
        return NSRect(x: hs.minX + SizeHelper.getScaledXPos(0.087, width: SizeHelper.hearthstoneWindow.width, ratio: SizeHelper.screenRatio), y: hs.minY + (hs.height * (1.0 - 0.217)) - h - 16.0 * scale, width: w*2.0, height: h*2.0)
    }
}
