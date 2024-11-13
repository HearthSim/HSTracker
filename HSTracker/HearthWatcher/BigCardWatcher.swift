//
//  BigCardWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BigCardArgs: Equatable {
    var tooltipHeights: [Float]
    var enchantmentHeights: [Float]
    var cardId: String
    var zonePosition: Int
    var zoneSize: Int
    var side: Int
    var isHand: Bool
    
    init(value: MirrorBigCardState?) {
        if let value {
            tooltipHeights = value.tooltipHeights.compactMap { $0.floatValue }
            enchantmentHeights = value.enchantmentHeights.compactMap { $0.floatValue }
            cardId = value.cardId
            zonePosition = value.zonePosition.intValue
            zoneSize = value.zoneSize.intValue
            side = value.side.intValue
            isHand = value.isHand
        } else {
            tooltipHeights = [Float]()
            enchantmentHeights = [Float]()
            cardId = ""
            zonePosition = 0
            zoneSize = 0
            side = 0
            isHand = false
        }
    }
}

class BigCardWatcher {
    var change: ((_ sender: BigCardWatcher, _ args: BigCardArgs) -> Void)?
    
    let delay: TimeInterval
    private var _running = false
    private var _watch = false
    private var _prev: BigCardArgs?
    internal var queue: DispatchQueue?
    
    init(delay: TimeInterval = 0.016) {
        self.delay = delay
    }
    
    func run() {
        _watch = true
        if _running {
            return
        }
        if queue == nil {
            queue = DispatchQueue(label: "\(type(of: self))",
                                  attributes: [])
        }
        if let queue = queue {
            queue.async { [weak self] in
                Thread.current.name = queue.label
                self?.update()
            }
        }
    }
    
    func stop() {
        _watch = false
    }
    
    private func update() {
        _running = true
        while _watch {
            Thread.sleep(forTimeInterval: delay)
            if !_watch {
                break
            }
            
            let value = MirrorHelper.getBigCardState()
            let curr = BigCardArgs(value: value)
            if curr == _prev {
                continue
            }
            change?(self, curr)
            _prev = curr
        }
        _prev = nil
        _running = false
    }

}
