//
//  ConstructedMulliganSingleCardStats.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/19/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ConstructedMulliganSingleCardStats: NSView {
    @IBOutlet weak var contentView: NSView!
    
    @IBOutlet weak var singleCardHeader: ConstructedMulliganSingleCardHeader!
    
    let viewModel: ConstructedMulliganSingleCardViewModel
//    var index = 0

    init(frame: NSRect, viewModel: ConstructedMulliganSingleCardViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("ConstructedMulliganSingleCardStats", owner: self, topLevelObjects: nil)
        translatesAutoresizingMaskIntoConstraints = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        contentView.widthAnchor.constraint(equalToConstant: 212.0).isActive = true
        contentView.heightAnchor.constraint(equalToConstant: 480.0).isActive = true
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        viewModel.propertyChanged = { name in
            DispatchQueue.main.async {
                self.update(name)
            }
        }
        
        singleCardHeader.viewModel = viewModel.cardHeaderVM
    }
    
    func update(_ property: String? = nil) {
        if property == nil {
            singleCardHeader.update()
        }
    }
//    
//    override func draw(_ dirtyRect: NSRect) {
//        super.draw(dirtyRect)
//        let backgroundColor: NSColor = switch index {
//        case 0: NSColor(red: 0x48/255.0, green: 0x7E/255.0, blue: 0xAA/255.0, alpha: 0.3)
//        case 1: NSColor(red: 0x48/255.0, green: 0x00/255.0, blue: 0x9A/255.0, alpha: 0.3)
//        case 2: NSColor(red: 0x00/255.0, green: 0x7E/255.0, blue: 0x8A/255.0, alpha: 0.3)
//        case 3: NSColor(red: 0x48/255.0, green: 0x7E/255.0, blue: 0x00/255.0, alpha: 0.3)
//        default: NSColor(red: 0x48/255.0, green: 0x7E/255.0, blue: 0x6A/255.0, alpha: 0.3)
//        }
////        let backgroundColor = NSColor.clear
//        backgroundColor.set()
//        bounds.fill()
//    }
}
