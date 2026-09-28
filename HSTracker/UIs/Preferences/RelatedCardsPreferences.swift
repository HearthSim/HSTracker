//
//  RelatedCardsPreferences.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/22/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit
import SwiftUI

/// Per-card control over the opponent's "Related Cards" list - HDT's Overlay > Related
/// Cards options page.
///
/// Built in code rather than from a nib: the page is one row per registered related card,
/// and there are hundreds of them, so the rows have to be generated from the catalog.
class RelatedCardsPreferences: PreferencePaneController, PreferencePane {
    var preferencePaneIdentifier = PreferencePaneIdentifier.related_cards

    var preferencePaneTitle = String.localizedString("Options_Overlay_RelatedCards_Header", comment: "")

    var preferencePaneIcon = NSImage(named: "settings-related-cards")!

    var preferencePaneSearchText: [String] {
        ["OptionsRelatedCards_Description", "OptionsRelatedCards_Filter_Placeholder",
         "OptionsRelatedCards_CustomizedOnly", "OptionsCounters_ResetAll", "OptionsCounters_Column_Opponent"]
            .map { String.localizedString($0, comment: "") }
            + RelatedCardCatalog.descriptors.map(\.displayName)
    }

    override func makeContentView() -> NSView? {
        let hosting = NSHostingView(rootView: RelatedCardsPreferencesView())
        hosting.translatesAutoresizingMaskIntoConstraints = false
        return hosting
    }
}

extension PreferencePaneIdentifier {
    static let related_cards = Self("related_cards")
}

/// One configurable card, and the override it currently resolves to.
private struct RelatedCardRow: Identifiable {
    let descriptor: RelatedCardDescriptor
    var visibility: CounterVisibility

    var id: String { descriptor.cardId }
    var displayName: String { descriptor.displayName }
    var cardIdsText: String { descriptor.cardIdsText }
}

struct RelatedCardsPreferencesView: View {
    /// Every row, built once from the catalog. The rows are kept here rather than read
    /// back from the settings on each redraw so a dropdown change repaints just its own
    /// row.
    @SwiftUI.State private var allRows: [RelatedCardRow] = []
    @SwiftUI.State private var filter = ""
    @SwiftUI.State private var customizedOnly = false

    /// The height HDT's own list is capped at (OverlayRelatedCards.xaml's ScrollViewer).
    private static let listHeight: CGFloat = 420

    /// Wider than HDT's 110pt ComboBox: a macOS pop-up button spends part of its width on
    /// the chevron, and at 110 the longest option ("Always show") was elided.
    private static let pickerWidth: CGFloat = 130

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String.localizedString("OptionsRelatedCards_Description", comment: ""))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 10)

            HStack(spacing: 8) {
                TextField(String.localizedString("OptionsRelatedCards_Filter_Placeholder", comment: ""),
                          text: $filter)
                    .textFieldStyle(.roundedBorder)
                Toggle(String.localizedString("OptionsRelatedCards_CustomizedOnly", comment: ""),
                       isOn: $customizedOnly)
                Button(String.localizedString("OptionsCounters_ResetAll", comment: "")) {
                    RelatedCardVisibilitySettings.instance.resetAll()
                    reload()
                }
                .disabled(!hasAnyOverride)
            }

            // Column header, aligned with the dropdown in the row below.
            HStack {
                Spacer()
                Text(String.localizedString("OptionsCounters_Column_Opponent", comment: ""))
                    .fontWeight(.bold)
                    .frame(width: Self.pickerWidth)
            }
            .padding(.top, 6)
            .padding(.trailing, 18)

            if visibleRows.isEmpty {
                Text(String.localizedString("OptionsRelatedCards_NoResults", comment: ""))
                    .padding(.top, 12)
                Spacer(minLength: 0)
            } else {
                // A List rather than a ScrollView of rows: there are hundreds of
                // related cards, and this is the one container available on the
                // deployment target that only builds the rows it shows - the same
                // reason HDT virtualizes this page and not the counters one.
                List(visibleRows) { row in
                    rowView(row)
                }
                .padding(.top, 4)
            }
        }
        // The padding goes around this frame, so it comes out of the pane's width.
        .frame(width: PreferencePaneController.fixedWidth - 40,
               height: Self.listHeight + 120,
               alignment: .leading)
        .padding(20)
        .onAppear(perform: loadIfNeeded)
    }

    private func rowView(_ row: RelatedCardRow) -> some View {
        HStack(spacing: 0) {
            CardPortraitView(cardId: row.id)
                .frame(width: 30, height: 30)

            Text(row.displayName)
                .lineLimit(1)
                .truncationMode(.tail)
                // The tooltip listing every id of the card. HDT puts it on the name
                // unconditionally; .help needs macOS 11, so below that the ids are
                // still reachable through the filter box.
                .modifier(HelpTooltip(text: row.cardIdsText))
                .padding(.leading, 8)
                .padding(.trailing, 10)

            Spacer(minLength: 0)

            Picker("", selection: binding(for: row)) {
                Text(String.localizedString("OptionsCounters_Mode_Auto", comment: ""))
                    .tag(CounterVisibility.auto)
                Text(String.localizedString("OptionsCounters_Mode_Enabled", comment: ""))
                    .tag(CounterVisibility.enabled)
                Text(String.localizedString("OptionsCounters_Mode_Disabled", comment: ""))
                    .tag(CounterVisibility.disabled)
            }
            .labelsHidden()
            .frame(width: Self.pickerWidth)
        }
    }

    private func binding(for row: RelatedCardRow) -> Binding<CounterVisibility> {
        Binding(
            get: { row.visibility },
            set: { value in
                guard let index = allRows.firstIndex(where: { $0.id == row.id }) else { return }
                guard allRows[index].visibility != value else { return }
                RelatedCardVisibilitySettings.instance.setOpponent(row.id, value)
                allRows[index].visibility = value
            }
        )
    }

    /// Filtered and sorted at draw time rather than cached: the display name is live, so a
    /// card-language change has to be able to reorder the list without anything being
    /// rebuilt.
    private var visibleRows: [RelatedCardRow] {
        allRows
            .filter(matches)
            .sorted { lhs, rhs in
                let byName = lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName)
                if byName != .orderedSame {
                    return byName == .orderedAscending
                }
                return lhs.id < rhs.id
            }
    }

    private func matches(_ row: RelatedCardRow) -> Bool {
        if customizedOnly && row.visibility == .auto {
            return false
        }
        let trimmed = filter.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return true
        }
        return row.displayName.localizedCaseInsensitiveContains(trimmed)
            || row.cardIdsText.localizedCaseInsensitiveContains(trimmed)
    }

    private var hasAnyOverride: Bool { allRows.contains { $0.visibility != .auto } }

    private func loadIfNeeded() {
        if allRows.isEmpty {
            reload()
        }
    }

    private func reload() {
        let settings = RelatedCardVisibilitySettings.instance
        allRows = RelatedCardCatalog.descriptors.map {
            RelatedCardRow(descriptor: $0, visibility: settings.getOpponent($0.cardId))
        }
    }
}

/// `.help` is macOS 11 and up, and the deployment target is older. Shared with the
/// counters pane.
struct HelpTooltip: ViewModifier {
    let text: String

    func body(content: Content) -> some View {
        if #available(macOS 11.0, *) {
            return AnyView(content.help(text))
        }
        return AnyView(content)
    }
}

/// The round card portrait at the head of each row - HDT's 30x30 ellipse filled with the
/// card's art, zoomed so the card frame stays outside the circle. Shared with the counters
/// pane, whose rows HDT draws the same way.
struct CardPortraitView: View {
    let cardId: String?

    @SwiftUI.State private var image: NSImage?

    var body: some View {
        Circle()
            .fill(Color.black.opacity(0.4))
            .overlay(
                Group {
                    if let image {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            // HDT's ScaleTransform(1.5, 1.5, 16, 11) on the 30x30 ellipse.
                            .scaleEffect(1.5, anchor: UnitPoint(x: 16.0 / 30.0, y: 11.0 / 30.0))
                    }
                }
            )
            .clipShape(Circle())
            .onAppear(perform: load)
    }

    private func load() {
        guard let cardId else { return }
        if let cached = ImageUtils.cachedArt(cardId: cardId) {
            image = cached
            return
        }
        ImageUtils.art(for: cardId) { img in
            DispatchQueue.main.async {
                self.image = img
            }
        }
    }
}
