//
//  BattlegroundsPlacementDistribution.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/19/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsPlacementDistribution: NSView {
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet var bar1st: BattlegroundsPlacementDistributionBar!
    @IBOutlet var bar2nd: BattlegroundsPlacementDistributionBar!
    @IBOutlet var bar3rd: BattlegroundsPlacementDistributionBar!
    @IBOutlet var bar4th: BattlegroundsPlacementDistributionBar!
    @IBOutlet var bar5th: BattlegroundsPlacementDistributionBar!
    @IBOutlet var bar6th: BattlegroundsPlacementDistributionBar!
    @IBOutlet var bar7th: BattlegroundsPlacementDistributionBar!
    @IBOutlet var bar8th: BattlegroundsPlacementDistributionBar!
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("BattlegroundsPlacementDistribution", owner: self, topLevelObjects: nil)
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)
        contentView.frame = self.bounds
        
        update()
    }
    
    private var _maxValue: Int = 30
    var maxValue: Int {
        get {
            return _maxValue
        }
        set {
            _maxValue = newValue
        }
    }

    private var _values: [Double] = [ 0, 0, 0, 0, 0, 0, 0, 0 ]
    var values: [Double] {
        get {
            return _values
        }
        set {
            _values = newValue
            onValuesChanged()
        }
    }
    
    func onValuesChanged() {
        let maxFromValues = values.max() ?? 30
        if Double(maxValue) < maxFromValues {
            maxValue = Int(ceil(maxFromValues))
        }
        if bar1st != nil {
            update()
        }
    }
    
    var hasData: Bool {
        return values.any({ x in x > 0 })
    }
    
    func update() {
        let maxValue = Double(self.maxValue)
        let values = self.values
        bar1st.maxValue = maxValue
        bar1st.value = values[0]
        bar2nd.maxValue = maxValue
        bar2nd.value = values[1]
        bar3rd.maxValue = maxValue
        bar3rd.value = values[2]
        bar4th.maxValue = maxValue
        bar4th.value = values[3]
        if values.count > 4 {
            bar5th.maxValue = maxValue
            bar5th.value = values[4]
            bar6th.maxValue = maxValue
            bar6th.value = values[5]
            bar7th.maxValue = maxValue
            bar7th.value = values[6]
            bar8th.maxValue = maxValue
            bar8th.value = values[7]
        }
    }
}
