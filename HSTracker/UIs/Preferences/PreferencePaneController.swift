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

    /// Tallest a pane may be before it gets wrapped in a scroll view.
    ///
    /// `PreferencesTabViewController.setWindowFrame` sizes the window straight from
    /// `view.fittingSize` with no clamp against the screen, so a tall pane simply
    /// runs off the bottom - Battlegrounds is 848pt of content, which needs roughly
    /// a 930pt window once the title bar and toolbar are added. The budget below is
    /// what is left of the screen after that chrome plus a margin.
    private static var maxContentHeight: CGFloat {
        let available = NSScreen.main?.visibleFrame.height ?? 900
        // ~78pt toolbar + ~28pt title bar, and some breathing room.
        return max(400, available - 140)
    }

    override func loadView() {
        super.loadView()

        let content = view
        content.translatesAutoresizingMaskIntoConstraints = false

        // fittingSize needs the width settled first, or a stack view reports the
        // height it would take at its natural width rather than at ours.
        let widthConstraint = content.widthAnchor.constraint(equalToConstant: Self.fixedWidth)
        widthConstraint.isActive = true
        content.layoutSubtreeIfNeeded()
        let contentHeight = content.fittingSize.height

        guard contentHeight > Self.maxContentHeight else { return }

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        // Left visible rather than autohiding: with legacy (non-overlay)
        // scrollbars a permanent scroller is what tells the user there is more
        // pane below, which is the whole point here. Overlay scrollers ignore
        // this and fade as usual.
        scrollView.autohidesScrollers = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.documentView = content

        // The content tracks the clip view's width rather than keeping its own
        // fixed one, so a legacy (non-overlay) scroller narrows it instead of
        // clipping its trailing edge.
        widthConstraint.isActive = false
        let clip = scrollView.contentView
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: clip.topAnchor),
            content.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: clip.trailingAnchor),
            content.heightAnchor.constraint(equalToConstant: contentHeight),
            scrollView.heightAnchor.constraint(equalToConstant: Self.maxContentHeight)
        ])

        view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Applies to the scroll view when loadView wrapped the pane, and to the
        // pane itself otherwise - either way it is what the window is sized from.
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: Self.fixedWidth).isActive = true
    }
}
