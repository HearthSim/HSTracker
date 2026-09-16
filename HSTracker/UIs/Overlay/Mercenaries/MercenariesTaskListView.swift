//
//  MercenariesTaskListView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's MercenariesTaskListView: the stack of task rows with the in-game
// notice under them. Replaces the MercenariesTaskListView NSPanel, which sized
// itself to half the Hearthstone window; this one takes its width from its
// content, as the WPF StackPanel does.
@available(macOS 10.15, *)
struct MercenariesTaskListView: View {
    @ObservedObject var viewModel: MercenariesTaskListViewModel
    // Only needed for the width ceiling - see MercenariesTaskView.maxContentWidth.
    let canvasWidth: CGFloat

    // Resolved from the rows themselves - see MercenariesTaskContentWidthKey.
    // Starts at the DockPanel's own MinWidth so the first pass is never
    // narrower than HDT's floor.
    @SwiftUI.State private var measuredContentWidth = MercenariesTaskView.minContentWidth

    // Margin="0,4,0,0" on each row, and "55,4,0,0" on the notice.
    private static let rowSpacing: CGFloat = 4
    private static let noticeInset: CGFloat = 55

    // FontSize and Opacity on the notice's TextBlock, and its Margin="8".
    private static let noticeFontSize: CGFloat = 14
    private static let noticeOpacity: Double = 0.7
    private static let noticeMargin: CGFloat = 8

    // HDT arranges every row at the widest one's natural width. The clamp on
    // top of that is ours: rows under the ceiling are unaffected, and a row over
    // it wraps its description instead of running off the screen.
    private var contentWidth: CGFloat {
        min(max(measuredContentWidth, MercenariesTaskView.minContentWidth),
            MercenariesTaskView.maxContentWidth(canvasWidth: canvasWidth))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.tasks) { task in
                MercenariesTaskView(task: task, contentWidth: contentWidth)
                    .padding(.top, Self.rowSpacing)
            }

            if viewModel.gameNoticeVisible {
                notice
                    .padding(.top, Self.rowSpacing)
                    .padding(.leading, Self.noticeInset)
            }
        }
        .fixedSize()
        .onPreferenceChange(MercenariesTaskContentWidthKey.self) { width in
            measuredContentWidth = width
        }
    }

    private var notice: some View {
        Text(String.localizedString("Task progress will update after the game", comment: ""))
            .font(.system(size: Self.noticeFontSize))
            .foregroundColor(.white)
            .opacity(Self.noticeOpacity)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(Self.noticeMargin)
            .padding(MercenariesTaskView.borderThickness)
            // The notice is a StackPanel child like the rows, so it stretches
            // to the same width they were arranged at, less its own left margin.
            .frame(width: MercenariesTaskView.rowWidth(contentWidth: contentWidth) - Self.noticeInset)
            .background(RoundedRectangle(cornerRadius: MercenariesTaskView.cornerRadius)
                .fill(MercenariesTaskView.panelFill))
            .overlay(
                RoundedRectangle(cornerRadius: MercenariesTaskView.cornerRadius)
                    .strokeBorder(MercenariesTaskView.panelStroke,
                                  lineWidth: MercenariesTaskView.borderThickness)
            )
    }
}
