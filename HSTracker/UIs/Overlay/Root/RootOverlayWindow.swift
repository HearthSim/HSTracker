//
//  RootOverlayWindow.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI
import Foundation

@available(macOS 10.15, *)
class RootOverlayWindow: OverWindowController {
    var hostingView: NSHostingView<RootOverlayView>!
    let viewModel = RootOverlayViewModel()

    override func windowDidLoad() {
        super.windowDidLoad()
        hostingView = NSHostingView(rootView: RootOverlayView(viewModel: viewModel))
        window?.contentView = hostingView
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.ignoresMouseEvents = true
    }
}
