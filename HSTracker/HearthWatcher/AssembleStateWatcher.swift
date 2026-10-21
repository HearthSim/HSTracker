//
//  AssembleStateWatcher.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

struct AssembleStateArgs: Equatable {
    var isShowing: Bool
    var targetEntityId: Int
    var selectedChoiceEntityId: Int
    var choiceEntityIds: [Int]
    var hoveredChoiceIndex: Int = -1
    var hoveredHalf: Int = 0

    static let hidden = AssembleStateArgs(isShowing: false, targetEntityId: 0, selectedChoiceEntityId: 0,
                                          choiceEntityIds: [], hoveredChoiceIndex: -1, hoveredHalf: 0)
}

class AssembleStateWatcher: Watcher {
    var change: ((_ sender: AssembleStateWatcher, _ args: AssembleStateArgs) -> Void)?

    private var _prev: AssembleStateArgs?

    override init(delay: TimeInterval = 0.016) {
        super.init(delay: delay)
    }

    override func cleanup() {
        // Watching can stop mid-Assemble (e.g. the game ends), so clear what the last state showed.
        if _prev?.isShowing == true {
            change?(self, .hidden)
        }
        _prev = nil
    }

    override func update() -> Bool {
        let state = MirrorHelper.getAssembleState()
        // A concealed screen (the player hid it to look at the board) shows nothing to hover.
        let isShowing = state.map { !$0.isConcealed } ?? false
        let curr = isShowing
            ? AssembleStateArgs(isShowing: true,
                                targetEntityId: state?.targetEntityId?.intValue ?? 0,
                                selectedChoiceEntityId: state?.selectedChoiceEntityId?.intValue ?? 0,
                                choiceEntityIds: state?.choiceEntityIds.map { $0.intValue } ?? [],
                                hoveredChoiceIndex: state?.hoveredChoiceIndex?.intValue ?? -1,
                                hoveredHalf: state?.hoveredHalf?.intValue ?? 0)
            : .hidden
        if curr == _prev {
            return false
        }
        _prev = curr
        change?(self, curr)
        return false
    }
}
