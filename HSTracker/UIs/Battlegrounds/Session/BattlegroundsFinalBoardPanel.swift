//
//  BattlegroundsFinalBoardPanel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI
import AppKit

// Carries HDT's inline final-board tooltip (BattlegroundsFinalBoardTooltip) in
// its own borderless child window instead of drawing it inside the session
// panel.
//
// HDT can draw it inline because its session panel sits on the full-size
// overlay canvas, so a tooltip 426pt wide has room to open beside a game row.
// HSTracker's session panel has its own window, only 400pt wide
// (SizeHelper.battlegroundsSessionFrame), and a window clips its content view -
// so an inline tooltip loses everything past the window's right edge. This
// window is positioned with HDT's own offsets, which keeps the layout identical
// while letting the board extend past the panel.
@available(macOS 10.15, *)
class BattlegroundsFinalBoardPanel: NSPanel {
    private let viewModel = BattlegroundsFinalBoardPanelViewModel()
    private var hostingView: NSHostingView<BattlegroundsFinalBoardPanelView>!

    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: true)
        isOpaque = false
        backgroundColor = .clear
        // Purely a tooltip - it must never take the clicks the session window
        // has just stopped passing through.
        ignoresMouseEvents = true
        hasShadow = false
        hidesOnDeactivate = false
        animationBehavior = .none
        isFloatingPanel = true

        hostingView = NSHostingView(rootView: BattlegroundsFinalBoardPanelView(viewModel: viewModel))
        contentView = hostingView
    }

    // `rowFrame` is the hovered row in the session panel's own unscaled
    // coordinate space; `panelView` is the view that space belongs to, and
    // `scaling` the session's scaling setting applied on top of it.
    func show(minions: [Entity], tooltipToRight: Bool, rowFrame: CGRect,
              in panelView: NSView, scaling: CGFloat, parent: NSWindow) {
        let contentSize = Self.measure(minions: minions)
        guard contentSize.width > 0, contentSize.height > 0 else { return }

        let scale = BattlegroundsFinalBoardTooltip.scale * scaling
        viewModel.minions = minions
        viewModel.tooltipToRight = tooltipToRight
        viewModel.contentSize = contentSize
        viewModel.scale = scale

        let left = BattlegroundsFinalBoardTooltip.canvasLeft(tooltipToRight: tooltipToRight,
                                                             contentWidth: contentSize.width)
        let top = BattlegroundsFinalBoardTooltip.canvasTop(minionCount: minions.count)

        // Still in the panel's top-left-origin space, so it converts through
        // the (flipped) hosting view rather than being flipped by hand. The
        // window is widened by arrowMargin on both sides and shifted left to
        // match, so the arrow - which sits outside the box on whichever side
        // faces the row - is not clipped away by the window edge.
        let margin = Self.arrowMargin * scale
        let rectInPanelView = CGRect(x: (rowFrame.minX + left) * scaling - margin,
                                     y: (rowFrame.minY + top) * scaling,
                                     width: contentSize.width * scale + 2 * margin,
                                     height: contentSize.height * scale)
        let rectInWindow = panelView.convert(rectInPanelView, to: nil)
        let screenRect = parent.convertToScreen(rectInWindow)
        guard screenRect.origin.x.isFinite && screenRect.origin.y.isFinite else { return }

        collectionBehavior = Settings.canJoinFullscreen ? [.canJoinAllSpaces, .fullScreenAuxiliary] : []
        setFrame(screenRect, display: true, animate: false)
        if parent.childWindows?.contains(where: { $0 === self }) != true {
            parent.addChildWindow(self, ordered: .above)
        }
        orderFront(nil)
    }

    func hide() {
        orderOut(nil)
    }

    // Unscaled slack left either side of the box for the arrow, which is drawn
    // outside it: a 14pt square rotated 45 degrees reaches ~3pt past the box on
    // the right-opening side, and sits ~19pt clear of it on the left-opening
    // one.
    static let arrowMargin: CGFloat = 20

    // The tooltip's unscaled size. scaleEffect is a render-time transform that
    // leaves the layout size alone, so this measures the view as authored and
    // the caller multiplies it out; the arrow only ever moves by .offset, which
    // does not affect layout, so the size does not depend on contentWidth.
    private static func measure(minions: [Entity]) -> CGSize {
        let probe = NSHostingView(rootView: BattlegroundsFinalBoardTooltip(minions: minions,
                                                                           tooltipToRight: true,
                                                                           contentWidth: 0))
        probe.layoutSubtreeIfNeeded()
        return probe.fittingSize
    }
}

@available(macOS 10.15, *)
class BattlegroundsFinalBoardPanelViewModel: ObservableObject {
    @Published var minions = [Entity]()
    @Published var tooltipToRight = true
    @Published var contentSize: CGSize = .zero
    @Published var scale: CGFloat = BattlegroundsFinalBoardTooltip.scale
}

@available(macOS 10.15, *)
struct BattlegroundsFinalBoardPanelView: View {
    @ObservedObject var viewModel: BattlegroundsFinalBoardPanelViewModel

    var body: some View {
        BattlegroundsFinalBoardTooltip(minions: viewModel.minions,
                                       tooltipToRight: viewModel.tooltipToRight,
                                       contentWidth: viewModel.contentSize.width)
            // FinalBoardCanvas Opacity=".95"
            .opacity(0.95)
            .scaleEffect(viewModel.scale, anchor: .topLeading)
            .frame(width: viewModel.contentSize.width * viewModel.scale,
                   height: viewModel.contentSize.height * viewModel.scale,
                   alignment: .topLeading)
            .padding(.horizontal, BattlegroundsFinalBoardPanel.arrowMargin * viewModel.scale)
    }
}
