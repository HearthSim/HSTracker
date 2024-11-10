//
//  CountersOverlay.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/26/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CountersView: NSView {
    override func layout() {
        let views = subviews
        if views.count == 0 {
            return
        }
        
        let maxWidth = bounds.width
        var rowLayout: [[NSView]] = []
        var width = 0.0
        var content = [NSView]()
        for view in views {
            if width + view.intrinsicContentSize.width > maxWidth {
                rowLayout.append(content)
                content = [NSView]()
                content.append(view)
                width = view.intrinsicContentSize.width
            } else {
                content.append(view)
                width += view.intrinsicContentSize.width
            }
        }
        rowLayout.append(content)
        var y = 49.0
        for row in rowLayout {
            var x = 0.0
            for view in row {
                let ics = view.intrinsicContentSize
                view.frame = NSRect(x: x, y: y, width: ics.width, height: ics.height)
                x += ics.width
            }
            y -= 49.0
        }
    }

    func update(_ overlay: CountersOverlay) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.update(overlay)
            }
            return
        }

        for view in self.subviews {
            view.removeFromSuperview()
        }
        for view in overlay.visibleCounters.array() {
            self.addSubview(CounterView(view))
        }
        self.needsLayout = true
    }
}

class CountersOverlay: OverWindowController {
    @IBOutlet var countersView: CountersView!
    
    private(set) var _counters: CounterManager!
    var isPlayer = false
    
    @objc dynamic var visibility = false
    
    var countersListChanged: (() -> Void)?
    
    func setCounters(_ counters: CounterManager) {
        _counters = counters
        _counters.addCountersChangedListener(countersChanged)
    }
    
    private func countersChanged() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.countersChanged()
            }
            return
        }
        updateVisibleCounters()
    }
    
    var visibleCounters = SynchronizedArray<BaseCounter>()
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        
        DispatchQueue.main.async {
            self.countersView?.update(self)
        }
    }
    
    private func updateVisibleCounters() {
        let visibleCounters = _counters.getVisibleCounters(controlledByPlayer: isPlayer)
        
        var changed = false
        for counter in self.visibleCounters.array() where !visibleCounters.contains(counter) {
            self.visibleCounters.remove(counter)
            changed = true
        }
        
        for counter in visibleCounters where !self.visibleCounters.contains(counter) {
            self.visibleCounters.append(counter)
            changed = true
        }
        
        if changed || countersView?.subviews.count != visibleCounters.count {
            countersView?.update(self)
        }
    }
    
    func forceShowExampleCounters() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.forceShowExampleCounters()
            }
            return
        }
        visibleCounters.removeAll()
        
        let exampleCounters = _counters.getExampleCounters(controlledByPlayer: isPlayer)
        
        for counter in exampleCounters {
            visibleCounters.append(counter)
        }
        countersView?.update(self)
    }
    
    func forceHideExampleCounters() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.forceHideExampleCounters()
            }
            return
        }
        visibleCounters.removeAll()
        updateVisibleCounters()
    }
    
    func needsUpdate() -> Bool {
        return countersView?.subviews.count != visibleCounters.count
    }
    
    func update() {
        countersView?.update(self)
    }

}
