//
//  ConstructedMulliganSingleCardHeader.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/18/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation
import CustomToolTip

class ConstructedMulliganSingleCardHeader: NSView {
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var mulliganWrTooltip: NSView!
    @IBOutlet weak var keepRateTooltip: NSView!
    @IBOutlet weak var handRankTooltip: NSView!
    
    @IBOutlet weak var mulliganWrTracker: NSView!
    @IBOutlet weak var mulliganWrLabel: NSTextField!
    @IBOutlet weak var rankBox: NSBox!
    @IBOutlet weak var rankLabel: NSTextField!
    @IBOutlet weak var keepRateTracker: NSView!
    @IBOutlet weak var keepRateLabel: NSTextField!
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 212, height: 53)
    }
        
    var viewModel: ConstructedStatsHeaderViewModel? {
        didSet {
            viewModel?.propertyChanged = { _ in
                DispatchQueue.main.async {
                    self.update()
                }
            }
            DispatchQueue.main.async {
                self.update()
            }
        }
    }
    
    @objc dynamic var rankTooltipText: String = ""

    override init(frame: NSRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("ConstructedMulliganSingleCardHeader", owner: self, topLevelObjects: nil)
        translatesAutoresizingMaskIntoConstraints = true
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)
        contentView.frame = self.bounds
        defaultBackgroundColor = .clear
        
        mulliganWrTracker.customToolTip = mulliganWrTooltip
        mulliganWrTracker.customToolTipMargins = CGSize(width: 0, height: 0)
        mulliganWrTracker.customToolTipInsets = CGSize(width: 25, height: 0)
        mulliganWrTooltip.updateTrackingAreas_CustomToolTip()
        
        rankBox.customToolTip = handRankTooltip
        rankBox.customToolTipMargins = CGSize(width: 0, height: 0)
        rankBox.customToolTipInsets = CGSize(width: 25, height: 0)
        handRankTooltip.updateTrackingAreas_CustomToolTip()
        
        keepRateTracker.customToolTip = keepRateTooltip
        keepRateTracker.customToolTipMargins = CGSize(width: 0, height: 0)
        keepRateTracker.customToolTipInsets = CGSize(width: 25, height: 0)
        keepRateTooltip.updateTrackingAreas_CustomToolTip()
    }

    func update() {
        logger.debug(#function)
        mulliganWrLabel.textColor = NSColor.fromHexString(hex: viewModel?.mulliganWrColor ?? "#FFFFFF") ?? NSColor.white
        if let wr = viewModel?.mulliganWr {
            mulliganWrLabel.doubleValue = wr
        } else {
            mulliganWrLabel.stringValue = "—" // em dash
        }
        
        rankBox.wantsLayer = true
        rankBox.layer = viewModel?.rankGradient
        if let rank = viewModel?.rank {
            rankLabel.intValue = Int32(rank)
        } else {
            rankLabel.stringValue = "—" // em dash
        }
        
        if let keepRate = viewModel?.keepRate {
            keepRateLabel.doubleValue = keepRate / 100.0
        } else {
            keepRateLabel.stringValue = "—" // em dash
        }
    }
}
