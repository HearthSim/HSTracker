//
//  DelayedTooltip.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/10/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class DelayedTooltip: NSObject {
    let handler: ((Any?) -> Void)
    var timer: Timer?
    
    init(handler: @escaping (Any?) -> Void, _ delay: TimeInterval = 0.500, _ userInfo: Any?) {
        self.handler = handler
        super.init()
        timer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(self.onTimer), userInfo: userInfo, repeats: false)
    }
    
    @objc private func onTimer(_ timer: Timer) {
        if !Thread.isMainThread {
            fatalError("Must be main thread")
        }
        handler(timer.userInfo)
        self.timer = nil
    }
    
    func cancel() {
        timer?.invalidate()
        timer = nil
    }
}
