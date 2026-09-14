//
//  ArenaPreDraftView.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
private extension Color {
    static let hsReplayBlue = Color(red: 0x1D / 255, green: 0x36 / 255, blue: 0x57 / 255)
    static let hsReplayGold = Color(red: 0xFF / 255, green: 0xB0 / 255, blue: 0x0D / 255)
    static let widgetBlack = Color(red: 0x14 / 255, green: 0x16 / 255, blue: 0x17 / 255)
    // HDT's own sale accent (#b94038), shared with the other pre-lobby panels.
    static let saleRed = Color(red: 0xB9 / 255, green: 0x40 / 255, blue: 0x38 / 255)
}

/// The Arenasmith panel on the Arena landing screen. Port of HDT's
/// `ArenaPreDraft.xaml`.
@available(macOS 10.15, *)
struct ArenaPreDraftView: View {
    @ObservedObject var viewModel: ArenaPreDraftViewModel

    /// HDT's ArenaPanel is a fixed 264pt wide.
    private static let panelWidth: CGFloat = 264

    var body: some View {
        // isShown is read here, inside a view holding its own @ObservedObject on
        // this view model, rather than by RootOverlayView deciding whether to
        // build this view at all - a parent only re-renders on its *own*
        // @Published changes, so gating from out there would freeze at whatever
        // isShown was when the parent was first constructed.
        if viewModel.isShown {
            VStack(spacing: 0) {
                header
                if !viewModel.isCollapsed {
                    content
                }
            }
            .frame(width: Self.panelWidth)
            .background(Color.widgetBlack)
            .overlay(Rectangle().stroke(Color.hsReplayBlue, lineWidth: 1))
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                           value: [proxy.frame(in: .rootOverlayCanvas)])
                }
            )
        }
    }

    private var header: some View {
        HStack(spacing: 4) {
            Image("arenasmith-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 19, height: 12)
            Text(String.localizedString("ArenaPreDraft_Panel_Title", comment: ""))
                .font(.system(size: 12))
                .foregroundColor(.white)
            Spacer()
            Button {
                viewModel.signIn()
            } label: {
                Image("settings-hsreplay")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.plain)
            Button {
                viewModel.toggleCollapsed()
            } label: {
                ArenaChevron()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .frame(width: 10, height: 6)
                    .rotationEffect(.degrees(viewModel.isCollapsed ? 180 : 0))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.hsReplayBlue)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.arenasmithAvailable {
        case .loading:
            loadingBody
        case .unavailable:
            // Arenasmith is off for this mode - usually a new patch, with the
            // model still being retrained.
            //
            // Centered because HDT's panel-wide TextBlock style sets
            // TextAlignment="Center", which applies to every state including
            // this one.
            VStack(alignment: .center, spacing: 4) {
                Text(String.localizedString("ArenaPreDraft_Panel_Preparing", comment: ""))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(String.localizedString("ArenaPreDraft_Panel_GatheringData", comment: ""))
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
        case .available:
            switch viewModel.userState {
            case .loading, .invalidated:
                loadingBody
            case .unknownPlayer:
                unknownPlayerBody
            case .trialPlayer:
                trialPlayerBody
            case .subscriber:
                subscriberBody
            }
        }
    }

    private var loadingBody: some View {
        Text(String.localizedString("ArenaPreDraft_Panel_Loading", comment: ""))
            .font(.system(size: 12))
            .foregroundColor(.white)
            .padding(16)
    }

    /// No Blizzard account id, so trials can't be attributed - subscribing is the
    /// only route.
    private var unknownPlayerBody: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(String.localizedString("ArenaPreDraft_Panel_JoinForAccess", comment: ""))
                .font(.system(size: 12))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            subscribeButton
            if viewModel.saleTooltipVisibility {
                saleTooltip
            }
        }
        .frame(width: 230)
        .padding(16)
    }

    private var trialPlayerBody: some View {
        VStack(alignment: .center, spacing: 8) {
            if viewModel.draftState == .preDraft {
                Text(String.localizedString("ArenaPreDraft_Panel_ReadyForRatings", comment: ""))
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text(String.localizedString("ArenaPreDraft_Panel_TrialDraftsRemaining", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    // verbatim: the count may be "3/5", and a plain Text would
                    // locale-format a bare number.
                    Text(verbatim: viewModel.remainingTrials)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize()
                    Text("i")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        .guideTooltip(String.localizedString("ArenaPreDraft_Panel_TrialDraftsRemaining_Tooltip",
                                                             comment: ""))
                }

                if viewModel.showResetTime {
                    HStack(spacing: 4) {
                        Text(String.localizedString("ArenaPreDraft_Panel_TrialsResetsIn", comment: ""))
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        Text(verbatim: viewModel.trialTimeRemaining ?? "")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .fixedSize()
                    }
                }
            } else {
                // Mid-draft: either this run is already covered by a trial, or it
                // is not and only a subscription will help.
                if viewModel.isTrialEnabledForDeck {
                    Text(String.localizedString("ArenaPreDraft_Panel_TrialActive", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(String.localizedString("ArenaPreDraft_Panel_JoinForUnlimitedAccess", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(String.localizedString("ArenaPreDraft_Panel_JoinThisDraft", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            subscribeButton

            // HDT floats this tooltip on a Canvas to the right of the button
            // (Canvas.Right="-250"); rendered inline here, matching how the
            // Constructed pre-lobby widget already does it in HSTracker.
            if viewModel.saleTooltipVisibility {
                saleTooltip
            }

            switch viewModel.refreshSubscriptionState {
            case .hidden:
                EmptyView()
            case .signIn:
                alreadySubscribed(action: String.localizedString("ArenaPreDraft_Panel_SignInToSubscription", comment: "")) {
                    viewModel.signIn()
                }
            case .refresh:
                alreadySubscribed(action: String.localizedString("ArenaPreDraft_Panel_RefreshSubscription", comment: "")) {
                    if viewModel.refreshAccountEnabled {
                        viewModel.refreshAccount()
                    }
                }
            }
        }
        .frame(width: 230)
        .padding(16)
    }

    private var subscriberBody: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(String.localizedString("ArenaPreDraft_Panel_ThanksForSubscribing", comment: ""))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.hsReplayGold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(String.localizedString("ArenaPreDraft_Panel_ReadyForRatings", comment: ""))
                .font(.system(size: 12))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                viewModel.viewArenaStats()
            } label: {
                Text(String.localizedString("ArenaPreDraft_Panel_ViewArenaStats", comment: ""))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.hsReplayBlue)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 230)
        .padding(16)
    }

    private var subscribeButton: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                viewModel.subscribeNow()
            } label: {
                Text(String.localizedString("ArenaPreDraft_Panel_SubscribeNow", comment: ""))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.widgetBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.hsReplayGold)
            }
            .buttonStyle(.plain)

            if viewModel.saleTagVisibility {
                Text(String.localizedString("BattlegroundsPreLobby_SaleTag", comment: ""))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.saleRed)
                    .cornerRadius(3)
                    .offset(x: 4, y: -8)
            }
        }
    }

    private var saleTooltip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Shared verbatim across all three pre-lobby panels in HDT.
                Text(String.localizedString("BattlegroundsPreLobby_SaleTooltip_Title", comment: ""))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    viewModel.closeSaleTooltip()
                } label: {
                    Text("✕").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            Text(viewModel.saleDescription)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.saleRed)
        .cornerRadius(4)
    }

    private func alreadySubscribed(action: String, onTap: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(String.localizedString("ArenaPreDraft_Panel_AlreadySubscribed", comment: ""))
                .font(.system(size: 11))
                .foregroundColor(.white)
            Text(verbatim: action)
                .font(.system(size: 11))
                .foregroundColor(.white)
                .underline()
                .onTapGesture(perform: onTap)
        }
    }
}

/// The collapse chevron, matching the one on the Constructed pre-lobby widget.
@available(macOS 10.15, *)
struct ArenaChevron: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}
