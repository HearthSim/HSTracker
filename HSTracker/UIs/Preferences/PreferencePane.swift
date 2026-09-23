//
//  PreferencePane.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit

/// Names a settings pane, so code outside the settings window can open it on a given pane.
/// Each pane declares its own identifier in an extension next to the pane.
struct PreferencePaneIdentifier: Hashable, RawRepresentable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A pane of the settings window: one row of its sidebar.
protocol PreferencePane: PreferencePaneController {
    var preferencePaneIdentifier: PreferencePaneIdentifier { get }
    var preferencePaneTitle: String { get }
    /// Shown next to the title in the sidebar. See `PreferencePaneController` for how to author one.
    var preferencePaneIcon: NSImage { get }
    /// Text the sidebar's search matches against, beyond the pane's title and the text of its
    /// AppKit controls, which it reads itself. A pane built in SwiftUI has no controls to read,
    /// so it lists its own labels here.
    var preferencePaneSearchText: [String] { get }
}

extension PreferencePane {
    var preferencePaneSearchText: [String] { [] }
}

/// A titled section of the settings sidebar.
struct PreferencePaneGroup {
    let title: String
    let panes: [PreferencePane]
}
