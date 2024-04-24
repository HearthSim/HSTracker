//
//  BattlegroundsMinionTypesBox.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/23/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsMinionTypesBox: NSView {
    @IBOutlet weak var contentView: NSView!
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: SizeHelper.trackerWidth, height: 72.0)
    }
    
    @objc dynamic var minionTypesText = ""
    
    private var _minionTypes = [Race]()
    
    var minionTypes: [Race] {
        get {
            return _minionTypes
        }
        set {
            _minionTypes = newValue
            minionTypesText = newValue.compactMap { race in String.localizedString(race.rawValue, comment: "") }.sorted().joined(separator: ", ")
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    private func commonInit() {
        guard Bundle.main.loadNibNamed("BattlegroundsMinionTypesBox", owner: self, topLevelObjects: nil) else {
            return
        }
        translatesAutoresizingMaskIntoConstraints = true
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)
    }
}
