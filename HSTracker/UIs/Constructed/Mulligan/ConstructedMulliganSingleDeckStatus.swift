//
//  ConstructedMulliganSingleCardStats.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/19/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ConstructedMulliganSingleDeckStatus: NSView {
    @IBOutlet var contentView: NSView!
    
    @IBOutlet var padding: NSLayoutConstraint!
    
    @IBOutlet var box: NSBox!
            
    let status: SingleDeckStatus
    
    @objc dynamic var label: String {
        return status.label
    }
    
    @objc dynamic var labelVisibility: Bool {
        return status.labelVisibility
    }
    
    @objc dynamic var iconVisibility: Bool {
        return status.iconVisibility
    }
    
    @objc dynamic var iconSource: NSImage? {
        return status.iconSource
    }
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 238.0, height: 96.0)
    }

    init(frame: NSRect, status: SingleDeckStatus) {
        self.status = status
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    private func commonInit() {
        NibHelper.loadNib(Self.self, self)
        
        translatesAutoresizingMaskIntoConstraints = true
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)

    }
    
    override func awakeFromNib() {
        padding.constant = CGFloat(status.padding)
        box.isHidden = !status.visibility
        box.borderColor = NSColor.fromHexString(hex: status.borderBrush) ?? .black
        box.fillColor = NSColor.fromHexString(hex: status.background) ?? .clear
    }
}
