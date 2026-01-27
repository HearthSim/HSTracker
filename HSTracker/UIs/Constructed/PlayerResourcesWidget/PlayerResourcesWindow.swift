//
//  PlayerResourcesWindow.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/23/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI
import Foundation

@available(macOS 10.15, *)
class PlayerResourcesWindow: OverWindowController {
    var hostingView: NSHostingView<PlayerResourcesView>!
    let viewModel = PlayerResourcesViewModel()
    
    override func windowDidLoad() {
        hostingView = NSHostingView(rootView: PlayerResourcesView(viewModel))
        window?.contentView = hostingView
        window?.isOpaque = false
        window?.backgroundColor = .clear
    }
}
