//
//  MulliganGuideTrialsExhaustedView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/12/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
private extension Color {
    static let hsReplayBlue = Color(red: 0x1D / 255, green: 0x36 / 255, blue: 0x57 / 255)
    static let hsReplayGold = Color(red: 0xFF / 255, green: 0xB0 / 255, blue: 0x0D / 255)
    static let widgetBlack = Color(red: 0x14 / 255, green: 0x16 / 255, blue: 0x17 / 255)
}

// isShown is checked here (this view's own @ObservedObject), not by the
// parent gating whether to instantiate it - same reasoning as
// ConstructedMulliganPreLobbyWidgetView.body: a parent's @ObservedObject
// only re-renders on its own @Published changes, not a nested
// ObservableObject's.
@available(macOS 10.15, *)
struct MulliganGuideTrialsExhaustedView: View {
    @ObservedObject var viewModel: MulliganGuideTrialsExhaustedViewModel

    var body: some View {
        if viewModel.isShown {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image("hsreplay_logo_white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 19, height: 12)
                    Text(String.localizedString("ConstructedTrialsExhausted_Header", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        viewModel.close()
                    } label: {
                        Text("✕").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.hsReplayBlue)

                VStack(alignment: .leading, spacing: 12) {
                    Text(String.localizedString("ConstructedTrialsExhausted_Title", comment: ""))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.hsReplayGold)
                    Text(String.localizedString("ConstructedTrialsExhausted_Description", comment: ""))
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    if viewModel.resetTimeVisibility {
                        Text(String(format: String.localizedString("BattlegroundsPreLobby_Authenticated_TrialsResetsIn", comment: ""), viewModel.trialTimeRemaining ?? ""))
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    Button {
                        viewModel.subscribeNow()
                    } label: {
                        Text(String.localizedString("ConstructedPreLobbyWidget_SubscribeNow", comment: ""))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.widgetBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Color.hsReplayGold)
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
            .frame(width: 380)
            .background(Color.widgetBlack)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.hsReplayBlue, lineWidth: 1))
            .fixedSize()
            // Reported from inside this conditional branch - see the
            // matching comment in ConstructedMulliganPreLobbyWidgetView.body
            // for why (this alert and the widget are mutually exclusive, but
            // both attach an interactive region reporter, so neither should
            // contribute one while hidden).
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: InteractiveRegionPreferenceKey.self, value: [proxy.frame(in: .rootOverlayCanvas)])
                }
            )
        }
    }
}
