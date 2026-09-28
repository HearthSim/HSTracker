//
//  PreferencePaneController.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit

/// Base class for the settings panes. The settings window shows each pane in a scroll view of
/// `fixedWidth`, pinned to its top, so a pane lays itself out for that width and its height comes
/// from its own constraints - a pane taller than the window scrolls.
///
/// Sidebar icons: each pane sets `preferencePaneIcon` to its own dedicated image set (prefixed
/// `settings-`), a template image the sidebar tints for the selected/unselected states. The sidebar
/// scales each icon down into its row, so icons are authored larger than that - scaling down stays
/// crisp where an 18pt raster scaled up looked blurry. When adding an icon, match:
///   - Size: 32×32 pt, template rendering intent.
///   - Vector art: a single `.pdf` with "Preserve Vector Data", or an asset-catalog `.svg` (the app's
///     10.15 deployment target supports either).
///   - Raster art: `.png` at @1x / @2x / @3x, i.e. 32 / 64 / 96 px.
class PreferencePaneController: NSViewController {
    /// Width of the settings window's pane area.
    static let fixedWidth: CGFloat = 600

    /// A pane that builds its content in code rather than from a nib returns it here.
    func makeContentView() -> NSView? { nil }

    override func loadView() {
        if let custom = makeContentView() {
            view = custom
        } else {
            super.loadView()
        }
        view.translatesAutoresizingMaskIntoConstraints = false
    }
}
