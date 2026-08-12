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

    @IBOutlet var labelTrailingConstraint: NSLayoutConstraint!

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

        // When the label is visible, its own trailing-to-superview
        // constraint (labelTrailingConstraint) is what makes the box
        // naturally hug the actual text's width - matching HDT's "minimal
        // size that satisfies constraints" behavior, and correctly varying
        // per status string ("No Data" vs "Mulligan G-V2 Ready" vs "Partial
        // Mulligan G-V2") instead of a one-size-fits-all fixed width.
        // isHidden on the label alone doesn't deactivate this constraint
        // when hidden (confirmed live: isHidden only excludes constraints
        // entirely self-contained within the hidden view's own subtree, not
        // ones connecting it to its non-hidden superview), so toggle it
        // explicitly. When the label is hidden there's nothing else
        // constraining the box's trailing edge, so add an explicit compact
        // width just for that case, wrapping only the icon (HDT's
        // compact/icon-only badge for non-focused decks).
        labelTrailingConstraint.isActive = status.labelVisibility
        if !status.labelVisibility {
            box.widthAnchor.constraint(equalToConstant: 30).isActive = true
        }
    }
}
