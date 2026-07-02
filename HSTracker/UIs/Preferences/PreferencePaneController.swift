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
///
/// Tab icons: each pane sets `toolbarItemIcon` to its own dedicated image set (prefixed `settings-`),
/// a template image the toolbar tints for the selected/unselected states. The toolbar scales each icon
/// into its own slot, so icons are authored larger than that slot — it only ever downscales them,
/// which stays crisp (an 18pt raster got upscaled and looked blurry). When adding a tab icon, match:
///   - Size: 32×32 pt, template rendering intent.
///   - Vector art: a single `.pdf` with "Preserve Vector Data" (PDF rather than SVG so it renders on
///     the app's macOS 10.14 deployment target; asset-catalog SVG requires 10.15+).
///   - Raster art: `.png` at @1x / @2x / @3x, i.e. 32 / 64 / 96 px.
class PreferencePaneController: NSViewController {
    /// Shared width for every settings pane.
    static let fixedWidth: CGFloat = 600

    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: Self.fixedWidth).isActive = true
    }
}
