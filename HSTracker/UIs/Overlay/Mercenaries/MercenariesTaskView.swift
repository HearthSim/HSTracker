//
//  MercenariesTaskView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Reports the natural width of a row's text column. HDT gets this for free:
// its rows sit in a StackPanel measured with infinite width, so every row is
// first measured at the width its own title and description want, and then
// arranged at the widest of them. SwiftUI has no separate measure pass, so
// each row measures itself off-screen and the list reduces the reports with
// max() and hands the winner back down - see MercenariesTaskListView.
struct MercenariesTaskContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// HDT's MercenariesTaskView: one visitor task, drawn as a rounded panel with
// the mercenary's framed portrait hanging off its left edge. Replaces the
// MercenariesTask.xib NSView of the same shape.
struct MercenariesTaskView: View {
    let task: MercenariesTaskViewModel
    // The text column's width, resolved across the whole list. Rows are all
    // arranged at the same width, as StackPanel arranges them.
    let contentWidth: CGFloat

    // MinWidth on the DockPanel that holds the title, description and bar.
    static let minContentWidth: CGFloat = 280

    // The Border's own Margin="50,0,0,0", which leaves room for the portrait
    // sitting over its left edge, plus the BorderThickness="2" and the
    // DockPanel's Margin="50,8,8,8" - everything between the row's left edge
    // and the text column.
    private static let panelMargin: CGFloat = 50
    static let borderThickness: CGFloat = 2
    private static let contentInset = EdgeInsets(top: 8, leading: 50, bottom: 8, trailing: 8)

    // Total row width for a given text column width: what the StackPanel ends
    // up arranging every row (and the game notice) at.
    static func rowWidth(contentWidth: CGFloat) -> CGFloat {
        panelMargin + borderThickness * 2
            + contentInset.leading + contentWidth + contentInset.trailing
    }

    // A ceiling HDT does not have. Its list sits on a Canvas, which measures
    // with infinite width, so a row grows to whatever its description wants and
    // TextWrapping="Wrap" never fires. That holds up there because HDT's mirror
    // cannot fill in $owner_merc, $bounty_* or $additional_mercs and leaves the
    // tokens in the string; HSTracker's does fill them in, and
    // $additional_mercs expands to a comma-joined list of mercenary names. The
    // list is anchored to the right edge, so an unbounded row grows off the
    // left of the screen.
    //
    // Half the canvas less a row's fixed furniture - which is where the AppKit
    // list capped itself (SizeHelper.mercenariesTaskListView took
    // hearthstoneWindow.width / 2). Floored at HDT's own MinWidth so the cap can
    // never pull a row below it, and rows shorter than the cap are laid out
    // exactly as HDT lays them out.
    static func maxContentWidth(canvasWidth: CGFloat) -> CGFloat {
        max(minContentWidth, canvasWidth / 2 - rowWidth(contentWidth: 0))
    }

    // Background / BorderBrush, shared with the button and the game notice.
    static let panelFill = Color(hex: "#221717")
    static let panelStroke = Color(hex: "#110C0C")
    static let cornerRadius: CGFloat = 3

    // Background on the progress track and on the filled part of it.
    private static let trackFill = Color(hex: "#110C0C")
    private static let barFill = Color(hex: "#6E1E1E")

    // FontSize on the title, the description and the HearthstoneTextBlock in
    // the middle of the bar.
    private static let titleFontSize: CGFloat = 18
    private static let descriptionFontSize: CGFloat = 14
    private static let progressFontSize: CGFloat = 16

    // The Ellipse behind the portrait: Width="80" Height="104"
    // Margin="10,0,0,0", drawn over the panel's left edge.
    private static let ellipseSize = CGSize(width: 80, height: 104)
    private static let ellipseInset: CGFloat = 10

    // The portrait Grid: Width="100" Height="100" Margin="0,2", holding a
    // 110x110 image and the 100x100 frame over it.
    private static let portraitBox: CGFloat = 100
    private static let portraitBoxMargin: CGFloat = 2
    private static let portraitImageSize: CGFloat = 110

    var body: some View {
        // The Grid: the panel first, then the ellipse and the portrait over it,
        // all left-aligned and vertically centred on each other.
        ZStack(alignment: .leading) {
            panel
                .padding(.leading, Self.panelMargin)

            Ellipse()
                .fill(Self.panelFill)
                .frame(width: Self.ellipseSize.width, height: Self.ellipseSize.height)
                .padding(.leading, Self.ellipseInset)

            portrait
                .frame(width: Self.portraitBox, height: Self.portraitBox)
                .padding(.vertical, Self.portraitBoxMargin)
        }
        .background(contentSizer)
    }

    private var panel: some View {
        // DockPanel: Title docked Top, the progress Grid docked Bottom, and the
        // description as the fill child between them.
        VStack(alignment: .leading, spacing: 0) {
            titleText
            descriptionText
                .padding(.vertical, 4)
            progressBar
                .padding(.top, 4)
        }
        .frame(width: contentWidth, alignment: .leading)
        .padding(Self.contentInset)
        // WPF insets a Border's child by its BorderThickness on top of any
        // padding, so the content sits 2pt further in than the margins say.
        .padding(Self.borderThickness)
        .background(RoundedRectangle(cornerRadius: Self.cornerRadius).fill(Self.panelFill))
        .overlay(
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .strokeBorder(Self.panelStroke, lineWidth: Self.borderThickness)
        )
    }

    private var titleText: some View {
        Text(verbatim: task.title)
            .font(.system(size: Self.titleFontSize, weight: .semibold))
            .foregroundColor(.white)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var descriptionText: some View {
        OverlayFormattedText.text(task.description, size: Self.descriptionFontSize)
            .foregroundColor(.white)
            .fixedSize(horizontal: false, vertical: true)
    }

    // The progress Grid: a rounded track with the filled part left-aligned
    // inside it, and the HearthstoneTextBlock centred over both. The Grid takes
    // its height from that text (Margin="0,2"), and the track stretches to it.
    private var progressBar: some View {
        Text(verbatim: task.progressText)
            .chunkFive(size: Self.progressFontSize)
            .outlinedText()
            // OutlinedTextBlock.OnRender drops an unconstrained left-aligned
            // line by a twentieth of its own height before drawing it.
            .offset(y: Self.progressLineHeight * 0.05)
            .fixedSize()
            .padding(.vertical, 2)
            .frame(width: contentWidth)
            .background(track)
    }

    private var track: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .fill(Self.trackFill)
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .fill(Self.barFill)
                    .frame(width: proxy.size.width * CGFloat(task.progress))
            }
            // HDT's converter multiplies the track width by a progress that is
            // never clamped, so a task finished past its quota asks for a bar
            // wider than the track. The rounded Border it sits in is what keeps
            // that off-screen in WPF; this is the same clip.
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
        }
    }

    private var portrait: some View {
        ZStack {
            // Margin="-5,-5,0,0" on the 110x110 portrait needs no .offset() of
            // its own. The Image's alignment is WPF's default Stretch, and
            // ComputeAlignmentOffset degenerates Stretch to Left/Top once the
            // child is bigger than the slot its margins leave it - 110 against
            // 105 here - so WPF draws it at exactly (-5,-5) in the Grid, which
            // is where a ZStack puts a 110 child in a 100 box anyway. Applying
            // the margin on top of that centring moved it twice, and the clip
            // ellipse's centre (55,55) landed up and left of the frame art
            // instead of dead centre of it.
            MercenariesTaskPortrait(card: task.card)
                .frame(width: Self.portraitImageSize, height: Self.portraitImageSize)

            Image("merc_frame")
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: Self.portraitBox, height: Self.portraitBox)
        }
        .frame(width: Self.portraitBox, height: Self.portraitBox)
    }


    // Measured off-screen at the width the title and description want, which is
    // what the row reports up to the list. Everything else in the row is either
    // fixed or driven by the resolved contentWidth, so those two are the only
    // things that can widen it.
    private var contentSizer: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleText
            descriptionText
        }
        .fixedSize()
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: MercenariesTaskContentWidthKey.self,
                                       value: proxy.size.width)
            }
        )
        .hidden()
    }

    private static let progressLineHeight: CGFloat = {
        guard let font = NSFont(name: "ChunkFive", size: MercenariesTaskView.progressFontSize) else {
            return MercenariesTaskView.progressFontSize
        }
        return font.ascender - font.descender + font.leading
    }()
}

// The mercenary's portrait, clipped to the oval the frame art leaves open.
private struct MercenariesTaskPortrait: View {
    let card: Card?

    @SwiftUI.State private var image: NSImage?

    var body: some View {
        // Color.clear rather than a bare `if`: .onAppear does not fire on a
        // view that renders empty, and until the art arrives that is exactly
        // what this is - so the loader would never run.
        ZStack {
            Color.clear
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            }
        }
        // Image.Clip = EllipseGeometry Center="55,55" RadiusX="35" RadiusY="47",
        // in the 110x110 image's own space.
        .clipShape(Ellipse().path(in: CGRect(x: 20, y: 8, width: 70, height: 94)))
        .onAppear(perform: load)
    }

    private func load() {
        guard let card else { return }
        if let cached = ImageUtils.cachedArt(cardId: card.id) {
            image = cached
            return
        }
        ImageUtils.art(for: card.id) { img in
            DispatchQueue.main.async {
                self.image = img
            }
        }
    }
}
