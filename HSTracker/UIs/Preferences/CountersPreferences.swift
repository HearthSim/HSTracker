//
//  CountersPreferences.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/23/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit
import Preferences
import SwiftUI

/// Per-counter, per-side control over which counters are shown - HDT's Overlay > Counters
/// options page (FlyoutControls/Options/Overlay/OverlayCounters.xaml{,.cs}).
///
/// Built in code rather than from a nib: the page is one row per counter type, generated
/// from the catalog, so a new counter shows up here without anything being touched.
class CountersPreferences: PreferencePaneController, PreferencePane {
    var preferencePaneIdentifier = Preferences.PaneIdentifier.counters

    var preferencePaneTitle = String.localizedString("Options_Overlay_Counters_Header", comment: "")

    var toolbarItemIcon = NSImage(named: "settings-counters")!

    override func makeContentView() -> NSView? {
        let hosting = NSHostingView(rootView: CountersPreferencesView())
        hosting.translatesAutoresizingMaskIntoConstraints = false
        return hosting
    }
}

extension Preferences.PaneIdentifier {
    static let counters = Self("counters")
}

/// One configurable counter, and the overrides it currently resolves to.
private struct CounterSettingRow: Identifiable {
    let descriptor: CounterDescriptor
    var playerVisibility: CounterVisibility
    var opponentVisibility: CounterVisibility

    var id: String { descriptor.counterId }
    var displayName: String { descriptor.displayName }

    // HDT greys the opponent dropdown out for Battlegrounds counters: the opponent's
    // counters are never shown there.
    var isOpponentSupported: Bool { !descriptor.isBattlegroundsCounter }

    func visibility(isPlayer: Bool) -> CounterVisibility {
        isPlayer ? playerVisibility : opponentVisibility
    }
}

struct CountersPreferencesView: View {
    /// The game the catalog's probe counters are built against, as HDT hands them
    /// `Core.Game`. Nil until the core has started, in which case the rows are loaded the
    /// next time the pane appears.
    var game: () -> Game? = { AppDelegate.instance().coreManager?.game }

    /// Every row, built once from the catalog. Kept here rather than read back from the
    /// settings on each redraw so a dropdown change repaints just its own row.
    @SwiftUI.State private var allRows: [CounterSettingRow] = []
    @SwiftUI.State private var filter = ""

    /// Same cap as the related cards pane: HDT's page grows inside the options flyout's
    /// scroll viewer, which a preferences window has no equivalent of.
    private static let listHeight: CGFloat = 420

    /// Wider than HDT's 110pt ComboBox, for the same reason as the related cards pane: a
    /// macOS pop-up button spends part of its width on the chevron.
    private static let pickerWidth: CGFloat = 130

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String.localizedString("OptionsCounters_Description", comment: ""))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 10)

            HStack(spacing: 8) {
                TextField(String.localizedString("OptionsCounters_Filter_Placeholder", comment: ""),
                          text: $filter)
                    .textFieldStyle(.roundedBorder)
                Button(String.localizedString("OptionsCounters_ResetAll", comment: "")) {
                    CounterVisibilitySettings.instance.resetAll()
                    reload()
                }
                .disabled(!hasAnyOverride)
            }
            .padding(.bottom, 4)

            // Column headers, aligned with the two dropdowns in the rows below.
            HStack(spacing: 6) {
                Spacer()
                Text(String.localizedString("OptionsCounters_Column_Player", comment: ""))
                    .fontWeight(.bold)
                    .frame(width: Self.pickerWidth)
                Text(String.localizedString("OptionsCounters_Column_Opponent", comment: ""))
                    .fontWeight(.bold)
                    .frame(width: Self.pickerWidth)
            }
            .padding(.top, 6)
            .padding(.trailing, 18)

            if constructedRows.isEmpty && battlegroundsRows.isEmpty {
                Text(String.localizedString("OptionsCounters_NoResults", comment: ""))
                    .padding(.top, 12)
                Spacer(minLength: 0)
            } else {
                List {
                    if !constructedRows.isEmpty {
                        Section(header: groupHeader("OptionsCounters_Group_Traditional")) {
                            ForEach(constructedRows) { row in
                                rowView(row)
                            }
                        }
                    }
                    if !battlegroundsRows.isEmpty {
                        Section(header: groupHeader("OptionsCounters_Group_Battlegrounds")) {
                            ForEach(battlegroundsRows) { row in
                                rowView(row)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(width: PreferencePaneController.fixedWidth,
               height: Self.listHeight + 120,
               alignment: .leading)
        .padding(20)
        .onAppear(perform: loadIfNeeded)
    }

    private func groupHeader(_ key: String) -> some View {
        Text(String.localizedString(key, comment: ""))
            .font(.system(size: 14, weight: .bold))
            .padding(.top, 12)
            .padding(.bottom, 4)
    }

    private func rowView(_ row: CounterSettingRow) -> some View {
        HStack(spacing: 0) {
            CardPortraitView(cardId: row.descriptor.cardIdToShowInUI)
                .frame(width: 30, height: 30)

            Text(row.displayName)
                .lineLimit(1)
                .truncationMode(.tail)
                // HDT's ToolTip="{Binding CounterId}" on the name.
                .modifier(HelpTooltip(text: row.id))
                .padding(.leading, 8)
                .padding(.trailing, 10)

            Spacer(minLength: 0)

            picker(for: row, isPlayer: true)
                .padding(.trailing, 6)

            picker(for: row, isPlayer: false)
                .disabled(!row.isOpponentSupported)
                .modifier(HelpTooltip(text: row.isOpponentSupported
                    ? ""
                    : String.localizedString("OptionsCounters_OpponentUnsupportedTooltip", comment: "")))
        }
        .padding(.vertical, 3)
    }

    private func picker(for row: CounterSettingRow, isPlayer: Bool) -> some View {
        Picker("", selection: binding(for: row, isPlayer: isPlayer)) {
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

    private func binding(for row: CounterSettingRow, isPlayer: Bool) -> Binding<CounterVisibility> {
        Binding(
            get: { row.visibility(isPlayer: isPlayer) },
            set: { value in
                guard let index = allRows.firstIndex(where: { $0.id == row.id }) else { return }
                guard allRows[index].visibility(isPlayer: isPlayer) != value else { return }
                CounterVisibilitySettings.instance.set(row.id, isPlayer: isPlayer, value)
                if isPlayer {
                    allRows[index].playerVisibility = value
                } else {
                    allRows[index].opponentVisibility = value
                }
            }
        )
    }

    private var constructedRows: [CounterSettingRow] {
        visibleRows.filter { !$0.descriptor.isBattlegroundsCounter }
    }

    private var battlegroundsRows: [CounterSettingRow] {
        visibleRows.filter { $0.descriptor.isBattlegroundsCounter }
    }

    /// Filtered and sorted at draw time rather than cached: the display name is live, so a
    /// card-language change has to be able to reorder the list without anything being
    /// rebuilt.
    private var visibleRows: [CounterSettingRow] {
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

    private func matches(_ row: CounterSettingRow) -> Bool {
        let trimmed = filter.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return true
        }
        return row.displayName.localizedCaseInsensitiveContains(trimmed)
            || row.id.range(of: trimmed, options: .caseInsensitive) != nil
    }

    private var hasAnyOverride: Bool {
        allRows.contains { $0.playerVisibility != .auto || $0.opponentVisibility != .auto }
    }

    private func loadIfNeeded() {
        if allRows.isEmpty {
            reload()
        }
    }

    private func reload() {
        guard let game = game() else { return }
        let settings = CounterVisibilitySettings.instance
        allRows = CounterCatalog.descriptors(game: game).map {
            CounterSettingRow(descriptor: $0,
                              playerVisibility: settings.get($0.counterId, isPlayer: true),
                              opponentVisibility: settings.get($0.counterId, isPlayer: false))
        }
    }
}
