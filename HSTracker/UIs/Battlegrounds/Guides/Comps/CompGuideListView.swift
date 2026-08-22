//
//  CompGuideListView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's CompGuideList.xaml: title + free/tier7 mode badge, then one
// of loading/empty/error/list depending on currentState.
@available(macOS 10.15, *)
struct CompGuideListView: View {
    @ObservedObject var viewModel: BattlegroundsCompsGuidesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            header
            content
        }
        .padding(9)
    }

    private var header: some View {
        HStack {
            Text("Comp Guides")
                .chunkFive(size: 14)
                .outlinedText()
            Spacer()
            modeBadge
        }
    }

    @ViewBuilder
    private var modeBadge: some View {
        switch viewModel.currentState {
        case .tier7Feature:
            Text("Tier 7 Mode")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "#F5A623"))
        case .baseFeature, .empty, .error, .loading:
            Text("Free")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "#F5C543"))
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.currentState {
        case .loading:
            Text("Loading...")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        case .empty:
            emptyState
        case .error:
            errorState
        case .baseFeature:
            if let comps = viewModel.comps {
                rows(comps)
            }
        case .tier7Feature:
            if let compsByTier = viewModel.compsByTier {
                tieredRows(compsByTier)
            }
        }
    }

    // Matches HDT's CompGuideList.xaml error state exactly: separate title/
    // message text, a styled (not plain) retry button with an icon, and a
    // retry-failed message - the previous version only rendered a single
    // generic line and a bare-bones button, and never surfaced
    // hasRetriedAndFailed at all despite the view model already tracking it.
    private var errorState: some View {
        VStack(spacing: 0) {
            Text("Something went wrong")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#E74C3C"))
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
            Text("We couldn't load the comp guides. Please try again.")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#9CA3A8"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
                .padding(.bottom, 16)
            Button {
                Task { await viewModel.retry() }
            } label: {
                HStack(spacing: 6) {
                    Text("\u{27F3}")
                        .font(.system(size: 14, weight: .bold))
                    Text(viewModel.isRetrying ? "Retrying..." : "Retry")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(viewModel.isRetrying ? Color(hex: "#9CA3A8") : Color(hex: "#26200F"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(minWidth: 140)
                .background(viewModel.isRetrying ? Color(hex: "#5A5A5A") : Color(hex: "#F1C040"))
                .cornerRadius(4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isRetrying)
            if viewModel.hasRetriedAndFailed {
                Text("Still couldn't load the comp guides. Please try again later.")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#E67E22"))
                    .opacity(0.9)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 250)
                    .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }

    // Matches HDT's CompGuideList.xaml empty state: separate title/message,
    // not a single generic line.
    private var emptyState: some View {
        VStack(spacing: 0) {
            Text("No comp guides available")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
            Text("Check back later for updated composition guides.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }

    private func rows(_ comps: [BattlegroundsCompGuideViewModel]) -> some View {
        VStack(spacing: 1) {
            ForEach(comps) { comp in
                CompGuideRow(comp: comp) {
                    viewModel.selectedComp = comp
                }
            }
        }
    }

    private func tieredRows(_ compsByTier: [Int: [BattlegroundsCompGuideViewModel]]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(compsByTier.keys.sorted(), id: \.self) { tier in
                if let comps = compsByTier[tier], !comps.isEmpty {
                    VStack(alignment: .leading, spacing: 1) {
                        tierHeader(tier: tier, colors: comps[0].tierColors)
                        ForEach(comps) { comp in
                            CompGuideRow(comp: comp) {
                                viewModel.selectedComp = comp
                            }
                        }
                    }
                }
            }
        }
    }

    // Matches HDT's CompGuideList.xaml tier group header exactly: a
    // full-width flat (unrounded) stretch bar, not a small badge chip.
    private func tierHeader(tier: Int, colors: [Color]) -> some View {
        Text(BattlegroundsCompGuideViewModel.tierText(tier))
            .font(.system(size: 16, weight: .black))
            .foregroundColor(.white)
            .padding(.leading, 8)
            .padding(.trailing, 8)
            .padding(.top, 2)
            .padding(.bottom, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

@available(macOS 10.15, *)
private struct CompGuideRow: View {
    let comp: BattlegroundsCompGuideViewModel
    let action: () -> Void

    @SwiftUI.State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(comp.compGuide.name)
                    .chunkFive(size: 12)
                    .outlinedText()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    // See CompGuideDetailView's header for why: without an
                    // explicit frame, .outlinedText()'s internal ZStack
                    // reports a narrower ideal width than the Text would
                    // alone, truncating short of the space actually
                    // available before the chevron.
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
                Text("\u{203A}")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            // Matches HDT's CompButton.xaml: the row's own representative-
            // card art, faded (0.2 idle / 0.4 hover), not a flat tint.
            .background(GuideCardArtBackground(card: comp.representativeCard, opacity: isHovering ? 0.4 : 0.2))
            .background(Color.black)
            .clipped()
            // Without this, SwiftUI on macOS derives the Button's tappable/
            // hoverable region from its label's own opaque content rather
            // than the full frame above - the Spacer() and background-only
            // areas then don't register hover or clicks at all, only the
            // chevron glyph did.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
