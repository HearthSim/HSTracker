//
//  SpecialShopChoicesStateWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/25/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation
import Atomics

struct SpecialShopChoicesArgs: Equatable {
    static func == (lhs: SpecialShopChoicesArgs, rhs: SpecialShopChoicesArgs) -> Bool {
        if lhs.isActive != rhs.isActive {
            return false
        }
        
        if lhs.mousedOverSlot != rhs.mousedOverSlot {
            return false
        }
        
        if lhs.boardCards.count != rhs.boardCards.count {
            return false
        }
        
        for (i, thisCard) in lhs.boardCards.enumerated() {
            let otherCard = rhs.boardCards[i]
            if thisCard.entityId != otherCard.entityId {
                return false
            }
            if thisCard.hovered != otherCard.hovered {
                return false
            }
        }
        return true
    }

    let isActive: Bool
    let boardCards: [MirrorBoardCard]
    let mousedOverSlot: Int
}

class SpecialShopChoicesStateWatcher {
    var change: ((_ sender: SpecialShopChoicesStateWatcher, _ args: SpecialShopChoicesArgs) -> Void)?
    private let delay: TimeInterval
    private var _running = ManagedAtomic<Bool>(false)
    private var _watch = ManagedAtomic<Bool>(false)
    private var _prev: SpecialShopChoicesArgs?
    internal var queue: DispatchQueue?
    
    init(delay: TimeInterval = 0.200) {
        self.delay = delay
    }
    
    func run() {
        _watch.store(true, ordering: .sequentiallyConsistent)
        if _running.load(ordering: .sequentiallyConsistent) {
            return
        }
        if queue == nil {
            queue = DispatchQueue(label: "\(type(of: self))",
                                  attributes: [])
        }
        if let queue = queue {
            queue.async { [weak self] in
                guard let self else { return }
                Thread.current.name = queue.label
                self.update()
            }
        }
    }
    
    func stop() {
        _watch.store(false, ordering: .sequentiallyConsistent)
    }
    
    private func update() {
        _running.store(true, ordering: .sequentiallyConsistent)
        while _watch.load(ordering: .sequentiallyConsistent) {
            Thread.sleep(forTimeInterval: delay)
            if !_watch.load(ordering: .sequentiallyConsistent) {
                break
            }
            
            let state = MirrorHelper.getSpecialShopChoiceState()
            let curr = SpecialShopChoicesArgs(isActive: state?.isActive ?? false, boardCards: state?.boardCards ?? [MirrorBoardCard](), mousedOverSlot: state?.mousedOverSlot.intValue ?? -1)
            if curr == _prev {
                continue
            }
            change?(self, curr)
            _prev = curr
        }
        _prev = nil
        _running.store(false, ordering: .sequentiallyConsistent)
    }
}
