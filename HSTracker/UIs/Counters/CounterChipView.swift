//
//  CounterChipView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/26/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// SwiftUI replacement for the old CounterView.xib (an AppKit NSView pill: a
// circular card-art crop + a ChunkFive counter value, hosted in
// CountersOverlay's NSCollectionView-free custom-layout NSView). Geometry
// below (margins, circle crop offsets, corner radius) is ported verbatim from
// that xib rather than redesigned, so the pill looks identical.

@available(macOS 10.15, *)
final class CounterChipViewModel: ObservableObject, Identifiable {
    let counter: BaseCounter
    var id: ObjectIdentifier { ObjectIdentifier(counter) }

    @Published private(set) var counterValue: String
    @Published private(set) var isDisplayValueLong: Bool
    @Published private(set) var cardImage: NSImage?

    init(counter: BaseCounter) {
        self.counter = counter
        self.counterValue = counter.counterValue
        self.isDisplayValueLong = counter.isDisplayValueLong
        counter.propertyChanged = { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.counterValue = self.counter.counterValue
                self.isDisplayValueLong = self.counter.isDisplayValueLong
            }
        }
        loadImage()
    }

    private func loadImage() {
        guard let cardId = counter.cardIdToShowInUI else { return }
        ImageUtils.art(for: cardId) { [weak self] image in
            DispatchQueue.main.async { self?.cardImage = image }
        }
    }

    // Ported from CounterView.setFontSize(): the font shrinks (floor 5pt)
    // until the word-wrapped value fits the 37pt-tall circle-height budget -
    // the chip's own height never grows past 51pt, only the font shrinks.
    var fontSize: CGFloat {
        guard isDisplayValueLong else { return 15 }
        var size: CGFloat = 16
        while size > 5 {
            if measuredHeight(fontSize: size) <= 37 { break }
            size -= 1
        }
        return size
    }

    private var textWidth: CGFloat {
        isDisplayValueLong ? min(measuredWidth(fontSize: fontSize), 100) : measuredWidth(fontSize: fontSize)
    }

    // CounterView.intrinsicContentSize's formula (2*5 outer margin + 2 border
    // + 37 circle + 10 left text margin + text + 10 right text margin) doesn't
    // carry over unchanged: unlike NSBox's borderWidth, a SwiftUI .overlay()
    // stroke doesn't consume any of the view's own reported layout size, so
    // this constant is measured directly against this view's actual body
    // (via NSHostingView.fittingSize) rather than re-derived by analogy -
    // getting it too small silently clips the digits against the next chip,
    // since the chip is wrapped in .clipped() to stop overflow the other way.
    var chipWidth: CGFloat {
        67 + textWidth
    }

    private func measuredWidth(fontSize: CGFloat) -> CGFloat {
        guard let font = NSFont(name: "ChunkFive", size: fontSize) else { return 20 }
        return ceil((counterValue as NSString).size(withAttributes: [.font: font]).width)
    }

    private func measuredHeight(fontSize: CGFloat) -> CGFloat {
        guard let font = NSFont(name: "ChunkFive", size: fontSize) else { return 0 }
        let bounding = (counterValue as NSString).boundingRect(
            with: NSSize(width: 100, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            attributes: [.font: font])
        return ceil(bounding.height)
    }
}

// Carries the chip's NSView so RootOverlayWindow can tell when the cursor is
// over it, and so the tooltip can be anchored to the chip's own screen-space
// frame (what the old CounterView.tooltipDisplay got from
// `self.convert(self.bounds, to: nil)`).
//
// The chips now sit on the RootOverlay canvas, which stays click-through -
// HDT marks them IsOverlayHoverVisible, not IsOverlayHitTestVisible, so a
// click over a counter still reaches Hearthstone. A click-through window is
// delivered no mouse-entered events at all, which is why the NSTrackingArea
// this used to carry is gone: the cursor is matched against the registry
// instead, exactly as CardHoverRegistry does for the card tooltips.
@available(macOS 10.15, *)
final class CounterHoverNSView: NSView {
    private(set) var counter: BaseCounter?

    // Match NSHostingView's own flip so NSView.convert() stays consistent with
    // SwiftUI's Y-down coordinate space, as CardHoverNSView does.
    override var isFlipped: Bool { true }

    func update(counter: BaseCounter) {
        guard self.counter !== counter else { return }
        self.counter = counter
        if window != nil {
            CounterHoverRegistry.shared.register(self)
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            CounterHoverRegistry.shared.register(self)
        } else {
            CounterHoverRegistry.shared.unregister(self)
            // The counter went away while its tooltip was up (or on its way
            // up) - RootOverlayWindow's own sweep would only notice on the next
            // mouse move, and there may not be one.
            if let counter {
                CounterTooltipController.shared.hide(ifShowing: counter)
            }
        }
    }
}

@available(macOS 10.15, *)
class CounterHoverRegistry {
    static let shared = CounterHoverRegistry()

    struct Entry {
        let counter: BaseCounter
        weak var view: CounterHoverNSView?
    }

    private(set) var entries: [Entry] = []

    func register(_ view: CounterHoverNSView) {
        entries.removeAll { $0.view == nil || $0.view === view }
        guard let counter = view.counter else { return }
        entries.append(Entry(counter: counter, view: view))
    }

    func unregister(_ view: CounterHoverNSView) {
        entries.removeAll { $0.view === view || $0.view == nil }
    }
}

// Drives RelatedCardsTooltipPanel from whichever chip the cursor is over.
// Ported from the old CounterView.tooltipDisplay, including its 0.6s delay -
// HDT's counters carry ToolTipService.InitialShowDelay="600".
@available(macOS 10.15, *)
class CounterTooltipController {
    static let shared = CounterTooltipController()

    private static let showDelay: TimeInterval = 0.6

    private var hoveredCounter: BaseCounter?
    private var shownCounter: BaseCounter?
    private var pendingShow: DispatchWorkItem?

    // Called by RootOverlayWindow's cursor tracking on every mouse move, with
    // the chip under the cursor (if any) and its screen-space frame.
    func hover(counter: BaseCounter?, anchor: NSRect?) {
        guard hoveredCounter !== counter else { return }
        hoveredCounter = counter
        pendingShow?.cancel()
        pendingShow = nil

        guard let counter, let anchor else {
            hideIfShown()
            return
        }

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingShow = nil
            self.show(counter: counter, anchor: anchor)
        }
        pendingShow = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.showDelay, execute: work)
    }

    func hide(ifShowing counter: BaseCounter) {
        guard shownCounter === counter || hoveredCounter === counter else { return }
        if hoveredCounter === counter {
            hoveredCounter = nil
        }
        pendingShow?.cancel()
        pendingShow = nil
        hideIfShown()
    }

    // Ported from CounterView.tooltipDisplay: butt the grid against whichever
    // side has room and clamp it so it never runs past the top of the
    // Hearthstone window. The chip's own screen frame stands in for the
    // counters window's, which is what that code measured against - there is no
    // such window any more, and the canvas's frame is the whole client, which
    // would push the grid off the far side of it.
    private func show(counter: BaseCounter, anchor: NSRect) {
        let cardsToDisplay = counter.cardsToDisplay
        if cardsToDisplay.isEmpty { return }

        let cardImages = RelatedCardsTooltipPanel.shared
        cardImages.setTitle(counter.localizedName)
        cardImages.setCardIdsFromCards(cardsToDisplay)

        let width = CGFloat(cardImages.gridWidth)
        let height = CGFloat(cardImages.gridHeight)
        let hsFrame = SizeHelper.hearthstoneWindow.frame

        let x = anchor.minX < width ? anchor.maxX : anchor.minX - width
        var y = anchor.minY
        if y + height > hsFrame.maxY {
            y = hsFrame.maxY - height
        }

        shownCounter = counter
        cardImages.show(frame: NSRect(x: x, y: y, width: width, height: height))
    }

    // Only ever hides a tooltip this controller put up: the same panel is
    // driven by the trackers' own card tiles.
    private func hideIfShown() {
        guard shownCounter != nil else { return }
        shownCounter = nil
        RelatedCardsTooltipPanel.shared.hide()
    }
}

@available(macOS 10.15, *)
private struct CounterHoverRepresentable: NSViewRepresentable {
    let counter: BaseCounter

    func makeNSView(context: Context) -> CounterHoverNSView { CounterHoverNSView() }
    func updateNSView(_ nsView: CounterHoverNSView, context: Context) {
        nsView.update(counter: counter)
    }
}

@available(macOS 10.15, *)
struct CounterChipView: View {
    @ObservedObject var viewModel: CounterChipViewModel

    var body: some View {
        HStack(spacing: 0) {
            circleImage
                .frame(width: 37, height: 37)
            Text(viewModel.counterValue)
                .chunkFive(size: viewModel.fontSize)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(viewModel.isDisplayValueLong ? nil : 1)
                // maxWidth (not width): a plain `.frame(width: 100)` is a fixed
                // assignment, so it always reports/occupies exactly 100pt even
                // when the current value is short (e.g. PlayedSpellSchoolsCounter's
                // "None" before any spell school has been cast) - badly
                // undersizing chipWidth below, which only budgets for the
                // *measured* (potentially much narrower) text. maxWidth caps
                // wrapping at 100 while still shrinking for shorter text, matching
                // chipWidth's min(measuredWidth, 100) below.
                .frame(maxWidth: viewModel.isDisplayValueLong ? 100 : nil)
                // Without this, a `.frame(width:)` constraint doesn't actually
                // force wrapping - Text still reports (and paints) its full
                // unwrapped width, overflowing into the next chip in the row.
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 10)
        }
        .frame(height: 41, alignment: .leading)
        .background(Color(hex: "#2E3437").opacity(0.75))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#141617"), lineWidth: 2))
        .cornerRadius(20)
        .padding(5)
        .frame(width: viewModel.chipWidth, height: 51, alignment: .leading)
        .clipped()
        .background(CounterHoverRepresentable(counter: viewModel.counter))
    }

    private var circleImage: some View {
        // Ported from CounterView.xib's image constraints: leading = -10,
        // top = -7 relative to the 37x37 circle - i.e. the oversized image's
        // top-left corner sits 10pt left of and 7pt above the circle's own
        // top-left corner. That only reproduces correctly if the image is
        // anchored .topLeading before the offset is applied: a ZStack (which
        // defaults to .center) centers the 55.5x55.5 image first, and the
        // same offset then lands ~9pt further out in both directions than
        // intended, cropping a noticeably different region of the art.
        Group {
            if let cardImage = viewModel.cardImage {
                Image(nsImage: cardImage).resizable().aspectRatio(contentMode: .fill)
            } else {
                Color.clear
            }
        }
        .frame(width: 55.5, height: 55.5)
        .offset(x: -10, y: -7)
        .frame(width: 37, height: 37, alignment: .topLeading)
        .clipShape(Circle())
    }
}
