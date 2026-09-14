//
//  SpinningIndicator.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// AppKit's NSProgressIndicator in its spinning style, sized by its SwiftUI
// frame - what HDT's mah:ProgressRing maps to here, since SwiftUI's own
// ProgressView needs macOS 11. Shared by the Inspiration panel and Bob's Buddy,
// both of which spin one while their data is on the way.
@available(macOS 10.15, *)
struct SpinningIndicator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSProgressIndicator {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.isIndeterminate = true
        indicator.controlSize = .regular
        // The overlay is dark throughout, so force the light-on-dark variant
        // rather than following the system appearance.
        indicator.appearance = NSAppearance(named: .vibrantDark)
        indicator.startAnimation(nil)
        return indicator
    }

    func updateNSView(_ nsView: NSProgressIndicator, context: Context) {
        nsView.startAnimation(nil)
    }
}
