//
//  CollectionToastViewController.swift
//  HSTracker
//
//  Created by Martin BONNIN on 03/05/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Cocoa
import TextAttributes

class CollectionToastViewController: NSViewController {

    var message =  ""
    var loading = false
    private let attributes = TextAttributes()

    @IBOutlet var frameView: FrameView!
    @IBOutlet weak private var textField: NSTextField!
    @IBOutlet weak private var progress: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        attributes
            .font(NSFont(name: "Belwe Bd BT", size: 14))
            .foregroundColor(.white)
            .strokeWidth(-1.5)
            .strokeColor(.black)
            .alignment(.center)

        view.autoresizingMask = [.width, .height]
        
        frameView.color = NSColor.white.withAlphaComponent(0.5)

        self.progress.isIndeterminate = true
        self.progress.startAnimation(nil)
        self.progress.usesThreadedAnimation = true
        self.progress.isHidden = !loading

        self.textField.attributedStringValue = NSAttributedString(string: message, attributes: attributes)

    }
}
