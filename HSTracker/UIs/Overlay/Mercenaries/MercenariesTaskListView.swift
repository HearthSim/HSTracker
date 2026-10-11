//
//  MercenariesTaskListView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// The rows' natural height, reported up so the list can decide whether it has
// to scroll. There is only one report per list; max() keeps it from being
// overwritten by a default from anywhere else in the subtree.
private struct MercenariesTaskContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// HDT's MercenariesTaskListView: the stack of task rows with the in-game
// notice under them. Replaces the MercenariesTaskListView NSPanel, which sized
// itself to half the Hearthstone window; this one takes its width from its
// content, as the WPF StackPanel does.
struct MercenariesTaskListView: View {
    @ObservedObject var viewModel: MercenariesTaskListViewModel
    // Only needed for the width ceiling - see MercenariesTaskView.maxContentWidth.
    let canvasWidth: CGFloat
    // The tallest the list may be before it scrolls - see
    // MercenariesTasksOverlayView.listMaxHeight.
    let maxHeight: CGFloat
    // The window-pixel gap between the list and the button under it, which
    // the list's hover region has to bridge - see hoverRegion below.
    let gap: CGFloat

    // Resolved from the rows themselves - see MercenariesTaskContentWidthKey.
    // Starts at the DockPanel's own MinWidth so the first pass is never
    // narrower than HDT's floor.
    @SwiftUI.State private var measuredContentWidth = MercenariesTaskView.minContentWidth

    // The rows' natural height, measured the same way. Starts at zero, so the
    // first pass lays the list out unscrolled and only switches to the
    // ScrollView once that pass has shown it does not fit.
    @SwiftUI.State private var measuredContentHeight: CGFloat = 0

    private var isScrollable: Bool {
        measuredContentHeight > maxHeight
    }

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
        Group {
            if isScrollable {
                // A plain ScrollView claims all the height offered to it, so
                // it is given the rows' own width and the cap as its height.
                ScrollView(.vertical, showsIndicators: true) {
                    content
                }
                .frame(width: MercenariesTaskView.rowWidth(contentWidth: contentWidth),
                       height: maxHeight)
            } else {
                content
            }
        }
        .background(regions)
        .onPreferenceChange(MercenariesTaskContentWidthKey.self) { width in
            measuredContentWidth = width
        }
        .onPreferenceChange(MercenariesTaskContentHeightKey.self) { height in
            measuredContentHeight = height
        }
    }

    // HDT's list is only hover-visible and closes as soon as the cursor leaves
    // the button. Here it stays open while the cursor is on the list itself,
    // so a list that scrolls can be reached - and, while it scrolls, it is
    // also hit-test visible, so the window takes the scroll wheel over it.
    // A list that fits stays click-through.
    //
    // The hover region reaches down across the gap to the button, or the list
    // would close on the way from one to the other. The gap is in window
    // pixels, which is what .rootOverlayCanvas measures in.
    private var regions: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .rootOverlayCanvas)
            var hoverFrame = frame
            hoverFrame.size.height += gap
            return Color.clear
                .preference(key: HoverRegionPreferenceKey.self,
                            value: [HoverRegion(id: HoverRegionID.mercenariesTasksList, rect: hoverFrame)])
                .preference(key: InteractiveRegionPreferenceKey.self, value: isScrollable ? [frame] : [])
        }
    }

    private var content: some View {
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
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: MercenariesTaskContentHeightKey.self,
                                       value: proxy.size.height)
            }
        )
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
