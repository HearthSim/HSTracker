//
//  ExperienceCounterView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's ExperienceCounter (Controls/Overlay/ExperienceCounter.xaml), the reward
// track bar it draws over the bottom-right of the hub. This replaces the
// ExperienceOverlay NSPanel and the ExperienceTracker NSView that drew the same
// four images by hand.
final class ExperienceCounterViewModel: ObservableObject {
    // XPDisplay and LevelDisplay, the two bound strings.
    @Published var xpDisplay = ""
    @Published var levelDisplay = ""

    // How much of FullXPBar the clip rectangle exposes, 0...1.
    // ChangeRectangleFill stores it as an absolute Rect against the bar's
    // ActualWidth; a fraction is the same thing without needing the measured
    // width, which the bar's fixed 412 makes constant anyway.
    @Published var percentage = 0.0

    // HDT's Visibility on the control. It has been pinned Hidden there since
    // patch 24.2 - ShowExperienceCounter/HideExperienceCounter are commented
    // out - but HSTracker still shows the counter, so this stays live.
    @Published var isShown = false

    // The mode gate LoadingScreenHandler drives (the counter is only offered in
    // the hub and the other menu scenes). Kept off @Published because nothing
    // draws from it directly: Game.updateExperienceOverlay folds it into
    // isShown along with the setting, which is where HDT's
    // `if(Config.Instance.ShowExperienceCounter)` in ShowExperienceCounter
    // ends up.
    private(set) var visible = false

    // OverlayWindow.AnimatingXPBar, the flag HideExperienceCounter checks so a
    // scene change part way through a level-up does not take the counter away
    // mid-animation.
    private var isAnimating = false

    // ShowExperienceCounter / HideExperienceCounter. Both are called from the
    // log reader as well as from the animation, so callers go through these
    // rather than writing `visible` themselves.
    func show() {
        visible = true
    }

    func hide() {
        if !isAnimating {
            visible = false
        }
    }

    func beginAnimating() {
        isAnimating = true
    }

    func endAnimating() {
        isAnimating = false
    }

    // ChangeRectangleFill(newPercentageFull, instant): the storyboards it picks
    // between are a 3 second RectAnimation and a zero-duration one.
    static let levelUpDuration = 3.0

    func changeFill(_ newPercentageFull: Double, instant: Bool) {
        if instant {
            percentage = newPercentageFull
        } else {
            withAnimation(.linear(duration: Self.levelUpDuration)) {
                percentage = newPercentageFull
            }
        }
    }

    // ResetRectangleFill(), which empties the bar with the zero-duration
    // storyboard so the next level can fill it again.
    func resetFill() {
        percentage = 0
    }
}

struct ExperienceCounterView: View {
    @ObservedObject var viewModel: ExperienceCounterViewModel
    // The canvas width RootOverlayView measured, in the 1080-tall reference
    // space this subtree is authored in. The counter belongs here rather than
    // in the fixed-pixel layer because _experienceCounterBehavior gives it
    // GetScaling = AutoScaling, the Height/1080 factor this subtree applies.
    let canvasWidth: CGFloat

    private static let canvasHeight: CGFloat = 1080

    // _experienceCounterBehavior in OverlayWindow.xaml.cs:
    //   GetRight = () => Height * .35
    //   GetTop   = () => Height * .9652
    // Canvas.Right anchors the element's right edge that far in from the
    // canvas's right edge, and UpdateScaling scales it about that same
    // top-right corner (RenderTransformOrigin (1, 0), since GetLeft is null).
    private static let rightFactor: CGFloat = 0.35
    private static let topFactor: CGFloat = 0.9652

    // <Viewbox Width="85"> around a <Canvas Width="256" Height="256">. The
    // canvas is square, so the Viewbox is 85x85 and everything inside it is
    // scaled by 85/256. Nothing clips, so the parts of the artwork the canvas
    // does not cover - the scroll hanging off its left edge, the gem past its
    // right - still draw.
    private static let viewboxWidth: CGFloat = 85
    private static let canvasSide: CGFloat = 256
    private static let viewboxScale = viewboxWidth / canvasSide

    // Every one of these PNGs carries a 72-dpi pHYs chunk and WPF honours it, so
    // an image given no size of its own measures 96/72 larger than its pixels.
    private static let dpiScale: CGFloat = 96.0 / 72.0

    // The empty track has no Width, so it takes xp_empty_bar.png's 356x65 at
    // that scale, and the Grid the two bars share is exactly that big.
    private static let trackWidth = 356 * dpiScale
    private static let barHeight = 65 * dpiScale

    // Width="412" with HorizontalAlignment="Left" and Stretch="Fill" on
    // FullXPBar, so the filled bar is left-aligned and narrower than the track
    // behind it - a full bar stops about 87% of the way along. That is HDT's,
    // not a rounding of it: the empty track's own 474.67 is what the Grid is
    // sized by, and both numbers are carried over as written.
    private static let fullBarWidth: CGFloat = 412

    // The gem Grid: <Grid Canvas.Left="400" Canvas.Top="-9"> sized by
    // xp_gem.png's own 111x78 at the same scale.
    private static let gemOrigin = CGPoint(x: 400, y: -9)
    private static let gemSize = CGSize(width: 111 * dpiScale, height: 78 * dpiScale)

    // <Image Source="XPScrollIcon" Canvas.Left="-59" Canvas.Top="-20" Height="120"/>,
    // the width following from xp_scroll_item.png's 121x126.
    private static let scrollOrigin = CGPoint(x: -59, y: -20)
    private static let scrollHeight: CGFloat = 120
    private static let scrollWidth = scrollHeight * 121 / 126

    // FontSize="50" on both HearthstoneTextBlocks.
    private static let fontSize: CGFloat = 50
    // Width="400" and Margin="0 -3 0 0" on XPText, HorizontalAlignment="Center"
    // and Margin="-5 0 0 0" on LevelText. Both blocks are vertically centred by
    // OutlinedTextBlock's own constructor, so a margin on one side moves them
    // by half of it.
    private static let xpTextWidth: CGFloat = 400
    private static let xpTextMarginTop: CGFloat = -3
    private static let levelTextMarginLeft: CGFloat = -5

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it, and drawing nothing while hidden - what the window
        // show/hide used to do.
        ZStack(alignment: .topLeading) {
            Color.clear
            if viewModel.isShown {
                viewbox.offset(x: originX, y: originY)
            }
        }
        .frame(width: canvasWidth, height: Self.canvasHeight, alignment: .topLeading)
    }

    private var viewbox: some View {
        counterCanvas
            .frame(width: Self.canvasSide, height: Self.canvasSide, alignment: .topLeading)
            .scaleEffect(Self.viewboxScale, anchor: .topLeading)
            .frame(width: Self.viewboxWidth, height: Self.viewboxWidth, alignment: .topLeading)
    }

    private var counterCanvas: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            xpBar
            gem
            Image("xp_scroll_item")
                .resizable()
                .interpolation(.high)
                .frame(width: Self.scrollWidth, height: Self.scrollHeight)
                .offset(x: Self.scrollOrigin.x, y: Self.scrollOrigin.y)
        }
    }

    // The first Grid on HDT's canvas, at its origin: the empty track, the
    // filled bar clipped to the current fraction, and the "x/y" label over both.
    private var xpBar: some View {
        ZStack(alignment: .topLeading) {
            Image("xp_empty_bar")
                .resizable()
                .interpolation(.high)
                .frame(width: Self.trackWidth, height: Self.barHeight)
            Image("xp_filled_bar")
                .resizable()
                .interpolation(.high)
                .frame(width: Self.fullBarWidth, height: Self.barHeight)
                // FullXPBar.Clip, the RectangleGeometry the storyboards animate.
                // ChangeRectangleFill scales the fraction by the bar's own
                // ActualWidth, which is this 412 and not the track behind it.
                .mask(
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: Self.fullBarWidth * CGFloat(viewModel.percentage))
                        Spacer(minLength: 0)
                    }
                )
            Text(verbatim: viewModel.xpDisplay)
                .chunkFive(size: Self.fontSize)
                .outlinedText()
                .fixedSize()
                .frame(width: Self.xpTextWidth, height: Self.barHeight)
                .offset(x: (Self.trackWidth - Self.xpTextWidth) / 2,
                        y: Self.xpTextMarginTop / 2 + Self.lineHeight * 0.05)
        }
        .frame(width: Self.trackWidth, height: Self.barHeight, alignment: .topLeading)
    }

    // The second Grid, the level gem with its number.
    private var gem: some View {
        ZStack {
            Image("xp_gem")
                .resizable()
                .interpolation(.high)
                .frame(width: Self.gemSize.width, height: Self.gemSize.height)
            Text(verbatim: viewModel.levelDisplay)
                .chunkFive(size: Self.fontSize)
                .outlinedText()
                .fixedSize()
                .offset(x: Self.levelTextMarginLeft / 2, y: Self.lineHeight * 0.05)
        }
        .frame(width: Self.gemSize.width, height: Self.gemSize.height)
        .offset(x: Self.gemOrigin.x, y: Self.gemOrigin.y)
    }

    // Canvas.Right = Height * .35, expressed as the left edge this ZStack needs.
    private var originX: CGFloat {
        canvasWidth - Self.canvasHeight * Self.rightFactor - Self.viewboxWidth
    }

    // Canvas.Top = Height * .9652.
    private var originY: CGFloat {
        Self.canvasHeight * Self.topFactor
    }

    // OutlinedTextBlock.OnRender drops the line by a twentieth of its own
    // height; see BattlegroundsOpponentDeadForView for the same adjustment.
    private static let lineHeight: CGFloat = {
        guard let font = NSFont(name: "ChunkFive", size: ExperienceCounterView.fontSize) else {
            return ExperienceCounterView.fontSize
        }
        return font.ascender - font.descender + font.leading
    }()
}

#Preview {
    let vm = ExperienceCounterViewModel()
    vm.isShown = true
    vm.xpDisplay = "1350/2000"
    vm.levelDisplay = "37"
    vm.percentage = 0.675
    return ExperienceCounterView(viewModel: vm, canvasWidth: 1920)
        .frame(width: 1920, height: 1080)
        .background(Color.gray)
}
