//
//  PreferencesWindowController.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit

/// The settings window: a sidebar listing the panes by group, with a search field that filters it,
/// and the selected pane beside it.
final class PreferencesWindowController: NSWindowController {
    private static let sidebarWidth: CGFloat = 200
    private static let sidebarMaxWidth: CGFloat = 280
    /// Tall enough for the whole sidebar without scrolling.
    private static let minHeight: CGFloat = 480

    private let splitViewController: PreferencesSplitViewController

    init(groups: [PreferencePaneGroup]) {
        splitViewController = PreferencesSplitViewController(groups: groups)

        let window = NSWindow(contentRect: .zero,
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered,
                              defer: true)
        window.isReleasedWhenClosed = false
        window.contentViewController = splitViewController

        let paneWidth = PreferencePaneController.fixedWidth
        window.contentMinSize = NSSize(width: Self.sidebarWidth + paneWidth, height: Self.minHeight)
        window.contentMaxSize = NSSize(width: Self.sidebarMaxWidth + paneWidth,
                                       height: CGFloat.greatestFiniteMagnitude)
        // Most panes fit in this; the taller ones scroll, and the window can be made taller.
        let available = (NSScreen.main?.visibleFrame.height ?? 900) - 100
        window.setContentSize(NSSize(width: Self.sidebarWidth + paneWidth,
                                     height: max(Self.minHeight, min(available, 720))))
        window.center()
        window.setFrameAutosaveName("PreferencesWindow")

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Shows the window on `pane`, or on the pane it last showed.
    func show(preferencePane pane: PreferencePaneIdentifier? = nil) {
        if let pane = pane {
            splitViewController.select(pane)
        } else {
            splitViewController.selectInitialPaneIfNeeded()
        }
        showWindow(self)
        window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Split view

private final class PreferencesSplitViewController: NSSplitViewController {
    private let sidebar: PreferencesSidebarViewController
    private let container = PreferencePaneContainerViewController()

    init(groups: [PreferencePaneGroup]) {
        sidebar = PreferencesSidebarViewController(groups: groups)
        super.init(nibName: nil, bundle: nil)

        sidebar.onSelect = { [weak self] pane in
            self?.container.show(pane)
            self?.view.window?.title = pane.preferencePaneTitle
        }

        splitView.isVertical = true
        splitView.dividerStyle = .thin

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebar)
        sidebarItem.canCollapse = false
        sidebarItem.minimumThickness = 180
        sidebarItem.maximumThickness = 280
        addSplitViewItem(sidebarItem)

        let paneItem = NSSplitViewItem(viewController: container)
        paneItem.canCollapse = false
        addSplitViewItem(paneItem)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func select(_ identifier: PreferencePaneIdentifier) {
        _ = view
        sidebar.select(identifier)
    }

    func selectInitialPaneIfNeeded() {
        _ = view
        if container.pane == nil {
            sidebar.selectFirstPane()
        }
    }
}

// MARK: - Pane area

/// Shows one pane at a time, at `PreferencePaneController.fixedWidth`, pinned to the top of a scroll view.
private final class PreferencePaneContainerViewController: NSViewController {
    private let scrollView = NSScrollView()
    private let documentView = FlippedView()
    private(set) var pane: PreferencePane?

    override func loadView() {
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView
        let clip = scrollView.contentView
        // The pane tracks the clip view's width rather than keeping a fixed one of its own, so a
        // legacy (non-overlay) scroller narrows it instead of clipping its trailing edge.
        NSLayoutConstraint.activate([
            documentView.topAnchor.constraint(equalTo: clip.topAnchor),
            documentView.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
            documentView.trailingAnchor.constraint(equalTo: clip.trailingAnchor),
            scrollView.widthAnchor.constraint(equalToConstant: PreferencePaneController.fixedWidth)
        ])
        view = scrollView
    }

    func show(_ newPane: PreferencePane) {
        guard newPane !== pane else { return }
        _ = view

        if let old = pane {
            old.view.removeFromSuperview()
            old.removeFromParent()
        }
        pane = newPane
        addChild(newPane)

        let paneView = newPane.view
        documentView.addSubview(paneView)
        NSLayoutConstraint.activate([
            paneView.topAnchor.constraint(equalTo: documentView.topAnchor),
            paneView.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            paneView.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            paneView.bottomAnchor.constraint(equalTo: documentView.bottomAnchor)
        ])
        scrollView.contentView.scroll(to: .zero)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }
}

/// Keeps a pane shorter than the scroll view at its top rather than its bottom.
private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

// MARK: - Sidebar

private final class PreferencesSidebarViewController: NSViewController {
    /// One sidebar section, holding the panes the search leaves visible.
    private final class Group {
        let title: String
        let panes: [PreferencePane]
        var visiblePanes: [PreferencePane]

        init(_ group: PreferencePaneGroup) {
            title = group.title
            panes = group.panes
            visiblePanes = group.panes
        }
    }

    private static let headerIdentifier = NSUserInterfaceItemIdentifier("PreferencesSidebarHeader")
    private static let rowIdentifier = NSUserInterfaceItemIdentifier("PreferencesSidebarRow")

    var onSelect: ((PreferencePane) -> Void)?

    private let groups: [Group]
    private var visibleGroups: [Group]
    private let outlineView = NSOutlineView()
    private let searchField = NSSearchField()
    private var selectedPane: PreferencePane?
    /// Set while the selection is changed in code, so it is not reported back as the user's.
    private var isUpdatingSelection = false
    /// Every string a pane shows, gathered the first time the user searches.
    private var searchIndex: [ObjectIdentifier: String] = [:]

    init(groups: [PreferencePaneGroup]) {
        self.groups = groups.map(Group.init)
        visibleGroups = self.groups
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let root = NSView()

        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.sendsSearchStringImmediately = true
        searchField.sendsWholeSearchString = false
        searchField.target = self
        searchField.action = #selector(searchChanged(_:))
        root.addSubview(searchField)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("PreferencesSidebarColumn"))
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.headerView = nil
        outlineView.selectionHighlightStyle = .sourceList
        if #available(macOS 11, *) {
            outlineView.style = .sourceList
        }
        outlineView.floatsGroupRows = false
        outlineView.rowSizeStyle = .default
        outlineView.allowsEmptySelection = true
        outlineView.dataSource = self
        outlineView.delegate = self

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        root.addSubview(scrollView)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: root.topAnchor, constant: 10),
            searchField.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10),
            searchField.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -10),
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])

        view = root
        reload()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        // Start in the list, where the arrow keys move between panes, rather than in the search field.
        view.window?.initialFirstResponder = outlineView
    }

    func select(_ identifier: PreferencePaneIdentifier) {
        _ = view
        guard let pane = groups.lazy.flatMap(\.panes).first(where: { $0.preferencePaneIdentifier == identifier }) else {
            return
        }
        if !visibleGroups.contains(where: { $0.visiblePanes.contains { $0 === pane } }) {
            searchField.stringValue = ""
            applySearch()
        }
        choose(pane)
    }

    func selectFirstPane() {
        _ = view
        if let pane = visibleGroups.first?.visiblePanes.first {
            choose(pane)
        }
    }

    private func choose(_ pane: PreferencePane) {
        selectedPane = pane
        syncOutlineSelection()
        onSelect?(pane)
    }

    private func reload() {
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
        syncOutlineSelection()
    }

    private func syncOutlineSelection() {
        isUpdatingSelection = true
        defer { isUpdatingSelection = false }
        let row = selectedPane.map { outlineView.row(forItem: $0) } ?? -1
        if row >= 0 {
            outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            outlineView.scrollRowToVisible(row)
        } else {
            outlineView.deselectAll(nil)
        }
    }

    // MARK: Search

    @objc private func searchChanged(_ sender: NSSearchField) {
        applySearch()
    }

    private func applySearch() {
        let query = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        for group in groups {
            group.visiblePanes = query.isEmpty ? group.panes : group.panes.filter { matches($0, query) }
        }
        visibleGroups = groups.filter { !$0.visiblePanes.isEmpty }
        reload()

        // Keep the pane on screen in step with the list: if the search hid it, show the first match.
        if let selected = selectedPane, outlineView.row(forItem: selected) < 0,
           let first = visibleGroups.first?.visiblePanes.first {
            choose(first)
        }
    }

    private func matches(_ pane: PreferencePane, _ query: String) -> Bool {
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        if pane.preferencePaneTitle.range(of: query, options: options) != nil {
            return true
        }
        return searchText(for: pane).range(of: query, options: options) != nil
    }

    private func searchText(for pane: PreferencePane) -> String {
        let key = ObjectIdentifier(pane)
        if let text = searchIndex[key] {
            return text
        }
        var strings = pane.preferencePaneSearchText
        Self.collectStrings(in: pane.view, into: &strings)
        let text = strings.filter { !$0.isEmpty }.joined(separator: "\n")
        searchIndex[key] = text
        return text
    }

    /// Gathers the text of a pane's AppKit labels and controls.
    private static func collectStrings(in view: NSView, into strings: inout [String]) {
        switch view {
        case let popUp as NSPopUpButton:
            strings += popUp.itemTitles
        case let button as NSButton:
            strings.append(button.title)
        case let comboBox as NSComboBox:
            strings += comboBox.objectValues.compactMap { $0 as? String }
        case let field as NSTextField:
            strings.append(field.stringValue)
            strings += [field.placeholderString].compactMap { $0 }
        case let segmented as NSSegmentedControl:
            strings += (0..<segmented.segmentCount).compactMap { segmented.label(forSegment: $0) }
        case let box as NSBox:
            strings.append(box.title)
        default:
            break
        }
        for subview in view.subviews {
            collectStrings(in: subview, into: &strings)
        }
    }
}

extension PreferencesSidebarViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let group = item as? Group {
            return group.visiblePanes.count
        }
        return item == nil ? visibleGroups.count : 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let group = item as? Group {
            return group.visiblePanes[index]
        }
        return visibleGroups[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        item is Group
    }
}

extension PreferencesSidebarViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        item is Group
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        !(item is Group)
    }

    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        false
    }

    func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
        false
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let group = item as? Group {
            let cell = outlineView.makeView(withIdentifier: Self.headerIdentifier, owner: self) as? NSTableCellView
                ?? makeCell(identifier: Self.headerIdentifier, withImage: false)
            cell.textField?.stringValue = group.title
            return cell
        }
        guard let pane = item as? PreferencePane else { return nil }
        let cell = outlineView.makeView(withIdentifier: Self.rowIdentifier, owner: self) as? NSTableCellView
            ?? makeCell(identifier: Self.rowIdentifier, withImage: true)
        cell.textField?.stringValue = pane.preferencePaneTitle
        cell.imageView?.image = pane.preferencePaneIcon
        return cell
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard !isUpdatingSelection else { return }
        guard let pane = outlineView.item(atRow: outlineView.selectedRow) as? PreferencePane else {
            // Clicking empty space clears the selection; the pane stays on screen, so keep its row selected.
            syncOutlineSelection()
            return
        }
        guard pane !== selectedPane else { return }
        selectedPane = pane
        onSelect?(pane)
    }

    private func makeCell(identifier: NSUserInterfaceItemIdentifier, withImage: Bool) -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = identifier

        let textField = NSTextField(labelWithString: "")
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byTruncatingTail
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        cell.addSubview(textField)
        cell.textField = textField

        var constraints = [
            textField.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -4),
            textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ]
        if withImage {
            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.imageScaling = .scaleProportionallyUpOrDown
            cell.addSubview(imageView)
            cell.imageView = imageView
            constraints += [
                imageView.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                imageView.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 18),
                imageView.heightAnchor.constraint(equalToConstant: 18),
                textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 6)
            ]
        } else {
            textField.font = .boldSystemFont(ofSize: NSFont.smallSystemFontSize)
            textField.textColor = .secondaryLabelColor
            constraints.append(textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2))
        }
        NSLayoutConstraint.activate(constraints)
        return cell
    }
}
