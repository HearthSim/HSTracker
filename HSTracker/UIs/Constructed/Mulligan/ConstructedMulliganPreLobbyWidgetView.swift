//
//  ConstructedMulliganPreLobbyWidgetView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
private extension Color {
    static let hsReplayBlue = Color(red: 0x1D / 255, green: 0x36 / 255, blue: 0x57 / 255)
    static let hsReplayGold = Color(red: 0xFF / 255, green: 0xB0 / 255, blue: 0x0D / 255)
    static let widgetBlack = Color(red: 0x14 / 255, green: 0x16 / 255, blue: 0x17 / 255)
    // Matches HDT's own sale tag/tooltip accent color (#b94038).
    static let saleRed = Color(red: 0xB9 / 255, green: 0x40 / 255, blue: 0x38 / 255)
}

@available(macOS 10.15, *)
struct ConstructedMulliganPreLobbyWidgetView: View {
    @ObservedObject var viewModel: ConstructedMulliganPreLobbyWidgetViewModel

    var body: some View {
        // isShown is checked here, in a View holding its own @ObservedObject
        // directly on this view model, rather than by the parent (RootOverlayView)
        // gating whether to instantiate this view at all - a parent's
        // @ObservedObject only re-renders on *its own* @Published changes, not
        // on a nested ObservableObject's, so gating from outside would freeze
        // at whatever isShown was when the parent was first constructed.
        if viewModel.isShown && viewModel.visibility {
            ZStack {
                VStack(spacing: 0) {
                    header
                    if !viewModel.isCollapsed {
                        body_
                    }
                }
                .frame(minWidth: viewModel.panelMinWidth)
                .background(Color.widgetBlack)
                .overlay(RoundedRectangle(cornerRadius: 0).stroke(Color.hsReplayBlue, lineWidth: 1))
                .fixedSize()

                if viewModel.isOnboardingVisible {
                    onboardingModal
                }
            }
            // Reported from inside this conditional branch, not by an
            // external wrapper in RootOverlayView, so a sibling that's
            // currently hidden (e.g. MulliganGuideTrialsExhaustedView, shown
            // mutually exclusively with this widget) never contributes a
            // stale/zero rect that could overwrite this one depending on
            // ZStack evaluation order - PreferenceKey only sees
            // contributions from views that actually call .preference().
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: InteractiveRegionPreferenceKey.self, value: proxy.frame(in: .rootOverlayCanvas))
                }
            )
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image("hsreplay_logo_white")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 19, height: 12)
            Text(String.localizedString("ConstructedPreLobbyWidget_Header", comment: ""))
                .font(.system(size: 12))
                .foregroundColor(.white)
            Spacer()
            if viewModel.showOnboardingButton {
                Button {
                    viewModel.toggleOnboarding()
                } label: {
                    Text("?")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            Button {
                viewModel.toggleCollapsed()
            } label: {
                MulliganChevron()
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
    private var body_: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.showOnboardingNotification {
                onboardingNotification
            }
            switch viewModel.userState {
            case .loading:
                Text(String.localizedString("ConstructedPreLobbyWidget_Loading", comment: ""))
                    .foregroundColor(.white)
                    .font(.system(size: 12))
                    .padding(16)
            case .unknownPlayer:
                unknownPlayerBody
            case .validPlayer:
                validPlayerBody
            case .subscribed:
                subscribedBody
            case .disabled:
                disabledBody
            }
        }
    }

    private var onboardingNotification: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String.localizedString("ConstructedPreLobbyWidget_OnboardingNotification_Title", comment: ""))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    viewModel.dismissOnboardingNotification()
                } label: {
                    Text("✕").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            Text(String.localizedString("ConstructedPreLobbyWidget_OnboardingNotification_Description", comment: ""))
                .font(.system(size: 12))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text(String.localizedString("ConstructedPreLobbyWidget_OnboardingNotification_LearnMore", comment: ""))
                .font(.system(size: 12))
                .foregroundColor(.white)
                .underline()
                .onTapGesture { viewModel.learnMoreOnboarding() }
        }
        .padding(12)
        .background(Color.hsReplayBlue)
        .cornerRadius(4)
        .padding(12)
    }

    private var saleTooltip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Matches HDT: this title string is shared verbatim across all
                // pre-lobby sale tooltips (Battlegrounds, Constructed, Arena).
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
        .padding(.top, 8)
    }

    private var unknownPlayerBody: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(String.localizedString("ConstructedPreLobbyWidget_Anonymous_Hover", comment: ""))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0x07 / 255, green: 0x61 / 255, blue: 0x8B / 255))
            Text(String.localizedString("ConstructedPreLobbyWidget_Anonymous_Details", comment: ""))
                .font(.system(size: 12))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 182)
        .padding(16)
    }

    private var validPlayerBody: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(String(format: String.localizedString("BattlegroundsPreLobby_Authenticated_Welcome", comment: ""), viewModel.username ?? ""))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.hsReplayGold)
            HStack(spacing: 6) {
                Text(String(format: String.localizedString("BattlegroundsPreLobby_Authenticated_TrialsRemaining", comment: ""), viewModel.trialUsesRemaining ?? 0))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Text("i")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    .guideTooltip(String.localizedString("ConstructedPreLobbyWidget_TrialsRemaining_Tooltip", comment: ""))
            }
            if viewModel.resetTimeVisibility {
                Text(String(format: String.localizedString("BattlegroundsPreLobby_Authenticated_TrialsResetsIn", comment: ""), viewModel.trialTimeRemaining ?? ""))
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            Text(String.localizedString("ConstructedPreLobbyWidget_Join", comment: ""))
                .font(.system(size: 12))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            ZStack(alignment: .topTrailing) {
                Button {
                    viewModel.subscribeNow()
                } label: {
                    Text(String.localizedString("ConstructedPreLobbyWidget_SubscribeNow", comment: ""))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.widgetBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.hsReplayGold)
                }
                .buttonStyle(.plain)

                if viewModel.saleTagVisibility {
                    Text(String.localizedString("ConstructedPreLobbyWidget_SaleTag", comment: ""))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.saleRed)
                        .cornerRadius(3)
                        .offset(x: 4, y: -8)
                }
            }

            if viewModel.saleTooltipVisibility {
                saleTooltip
            }

            switch viewModel.refreshSubscriptionState {
            case .signIn:
                HStack(spacing: 4) {
                    Text(String.localizedString("ConstructedPreLobbyWidget_AlreadySubscribed", comment: ""))
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                    Text(String.localizedString("ConstructedPreLobbyWidget_SignIn", comment: ""))
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .underline()
                        .onTapGesture { viewModel.signIn() }
                }
            case .refresh:
                HStack(spacing: 4) {
                    Text(String.localizedString("ConstructedPreLobbyWidget_AlreadySubscribed", comment: ""))
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                    Text(String.localizedString("ConstructedPreLobbyWidget_Refresh", comment: ""))
                        .font(.system(size: 11))
                        .foregroundColor(viewModel.refreshAccountEnabled ? .white : .gray)
                        .underline()
                        .onTapGesture { if viewModel.refreshAccountEnabled { viewModel.refreshAccount() } }
                }
            case .hidden:
                EmptyView()
            }
        }
        .frame(width: 230)
        .padding(16)
    }

    private var subscribedBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String.localizedString("ConstructedPreLobbyWidget_Subscribed", comment: ""))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.hsReplayGold)
            Button {
                viewModel.myStats()
            } label: {
                Text(String.localizedString("ConstructedPreLobbyWidget_MyStats", comment: ""))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.white, lineWidth: 1))
                    // Unlike SUBSCRIBE NOW above (a filled .background(), so
                    // opaque and hit-testable everywhere), this button is
                    // just an unfilled stroke outline - without an explicit
                    // contentShape, only the stroke line and the text glyphs
                    // themselves count as tappable, not the empty interior.
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 230)
        .padding(16)
    }

    private var disabledBody: some View {
        HStack(spacing: 8) {
            Text(String.localizedString("ConstructedPreLobbyWidget_Disabled", comment: ""))
                .font(.system(size: 12))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 182)
        .padding(16)
    }

    private var onboardingModal: some View {
        ZStack {
            Color.black.opacity(0.4)
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button {
                        viewModel.toggleOnboarding()
                    } label: {
                        Text("✕").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
                HStack(alignment: .top, spacing: 12) {
                    onboardingBox(titleKey: "ConstructedPreLobbyWidget_OnboardingBar_Title", descriptionKey: "ConstructedPreLobbyWidget_OnboardingBar_Description")
                    Image("mulligan-gv2-elements")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150)
                    onboardingBox(titleKey: "ConstructedPreLobbyWidget_OnboardingShadowBar_Title", descriptionKey: "ConstructedPreLobbyWidget_OnboardingShadowBar_Description")
                }
                onboardingBox(titleKey: "ConstructedPreLobbyWidget_OnboardingSynergy_Title", descriptionKey: "ConstructedPreLobbyWidget_OnboardingSynergy_Description")
                    .frame(width: 220)
            }
            .padding(24)
            .background(Color.widgetBlack)
            .cornerRadius(4)
        }
        .fixedSize()
    }

    private func onboardingBox(titleKey: String, descriptionKey: String) -> some View {
        VStack(spacing: 0) {
            Text(String.localizedString(titleKey, comment: ""))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(Color(red: 0x2A / 255, green: 0x31 / 255, blue: 0x35 / 255))
            Text(String.localizedString(descriptionKey, comment: ""))
                .font(.system(size: 11))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(8)
                .background(Color.widgetBlack)
        }
        .frame(width: 180)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(red: 0x3A / 255, green: 0x42 / 255, blue: 0x46 / 255), lineWidth: 1))
    }
}
