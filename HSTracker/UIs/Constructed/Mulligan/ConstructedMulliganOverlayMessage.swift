//
//  OverlayMessage.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/4/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class ConstructedMulliganOverlayMessage: NSView {
    @IBOutlet var contentView: NSView!
    @IBOutlet var messageField: NSTextField!
    
    var viewModel: ConstructedMulliganOverlayMessageViewModel? {
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
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("ConstructedMulliganOverlayMessage", owner: self, topLevelObjects: nil)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.frame = self.bounds
    }
    
    func update() {
        guard let viewModel = viewModel else {
            return
        }
        contentView.isHidden = !viewModel.visibility
        messageField.stringValue = viewModel.text ?? ""
    }
}
