//
//  BobsBuddyPanelView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
private extension Color {
    // The panel's own background, the win/tie/loss block behind it, and the
    // hairlines between them.
    static let panelBackground = Color(hex: "#141617")
    static let resultsBackground = Color(hex: "#23272A")
    static let separator = Color(hex: "#393D3F")
    static let win = Color(hex: "#8AC66E")
    static let loss = Color(hex: "#C66E6E")
}

// Port of HDT's BobsBuddyPanel.xaml: the combat odds that drop down from the
// top of the screen during a Battlegrounds fight - win/tie/loss with each
// side's lethal chance, the average damage either side deals in its own panel
// to each side, and the status bar that says what the simulator is doing.
@available(macOS 10.15, *)
struct BobsBuddyPanelView: View {
    @ObservedObject var viewModel: BobsBuddyPanelViewModel

    // The storyboards animate both panels between 0 and 55.
    private static let expandedHeight: CGFloat = 55
    // ContainerStyle: MinWidth="60" Margin="5".
    private static let columnMinWidth: CGFloat = 60
    private static let columnPadding: CGFloat = 5
    // LabelContainerStyle: Height="20".
    private static let labelHeight: CGFloat = 20
    // AverageDamageBorderStyle: MinWidth="82".
    private static let averageDamageMinWidth: CGFloat = 82
    // MaxWidth="352" on the bottom bar.
    private static let bottomBarMaxWidth: CGFloat = 352
    // The SpacerStyle Grids between the three panels.
    private static let panelSpacing: CGFloat = 8

    // Gated in here rather than by the parent: RootOverlayView instantiates
    // this unconditionally so its @ObservedObject binding stays live.
    var body: some View {
        if viewModel.isShown {
            panel
        }
    }

    private var panel: some View {
        HStack(alignment: .top, spacing: 0) {
            averageDamagePanel(text: viewModel.averageDamageGivenDisplay,
                               color: .win,
                               opacity: viewModel.playerAverageDamageOpacity)
            Color.clear.frame(width: Self.panelSpacing)
            centrePanel
            Color.clear.frame(width: Self.panelSpacing)
            averageDamagePanel(text: viewModel.averageDamageTakenDisplay,
                               color: .loss,
                               opacity: viewModel.opponentAverageDamageOpacity)
        }
        .fixedSize()
    }

    // MARK: - Average damage

    // One of the two side panels, which slide open with the results when the
    // user has asked for them: Height 0 or 55, MinWidth 82, CornerRadius
    // "0 0 3 3", Margin "5, 0, 0, 5".
    private func averageDamagePanel(text: String, color: Color, opacity: Double) -> some View {
        VStack(spacing: 0) {
            label(String.localizedString("BobsBuddyPanel_Label_AVG", comment: ""),
                  size: 12, weight: .bold, color: color)
                // Margin="0, 5, 0, 0" on this label's own container.
                .padding(.top, 5)
            value(text, size: 17)
            Spacer(minLength: 0)
        }
        .opacity(opacity)
        .frame(minWidth: Self.averageDamageMinWidth)
        .frame(height: viewModel.averageDamageExpanded ? Self.expandedHeight : 0)
        .background(Color.panelBackground)
        .cornerRadius(3, corners: [.bottomLeft, .bottomRight])
        .clipped()
        .padding(.leading, 5)
        .padding(.bottom, 5)
    }

    // MARK: - Results and status

    private var centrePanel: some View {
        VStack(spacing: 0) {
            results
            statusBar
        }
        .background(Color.panelBackground)
        .cornerRadius(3, corners: [.bottomLeft, .bottomRight])
    }

    // ResultPanel: Height 0 or 55 with a 1pt #393D3F line along its bottom.
    private var results: some View {
        HStack(spacing: 0) {
            lethalColumn(text: viewModel.playerLethalDisplay,
                         color: .win,
                         opacity: viewModel.playerLethalOpacity)

            // The Grid the three rates share, which is the only part of the
            // row with its own background.
            HStack(spacing: 0) {
                rateColumn(String.localizedString("BobsBuddyPanel_Label_Win", comment: ""),
                           value: viewModel.winRateDisplay, color: .win)
                Color.separator.frame(width: 1)
                rateColumn(String.localizedString("BobsBuddyPanel_Label_Tie", comment: ""),
                           value: viewModel.tieRateDisplay, color: .white.opacity(0.7),
                           // The ProgressRing sits in the Tie slot, in place of
                           // its percentage while a simulation is running.
                           showsSpinner: true)
                Color.separator.frame(width: 1)
                rateColumn(String.localizedString("BobsBuddyPanel_Label_Loss", comment: ""),
                           value: viewModel.lossRateDisplay, color: .loss)
            }
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxHeight: .infinity)
            .background(Color.resultsBackground)

            lethalColumn(text: viewModel.opponentLethalDisplay,
                         color: .loss,
                         opacity: viewModel.opponentLethalOpacity)
        }
        .frame(height: viewModel.resultsExpanded ? Self.expandedHeight : 0)
        .clipped()
        .overlay(Color.separator.frame(height: 1)
            .opacity(viewModel.resultsExpanded ? 1 : 0), alignment: .bottom)
    }

    private func lethalColumn(text: String, color: Color, opacity: Double) -> some View {
        VStack(spacing: 0) {
            label(String.localizedString("BobsBuddyPanel_Label_Lethal", comment: ""),
                  size: 12, weight: .bold, color: color)
            // Opacity="0.85" on both lethal values.
            percentage(text, size: 17)
                .opacity(0.85)
        }
        .opacity(opacity)
        .frame(minWidth: Self.columnMinWidth)
        .padding(Self.columnPadding)
        // The StackPanel inside the fixed-height ResultPanel stacks from its
        // top, so a column left with only its label - which is what the
        // spinner state is - keeps that label where it was.
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func rateColumn(_ title: String, value: String, color: Color, showsSpinner: Bool = false) -> some View {
        VStack(spacing: 0) {
            label(title, size: 14, weight: .black, color: color)
            ZStack {
                percentage(value, size: 21)
                if showsSpinner && viewModel.showSpinner {
                    SpinningIndicator()
                        .frame(width: 20, height: 20)
                }
            }
        }
        .frame(minWidth: Self.columnMinWidth)
        .padding(Self.columnPadding)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // The bar that both reports what the simulator is doing and, on a click,
    // opens and closes the panel (BottomBar_MouseDown).
    private var statusBar: some View {
        HStack(spacing: 4) {
            if viewModel.warningIconVisible {
                // HDT draws its own appbar_warning here; HSTracker has always
                // used the system caution badge.
                Image(nsImage: NSImage(named: NSImage.cautionName) ?? NSImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }
            Text(viewModel.statusMessage)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
        }
        // TextBlock MinHeight="20" Margin="25,0" inside a Grid with Margin="5".
        .frame(minHeight: Self.labelHeight)
        .padding(.horizontal, 25)
        .padding(5)
        .frame(maxWidth: Self.bottomBarMaxWidth)
        // Cursor="Hand" with a near-transparent background, so the whole bar
        // takes the click rather than just the text.
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.toggleResults()
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                       value: [proxy.frame(in: .rootOverlayCanvas)])
            }
        )
    }

    // MARK: - Text

    // LabelTextStyle / LethalLabelTextStyle, in a Height="20" container.
    private func label(_ text: String, size: CGFloat, weight: Font.Weight, color: Color) -> some View {
        Text(text)
            .font(.system(size: size, weight: weight))
            .foregroundColor(color)
            .lineLimit(1)
            .fixedSize()
            .frame(height: Self.labelHeight)
    }

    // HearthstoneTextBlock: the Chunkfive face with the overlay's outline.
    private func value(_ text: String, size: CGFloat) -> some View {
        Text(verbatim: text)
            .chunkFive(size: size)
            .outlinedText()
            .fixedSize()
    }

    // The rates and lethal chances, which give way to the spinner while a
    // simulation is running (PercentagesVisibility).
    @ViewBuilder
    private func percentage(_ text: String, size: CGFloat) -> some View {
        if viewModel.showSpinner {
            // Collapsed rather than hidden, but the column is sized by its
            // label and MinWidth either way.
            Color.clear.frame(width: 0, height: 0)
        } else {
            value(text, size: size)
        }
    }
}
