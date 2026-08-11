//
//  MulliganTooltip.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI
import AppKit

// SwiftUI's `.help()` modifier needs macOS 11; this stays on plain
// NSView.toolTip so the mulligan V2 views can target macOS 10.15.
@available(macOS 10.15, *)
private struct MulliganTooltipHost: NSViewRepresentable {
    let text: String?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.toolTip = text
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.toolTip = text
    }
}

@available(macOS 10.15, *)
extension View {
    func mulliganTooltip(_ text: String?) -> some View {
        overlay(MulliganTooltipHost(text: text))
    }
}
