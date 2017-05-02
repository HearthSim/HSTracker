//
//  Toast.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 18/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import TextAttributes

class Toast {
    private static let windowWidth: CGFloat = 350
    private static let toastWindow: ToastWindow = {
        let w = ToastWindow()
        
        w.isOpaque = false
        w.hasShadow = false
        w.acceptsMouseMovedEvents = true
        w.styleMask = NSBorderlessWindowMask
        w.level = Int(CGWindowLevelForKey(CGWindowLevelKey.maximumWindow))
        w.backgroundColor = Color.clear
        
        w.orderFrontRegardless()
        
        let screenRect = NSScreen.screens()!.first!.frame
        let height = screenRect.height
        let x = screenRect.width / 2 - windowWidth / 2
        
        let rect = NSRect(x: x, y: screenRect.minY, width: windowWidth, height: height)
        w.setFrame(rect, display: true)
        
        return w
    }()
   
    class func show(title: String, message: String? = nil, duration: Double? = 3,
                    action: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let panel = ToastPanel(title: title,
                                   message: message,
                                   duration: duration,
                                   action: action)
            
            toastWindow.add(panel: panel)
        }
    }
    
    private class ToastPanel: NSView {
        private lazy var trackingArea: NSTrackingArea = {
            return NSTrackingArea(rect: NSRect.zero,
                                  options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                                  owner: self,
                                  userInfo: nil)
        }()
        
        private var title: String?
        private var message: String?
        fileprivate var duration: Double = 3
        private var action: (() -> Void)?
        
        private let buttonWidth: CGFloat = 80
        private var inClick = false
        
        convenience init(title: String, message: String? = nil, duration: Double? = nil,
                         action: (() -> Void)? = nil) {
            self.init()
            
            self.title = title
            self.message = message
            
            if let duration = duration {
                self.duration = duration
            } else if action != nil {
                self.duration = 6
            }
            
            self.action = action
            
            self.layerContentsRedrawPolicy = .onSetNeedsDisplay
            self.wantsLayer = true
            self.layer?.backgroundColor = NSColor.clear.cgColor
            self.layer?.cornerRadius = 10
        }
        
        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            
            let starting = NSColor(red: 0.9508, green: 0.9507, blue: 0.9507, alpha: 1.0)
            let ending = NSColor(red: 0.7928, green: 0.7928, blue: 0.7928, alpha: 1.0)
            let gradient = NSGradient(starting: starting, ending: ending)
            gradient?.draw(in: dirtyRect, angle: 270)
            
            let titleFrame = NSRect(x: 20, y: dirtyRect.height - 30,
                                    width: dirtyRect.width - 40, height: 20)
            let messageFrame = NSRect(x: 20, y: titleFrame.minY - 40,
                                    width: dirtyRect.width - 40, height: 40)
           
            if let title = title {
                let attributes = TextAttributes()
                    .font(NSFont(name: "ChunkFive", size: 16))
                    .foregroundColor(.black)
                NSAttributedString(string: title, attributes: attributes)
                    .draw(in: titleFrame)
            }
            if let message = message {
                let attributes = TextAttributes()
                    .font(NSFont(name: "ChunkFive", size: 14))
                    .foregroundColor(.black)
                NSAttributedString(string: message, attributes: attributes)
                    .draw(in: messageFrame)
            }
        }
        
        func remove() {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().completionHandler = { [weak self] in
                self?.removeFromSuperview()
            }
            NSAnimationContext.current().duration = 1.2
            
            animator().alphaValue = 0
            
            NSAnimationContext.endGrouping()
        }
        
        // MARK: - mouse hover
        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            
            if !self.trackingAreas.contains(trackingArea) {
                self.addTrackingArea(trackingArea)
            }
        }
        
        override func mouseDown(with event: NSEvent) {
            guard self.action != nil else { return }
            
            inClick = true
        }
        override func mouseUp(with event: NSEvent) {
            guard self.action != nil else { return }
            guard inClick else { return }
            
            inClick = false
            action?()
            toastWindow.remove(panel: self)
        }
    }
    
    private class ToastWindow: NSWindow {
        private var panels: [ToastPanel] = []
        
        func add(panel: ToastPanel) {
            if let contentView = self.contentView {
                let y = contentView.frame.maxY
                panel.frame = NSRect(x: 0, y: y, width: windowWidth, height: 70)
                contentView.addSubview(panel)
                panels.append(panel)
                
                var when = DispatchTime.now()
                    + Double(Int64(500 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)
                let queue = DispatchQueue.main
                queue.asyncAfter(deadline: when) { [weak self] in
                    self?.refresh()
                }
                
                when = DispatchTime.now()
                    + Double(Int64((0.5 + panel.duration) * Double(NSEC_PER_SEC)))
                    / Double(NSEC_PER_SEC)
                queue.asyncAfter(deadline: when) { [weak self] in
                    self?.remove(panel: panel)
                }
            }
        }
        
        func remove(panel: ToastPanel) {
            panel.remove()
            panels.remove(panel)
        }
        
        private func refresh() {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.8
            
            var y: CGFloat = contentView!.frame.maxY
            panels.reversed().forEach {
                y -= 80
                let newOrigin = NSPoint(x: 0, y: y)
                $0.animator().setFrameOrigin(newOrigin)
            }
            
            NSAnimationContext.endGrouping()
        }
    }
}
