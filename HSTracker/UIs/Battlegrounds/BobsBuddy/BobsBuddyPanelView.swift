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
        panelContent
            // UserControl_MouseEnter/MouseLeave.
            .onHover { viewModel.onPanelHover($0) }
            // OverlayWindow.Initialize adds BobsBuddyDisplay to its
            // _clickableElements, so the whole panel takes the mouse - not just
            // the status bar that opens and closes it.
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                           value: [proxy.frame(in: .rootOverlayCanvas)])
                }
            )
    }

    private var panelContent: some View {
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
        // AverageDamageTakenPanel_MouseEnter/MouseLeave, which both panels use.
        .onHover { viewModel.onAverageDamageHover($0) }
    }

    // MARK: - Results and status

    private var centrePanel: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                results
                statusBar
            }
            .background(Color.panelBackground)
            .cornerRadius(3, corners: [.bottomLeft, .bottomRight])

            if viewModel.infoVisible {
                infoPanel(title: String.localizedString("BobsBuddyPanel_Info_Title", comment: ""),
                          text: String.localizedString("BobsBuddyPanel_Info_Description", comment: ""),
                          showsLink: true,
                          onClose: viewModel.closeInfo)
            }

            if viewModel.averageDamageInfoVisible {
                infoPanel(title: String.localizedString("AverageDamage_Info_Title", comment: ""),
                          text: String.localizedString("AverageDamage_Info_Description", comment: ""),
                          showsLink: false,
                          onClose: viewModel.closeAverageDamageInfoVisible ? viewModel.closeAverageDamageInfo : nil)
            }
        }
    }

    // The two notes under the panel: Background="#23272A" BorderBrush="#141617"
    // BorderThickness="1" CornerRadius="3" Margin="0,5,0,0" MaxWidth="352",
    // over a StackPanel with Margin="10" and a close button in the corner.
    private func infoPanel(title: String, text: String, showsLink: Bool, onClose: (() -> Void)?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            body(text, showsLink: showsLink)
        }
        .padding(10)
        .frame(maxWidth: Self.bottomBarMaxWidth, alignment: .leading)
        .background(Color.resultsBackground)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.panelBackground, lineWidth: 1))
        .cornerRadius(3)
        .overlay(closeButton(onClose), alignment: .topTrailing)
        .padding(.top, 5)
    }

    @ViewBuilder
    private func body(_ text: String, showsLink: Bool) -> some View {
        // The description and, on the introduction only, the Hyperlink that
        // follows it in the same TextBlock.
        if showsLink {
            VStack(alignment: .leading, spacing: 0) {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(String.localizedString("BobsBuddyPanel_Info_Link_LearnMore", comment: ""))
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .underline()
                    .onTapGesture {
                        viewModel.openLearnMore()
                    }
            }
        } else {
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func closeButton(_ onClose: (() -> Void)?) -> some View {
        if let onClose {
            // Rectangle Width="14" Height="14" Margin="8", in the shared
            // StatusBarIconStyle.
            StatusBarIcon(shape: HDTCloseShape(),
                          canvasRect: CGRect(x: 22.1666, y: 22.1667, width: 31.6666, height: 31.6667),
                          size: CGSize(width: 14, height: 14),
                          action: onClose)
                .padding(8)
        }
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
    // opens and closes the panel (BottomBar_MouseDown). The two icons sit over
    // it at either end rather than beside the text, as they do in HDT's Grid.
    private var statusBar: some View {
        ZStack {
            HStack(spacing: 4) {
                if viewModel.warningIconVisible {
                    // HDT draws its own appbar_warning here; HSTracker has
                    // always used the system caution badge.
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
            // TextBlock MinHeight="20" Margin="25,0".
            .frame(minHeight: Self.labelHeight)
            .padding(.horizontal, 25)

            // Both are SettingsVisibility, i.e. only while the cursor is over
            // the panel.
            if viewModel.settingsVisible {
                HStack(spacing: 0) {
                    // Rectangle Width="12" Height="18", HorizontalAlignment
                    // Left: opens and closes the introduction.
                    StatusBarIcon(shape: HDTQuestionShape(),
                                  canvasRect: CGRect(x: 25.3333, y: 17.4167, width: 25.3333, height: 39.5833),
                                  size: CGSize(width: 12, height: 18),
                                  action: viewModel.toggleInfo)
                    Spacer(minLength: 0)
                    // Rectangle Width="20" Height="20", HorizontalAlignment
                    // Right: GlobalCommands.ShowSettings("Battlegrounds").
                    StatusBarIcon(shape: HDTGearShape(),
                                  canvasRect: CGRect(x: 18.538, y: 18.5381, width: 38.9239, height: 38.9239),
                                  size: CGSize(width: 20, height: 20),
                                  action: viewModel.showSettings)
                }
            }
        }
        // The Grid's own Margin="5".
        .padding(5)
        .frame(maxWidth: Self.bottomBarMaxWidth)
        // Cursor="Hand" with a near-transparent background, so the whole bar
        // takes the click rather than just the text.
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.toggleResults()
        }
    }

    // MARK: - Icons

    // StatusBarIconStyle: Cursor="Hand", Opacity 0.5, and 0.7 while the cursor
    // is on it.
    private struct StatusBarIcon<S: Shape>: View {
        let shape: S
        let canvasRect: CGRect
        let size: CGSize
        let action: () -> Void

        @SwiftUI.State private var isHovered = false

        var body: some View {
            HDTCanvasIcon(shape: shape, canvasRect: canvasRect, size: size, color: .white)
                .opacity(isHovered ? 0.7 : 0.5)
                .contentShape(Rectangle())
                .onHover { isHovered = $0 }
                .onTapGesture(perform: action)
        }
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
