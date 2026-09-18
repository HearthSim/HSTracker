//
//  OverlayLayoutPreferences.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit
import Preferences
import SwiftUI

/// The settings behind where the deck trackers and the secret helper sit on the
/// overlay, how big they are drawn and what order their sections come in - HDT's
/// Overlay > Player / Opponent options pages, minus the per-section checkboxes,
/// which HSTracker already has in its own Player and Opponent panes.
///
/// Built in code rather than from a nib: the section sorter is a list whose rows
/// move, which is what HDT's `ElementSorter` is, and there is nothing to gain
/// from expressing that in a xib.
class OverlayLayoutPreferences: PreferencePaneController, PreferencePane {
    var preferencePaneIdentifier = Preferences.PaneIdentifier.overlay_layout

    var preferencePaneTitle = String.localizedString("Overlay_Layout", comment: "")

    var toolbarItemIcon = NSImage(named: "settings-overlay-layout")!

    override func makeContentView() -> NSView? {
        let hosting = NSHostingView(rootView: OverlayLayoutPreferencesView())
        hosting.translatesAutoresizingMaskIntoConstraints = false
        return hosting
    }
}

extension Preferences.PaneIdentifier {
    static let overlay_layout = Self("overlay_layout")
}

struct OverlayLayoutPreferencesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OverlayLayoutSideSection(playerType: .player)
            Divider()
            OverlayLayoutSideSection(playerType: .opponent)
            Divider()
            SecretHelperLayoutSection()
            Divider()
            resetRow
        }
        .padding(20)
        .frame(width: PreferencePaneController.fixedWidth, alignment: .leading)
    }

    /// HDT's "Reset overlay position", which puts every one of these back to the
    /// defaults in Config.cs.
    private var resetRow: some View {
        HStack {
            Text(String.localizedString("Options_Overlay_General_Label_Reset", comment: ""))
            Spacer()
            Button(String.localizedString("Options_Overlay_General_Button_Reset", comment: "")) {
                Settings.playerDeckTop = 2
                Settings.playerDeckLeft = 99.5
                Settings.playerDeckHeight = 88
                Settings.opponentDeckTop = 12.5
                Settings.opponentDeckLeft = 0.5
                Settings.opponentDeckHeight = 72
                Settings.secretsPanelTop = 5
                Settings.secretsPanelLeft = 15
                Settings.secretsPanelHeight = 40
                AppDelegate.instance().coreManager?.game.updateAllTrackers()
            }
        }
    }
}

/// One side's block: scaling, opacity, vertical centring and the section order.
struct OverlayLayoutSideSection: View {
    let playerType: PlayerType

    @SwiftUI.State private var scaling: Double
    @SwiftUI.State private var opacity: Double
    @SwiftUI.State private var centered: Bool
    @SwiftUI.State private var order: [DeckPanel]

    // Seeded here rather than from .onAppear: a pane the settings window has not
    // shown yet would otherwise render its sliders at their placeholder values,
    // and the sorter - which draws nothing while its list is empty - might never
    // get an .onAppear at all.
    init(playerType: PlayerType) {
        self.playerType = playerType
        let isOpponent = playerType == .opponent
        _scaling = SwiftUI.State(initialValue: isOpponent ? Settings.overlayOpponentScaling : Settings.overlayPlayerScaling)
        _opacity = SwiftUI.State(initialValue: isOpponent ? Settings.opponentOpacity : Settings.playerOpacity)
        _centered = SwiftUI.State(initialValue: isOpponent ? Settings.overlayCenterOpponentStack : Settings.overlayCenterPlayerStack)
        _order = SwiftUI.State(initialValue: DeckPanel.order(for: playerType))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)

            sliderRow(label: String.localizedString("Options_Overlay_Player_Label_Scaling", comment: ""),
                      value: $scaling, range: 30...200, format: "%.0f%%") { value in
                if playerType == .opponent {
                    Settings.overlayOpponentScaling = value
                } else {
                    Settings.overlayPlayerScaling = value
                }
            }

            sliderRow(label: String.localizedString("Options_Overlay_Player_Label_Opacity", comment: ""),
                      value: $opacity, range: 0...100, format: "%.0f%%") { value in
                if playerType == .opponent {
                    Settings.opponentOpacity = value
                } else {
                    Settings.playerOpacity = value
                }
            }

            Toggle(String.localizedString("Options_Overlay_Player_CheckBox_CenterVertically", comment: ""),
                   isOn: Binding(get: { centered }, set: { newValue in
                       centered = newValue
                       if playerType == .opponent {
                           Settings.overlayCenterOpponentStack = newValue
                       } else {
                           Settings.overlayCenterPlayerStack = newValue
                       }
                   }))

            Text(String.localizedString("Overlay_Layout_Section_Order", comment: ""))
                .font(.subheadline)
            DeckPanelSorterView(order: $order, playerType: playerType)
        }
    }

    private var title: String {
        String.localizedString(playerType == .opponent
                               ? "Options_Overlay_Opponent_Header"
                               : "Options_Overlay_Player_Header", comment: "")
    }

    private func sliderRow(label: String, value: Binding<Double>, range: ClosedRange<Double>,
                           format: String, apply: @escaping (Double) -> Void) -> some View {
        HStack {
            Text(label).frame(width: 90, alignment: .leading)
            Slider(value: Binding(get: { value.wrappedValue },
                                  set: { newValue in
                                      value.wrappedValue = newValue
                                      apply(newValue)
                                  }),
                   in: range)
            Text(verbatim: String(format: format, value.wrappedValue))
                .frame(width: 50, alignment: .trailing)
        }
    }
}

/// HDT's `ElementSorter`: one row per section, each moved with an up and a down
/// button. The per-section checkboxes its rows also carry are HSTracker's
/// existing Player / Opponent pane options, so they are not repeated here.
struct DeckPanelSorterView: View {
    @Binding var order: [DeckPanel]
    let playerType: PlayerType

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(order.enumerated()), id: \.element) { index, panel in
                HStack {
                    Button(action: { move(from: index, by: -1) }) {
                        Text(verbatim: "\u{25B2}")
                    }
                    .disabled(index == 0)
                    Button(action: { move(from: index, by: 1) }) {
                        Text(verbatim: "\u{25BC}")
                    }
                    .disabled(index == order.count - 1)
                    Text(panel.localizedName)
                    Spacer()
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.4), lineWidth: 1))
    }

    private func move(from index: Int, by delta: Int) {
        let target = min(max(index + delta, 0), order.count - 1)
        guard target != index else { return }
        var updated = order
        let item = updated.remove(at: index)
        updated.insert(item, at: target)
        order = updated
        DeckPanel.setOrder(updated, for: playerType)
        AppDelegate.instance().coreManager?.game.updateAllTrackers()
    }
}

/// HDT's secret panel scaling, the one thing about `SecretsContainer` that is not
/// set by dragging it.
struct SecretHelperLayoutSection: View {
    @SwiftUI.State private var scaling: Double = Settings.secretsPanelScaling

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String.localizedString("Secret_Helper", comment: "")).font(.headline)
            HStack {
                Text(String.localizedString("Options_Overlay_Opponent_Label_SecretScaling", comment: ""))
                    .frame(width: 110, alignment: .leading)
                Slider(value: Binding(get: { scaling },
                                      set: { newValue in
                                          scaling = newValue
                                          Settings.secretsPanelScaling = newValue
                                      }),
                       in: 0.3...2.0)
                Text(verbatim: String(format: "%.0f%%", scaling * 100))
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }
}
