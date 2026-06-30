//
//  PreferencePaneController.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit

/// Base class for the settings panes. The `Preferences` library derives the settings window's size
/// from each pane's `view.fittingSize` (there is no width API), so giving every pane the same width
/// via Auto Layout is the supported way to keep the window a constant width across panes — only the
/// height varies, per the macOS HIG — instead of it resizing to each pane's natural content width.
class PreferencePaneController: NSViewController {
    /// Shared width for every settings pane.
    static let fixedWidth: CGFloat = 580

    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: Self.fixedWidth).isActive = true
    }
}
