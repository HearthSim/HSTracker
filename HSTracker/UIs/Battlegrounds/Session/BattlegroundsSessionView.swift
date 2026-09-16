//
//  BattlegroundsSessionView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's BattlegroundsSession.xaml
// (Controls/Overlay/Battlegrounds/Session): the session recap panel - minion
// types, Tier7 composition stats, MMR, and the session's latest games - stacked
// in a 240pt rounded box with a settings cog that appears on hover.
//
// OverlayWindow.xaml instantiates it with CornerRadius="5" FinalBoardTooltip="true",
// which is the configuration HSTracker uses.
@available(macOS 10.15, *)
struct BattlegroundsSessionView: View {
    @ObservedObject var viewModel: BattlegroundsSessionViewModel

    // Width="240" on the UserControl and on its outer Border, with
    // BorderThickness="1" - so the content inside is 238 wide.
    static let panelWidth: CGFloat = 240
    private static let contentWidth: CGFloat = 238
    private static let cornerRadius: CGFloat = 5

    // The two backgrounds every section is built from: #2E3235 for a section
    // body, #1C2022 for its header strip, divided by #4A5256 hairlines.
    private static let sectionBackground = Color(hex: "#2E3235")
    private static let headerBackground = Color(hex: "#1C2022")
    private static let dividerColor = Color(hex: "#4A5256")

    // The space a hovered game row reports its position in, and the one
    // BattlegroundsFinalBoardPanel places the tooltip against. Its origin is the
    // panel's top-left corner, before the session's scaling is applied.
    static let coordinateSpace = "battlegroundsSessionPanel"

    var body: some View {
        panel
            .coordinateSpace(name: Self.coordinateSpace)
            .onPreferenceChange(HoveredGamePreferenceKey.self) { hovered in
                viewModel.hoveredGame = hovered
            }
            // Attached outside the corner clipping in `panel`, so a hovered
            // game row's final board can extend past the panel's edge - in
            // SwiftUI a clip applies to everything beneath it, which is why the
            // row cannot draw this itself. It reaches across the overlay canvas
            // exactly as HDT's does.
            .overlay(finalBoardTooltip, alignment: .topLeading)
    }

    @ViewBuilder
    private var finalBoardTooltip: some View {
        if let hovered = viewModel.hoveredGame {
            FinalBoardTooltipContainer(minions: hovered.viewModel.finalBoardMinions,
                                       tooltipToRight: viewModel.tooltipToRight,
                                       origin: CGPoint(x: hovered.frame.minX, y: hovered.frame.minY))
                .allowsHitTesting(false)
        }
    }

    private var panel: some View {
        ZStack(alignment: .topTrailing) {
            sections
                .frame(width: Self.contentWidth)
                .background(Self.sectionBackground)
                // HDT rounds the stacked section backgrounds with an
                // OpacityMask fed by the BorderMask border; the inner radius is
                // the outer one less the 1pt border.
                .cornerRadius(Self.cornerRadius - 1)
            cogButton
        }
        .padding(1)
        .background(
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .fill(Self.dividerColor)
        )
        .frame(width: Self.panelWidth)
        .onHover { hovering in
            // Panel_MouseEnter / Panel_MouseLeave
            viewModel.isCogVisible = hovering
        }
    }

    @ViewBuilder
    private var sections: some View {
        VStack(spacing: 0) {
            if viewModel.minionTypesSectionVisible {
                minionTypesSection
            }
            if viewModel.availableCompStatsSectionVisible {
                compStatsSection
            }
            if viewModel.mmrSectionVisible {
                mmrSection
            }
            if viewModel.latestGamesSectionVisible {
                latestGamesSection
            }
        }
    }

    // MARK: - Shared chrome

    // Border BorderBrush="#4A5256" BorderThickness="0,0,0,1" Background="#1C2022"
    // wrapping a HearthstoneTextBlock FontSize="13" Margin="0,6".
    private func sectionHeader<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 0) {
            content()
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Self.headerBackground)
        .overlay(Self.dividerColor.frame(height: 1), alignment: .bottom)
    }

    private func headerTitle(_ key: String) -> some View {
        Text(String.localizedString(key, comment: ""))
            .chunkFive(size: 13)
            .outlinedText()
    }

    // The 11pt, 55%-white column captions HDT uses above each table.
    //
    // These are WPF <Label>s, and a Label's default template carries
    // Padding="5" - so the 5pt inset is part of the control, not something the
    // XAML has to ask for. Every Label ported here needs it; leaving it out is
    // what had the MMR labels sitting on top of their values.
    private func columnLabel(_ key: String) -> some View {
        Text(String.localizedString(key, comment: ""))
            .font(.system(size: 11))
            .foregroundColor(Color.white.opacity(0.55))
            .padding(5)
    }

    // TextBlock Foreground="#FFFFFF" Opacity=".5" TextAlignment="Center"
    private func placeholderText(_ key: String) -> some View {
        Text(String.localizedString(key, comment: ""))
            .font(.system(size: 13))
            .foregroundColor(Color.white.opacity(0.5))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Minion types

    private var minionTypesSection: some View {
        VStack(spacing: 0) {
            sectionHeader {
                Text(viewModel.minionTypesHeaderLabel)
                    .chunkFive(size: 13)
                    .outlinedText()
            }
            ZStack {
                // MinionTypesBodyVisibility is Hidden, not Collapsed, so the
                // lists keep their space while the panel waits for a game and
                // it does not resize the moment one starts.
                VStack(spacing: 0) {
                    if viewModel.availableMinionTypesSectionVisible {
                        tribeRow(viewModel.availableMinionTypes, availability: .available)
                    }
                    if viewModel.minionTypesBorderVisible {
                        Self.dividerColor.frame(height: 1)
                    }
                    if viewModel.bannedMinionTypesSectionVisible {
                        tribeRow(viewModel.bannedMinionTypes, availability: .banned)
                    }
                }
                .opacity(viewModel.minionTypesBodyVisible ? 1 : 0)

                if viewModel.minionTypesWaitingMsgVisible {
                    placeholderText("Battlegrounds_Session_Text_WaitingNextGame")
                        .padding(.bottom, 5)
                        .padding(.horizontal, 4)
                }
            }
        }
        .background(Self.sectionBackground)
    }

    // ItemsPanelTemplate: StackPanel Orientation="Horizontal" Margin="0,8,8,4"
    // HorizontalAlignment="Center" Height="58", each item wrapped in a
    // Border Margin="8,0,0,0".
    private func tribeRow(_ races: [Race], availability: BattlegroundsTribeIconView.Availability) -> some View {
        HStack(spacing: 8) {
            ForEach(races, id: \.self) { race in
                BattlegroundsTribeIconView(race: race, availability: availability)
            }
        }
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 4, trailing: 8))
        .frame(maxWidth: .infinity)
        .frame(height: 58)
    }

    // MARK: - Composition stats

    // ScrollViewer MaxHeight="150" over 30pt rows.
    private static let compStatsRowHeight: CGFloat = 30
    private static let compStatsMaxHeight: CGFloat = 150

    private var compStatsSection: some View {
        VStack(spacing: 0) {
            // This header has BorderThickness="0,1,0,1" - a hairline above it
            // as well, separating it from the minion types section.
            Self.dividerColor.frame(height: 1)
            sectionHeader {
                Image("tier7-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                headerTitle("Battlegrounds_Session_Header_Label_CompStats")
                    .padding(.leading, 6)
            }
            ZStack {
                // CompStatsBodyVisibility is Hidden too - same reasoning as the
                // minion types body above.
                VStack(spacing: 0) {
                    // Grid.ColumnDefinitions 0.9* / 70px / 0.8*, matching
                    // the rows below.
                    HStack(spacing: 0) {
                        columnLabel("Battlegrounds_Session_CompStats_Label_Composition")
                            // Margin="2,0,0,0", inside the column rather than
                            // pushing the whole row across.
                            .padding(.leading, 2)
                            .frame(width: 90, alignment: .leading)
                        columnLabel("Battlegrounds_Session_CompStats_Label_FirstPlace")
                            .frame(width: 70)
                        columnLabel("Battlegrounds_Session_CompStats_Label_AveragePlace")
                            .frame(width: 80)
                    }
                    .frame(width: Self.contentWidth)

                    compStatsRows
                }
                .opacity(viewModel.compStatsBodyVisible ? 1 : 0)
                .allowsHitTesting(viewModel.compStatsBodyVisible)

                if viewModel.compStatsWaitingMsgVisible {
                    placeholderText("Battlegrounds_Session_Text_WaitingNextGame")
                        .padding(.vertical, 26)
                        .padding(.horizontal, 4)
                }
                if viewModel.compStatsErrorVisible {
                    placeholderText("Battlegrounds_Session_CompStats_ErrorMessage")
                        .padding(.vertical, 26)
                        .padding(.horizontal, 4)
                }
            }
        }
        .background(Self.sectionBackground)
    }

    @ViewBuilder
    private var compStatsRows: some View {
        let stats = viewModel.compositionStats ?? []
        // A plain ScrollView would claim all the height offered to it, and this
        // panel is sized to fit its content - so the viewport is measured off
        // the rows themselves, capped at the XAML's MaxHeight.
        let height = min(CGFloat(stats.count) * Self.compStatsRowHeight, Self.compStatsMaxHeight)
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
                ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                    BattlegroundsCompositionStatsRowView(viewModel: stat)
                }
            }
        }
        .frame(width: Self.contentWidth, height: height)
    }

    // MARK: - MMR

    private var mmrSection: some View {
        VStack(spacing: 0) {
            // Border BorderThickness="0,1,0,0" above the header.
            Self.dividerColor.frame(height: 1)
            sectionHeader {
                headerTitle("Battlegrounds_Session_Header_Label_MMR")
            }
            HStack(spacing: 0) {
                mmrColumn(label: viewModel.mmrLabelA, value: viewModel.mmrValueA, color: .white)
                    .frame(width: Self.contentWidth / 2)
                mmrColumn(label: viewModel.mmrLabelB, value: viewModel.mmrValueB, color: viewModel.mmrValueBColor)
                    .frame(width: Self.contentWidth / 2)
                    // Border Grid.Column="1" BorderThickness="1,0,0,0"
                    .overlay(Self.dividerColor.frame(width: 1), alignment: .leading)
            }
        }
        .background(Self.sectionBackground)
    }

    private func mmrColumn(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 0) {
            // Label FontSize="11", with the template's own Padding="5" - which
            // the value's -5 top margin below is measured against.
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.55))
                .padding(5)
            // HearthstoneTextBlock FontSize="18" Margin="0,-5,0,8"
            Text(verbatim: value)
                .chunkFive(size: 18)
                .outlinedText(color)
                .fixedSize()
                .padding(.top, -5)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Latest games

    private var latestGamesSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // Border BorderThickness="0,1,0,0" above the header.
                Self.dividerColor.frame(height: 1)
                sectionHeader {
                    headerTitle("Battlegrounds_Session_Header_Label_Latest_Games")
                }
                if viewModel.gridHeaderVisible {
                    // Grid.ColumnDefinitions 1.7* / 1* / 1*, matching the rows.
                    HStack(spacing: 0) {
                        columnLabel("Battlegrounds_Session_Games_Label_Hero")
                            .frame(width: Self.contentWidth * 1.7 / 3.7)
                        columnLabel("Battlegrounds_Session_Games_Label_Place")
                            .frame(width: Self.contentWidth * 1.0 / 3.7)
                        columnLabel("Battlegrounds_Session_Games_Label_MMR")
                            .frame(width: Self.contentWidth * 1.0 / 3.7)
                    }
                }
                if viewModel.gamesEmptyStateVisible {
                    VStack(spacing: 0) {
                        placeholderText("Battlegrounds_Session_Games_Text_EmptyState1")
                            .padding(EdgeInsets(top: 8, leading: 4, bottom: 0, trailing: 4))
                        placeholderText("Battlegrounds_Session_Games_Text_EmptyState2")
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 8, trailing: 0))
                    }
                }
            }
            .background(Self.sectionBackground)

            ForEach(viewModel.sessionGames) { game in
                BattlegroundsGameRowView(viewModel: game)
            }
        }
    }

    // MARK: - Cog

    // OverlayButton Height="23" Width="24" CornerRadius="3" Margin="4", holding
    // a 14x14 settings glyph, transparent until hovered (#22FFFFFF).
    @ViewBuilder
    private var cogButton: some View {
        if viewModel.isCogVisible {
            SessionCogButton()
                .padding(4)
        }
    }
}

// Places BattlegroundsFinalBoardTooltip at the hovered row's origin. Split out
// so the tooltip's own measured width - which decides where it sits when it
// opens to the left - can be held in @State without that state living on the
// whole panel.
@available(macOS 10.15, *)
private struct FinalBoardTooltipContainer: View {
    let minions: [Entity]
    let tooltipToRight: Bool
    let origin: CGPoint

    @SwiftUI.State private var contentWidth: CGFloat = 0

    var body: some View {
        BattlegroundsFinalBoardTooltip(minions: minions,
                                       tooltipToRight: tooltipToRight,
                                       contentWidth: contentWidth)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: FinalBoardWidthPreferenceKey.self,
                                           value: proxy.size.width)
                }
            )
            .opacity(0.95)
            .scaleEffect(BattlegroundsFinalBoardTooltip.scale, anchor: .topLeading)
            .offset(x: origin.x + BattlegroundsFinalBoardTooltip.canvasLeft(tooltipToRight: tooltipToRight,
                                                                           contentWidth: contentWidth),
                    y: origin.y + BattlegroundsFinalBoardTooltip.canvasTop(minionCount: minions.count))
            .onPreferenceChange(FinalBoardWidthPreferenceKey.self) { width in
                contentWidth = width
            }
    }
}

@available(macOS 10.15, *)
private struct FinalBoardWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// HDT's BtnOptions: Command="{x:Static commands:GlobalCommands.ShowSettings}"
// CommandParameter="Battlegrounds".
@available(macOS 10.15, *)
private struct SessionCogButton: View {
    @SwiftUI.State private var isHovering = false

    var body: some View {
        Button(action: {
            AppDelegate.instance().openPreferences(pane: .battlegrounds)
        }) {
            glyph
                .frame(width: 24, height: 23)
                .background(Color.white.opacity(isHovering ? 0x22 / 255.0 : 0))
                .cornerRadius(3)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
    }

    // HDT fills a 14x14 rectangle from its own appbar_settings icon resource.
    // HSTracker ships no such asset and SF Symbols need macOS 11 while this
    // module's baseline is 10.15, so this uses AppKit's gear template image -
    // the same substitution BattlegroundsMinionPinningView already makes for
    // its own cog.
    @ViewBuilder
    private var glyph: some View {
        if let gear = NSImage(named: NSImage.actionTemplateName) {
            Image(nsImage: gear)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
                .frame(width: 14, height: 14)
        }
    }
}
