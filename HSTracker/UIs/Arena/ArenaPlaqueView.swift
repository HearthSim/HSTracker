//
//  ArenaPlaqueView.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

/// Port of HDT's `ArenaPlaque.xaml`.
///
/// The plate is drawn as concentric rounded rectangles, exactly as the XAML layers
/// them: gradient ground, an outer highlight ring at level 5, an inner highlight
/// ring from level 3, a dark inner overlay, then the flames, the bolts and the
/// score.
@available(macOS 10.15, *)
struct ArenaPlaqueView: View {
    @ObservedObject var viewModel: ArenaPlaqueViewModel

    private var size: CGSize { ArenaPlaqueViewModel.size }

    var body: some View {
        ZStack {
            // Recessed backing plate, visible around the badge itself.
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.black.opacity(0.25))

            plate
                .rotationEffect(.degrees(viewModel.angle), anchor: anchor)
        }
        .frame(width: size.width, height: size.height)
    }

    /// The level-1 plate hangs from its single bolt, so rotation is anchored there
    /// rather than at the centre.
    private var anchor: UnitPoint {
        UnitPoint(x: viewModel.rotateOrigin.x / size.width,
                  y: viewModel.rotateOrigin.y / size.height)
    }

    private var plate: some View {
        // A background rather than another stack layer: the outer flames are laid
        // out in a box far larger than the plate, and a ZStack would take its size
        // from them and stretch the plate to match. A background is offered the
        // parent's size but never sets it. It also stays clear of the plate's own
        // drop shadow, which HDT likewise applies below these.
        plateBody
            .background(outerFlames, alignment: .topLeading)
    }

    private var plateBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(viewModel.backgroundGradient)

            if viewModel.isLevel5 {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(viewModel.outerHighlightColor, lineWidth: 1)
            }

            if viewModel.isLevel3OrHigher {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(viewModel.innerHighlightColor, lineWidth: 1)
                    .padding(viewModel.isLevel5 ? 2 : 1)
            }

            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.66))
                .padding(viewModel.innerInset)

            if viewModel.isLevel4OrHigher {
                innerFlames
            }

            RoundedRectangle(cornerRadius: viewModel.isLevel5 ? 3 : 4)
                .strokeBorder(Color.black.opacity(0.25), lineWidth: 1)
                .padding(viewModel.innerInset)

            bolts

            if viewModel.isLevel5, #available(macOS 12.0, *) {
                ArenaPlaqueParticlesView(gradients: viewModel.particleGradients)
                    // HDT's Margin="-10,-10,-10,3": the motes drift out past the
                    // plate on three sides but stop short of its bottom edge.
                    .padding(EdgeInsets(top: -10, leading: -10, bottom: 3, trailing: -10))
                    .allowsHitTesting(false)
            }

            score
        }
        .shadow(color: .black.opacity(0.4), radius: 7, x: 1.5, y: 1.5)
    }

    private var score: some View {
        // Text(verbatim:) so a numeric score never picks up locale grouping, and
        // fixedSize so it is never truncated inside the plate.
        Text(verbatim: viewModel.score)
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.white)
            .fixedSize()
            .shadow(color: viewModel.isLevel5 ? viewModel.glowColor.opacity(0.8) : .clear, radius: 7)
    }

    // HDT's flames, from `ArenaPlaque.xaml`. Three sit inside the plate, clipped
    // to its inner rounded rect; two more hang off its sides at level 5.
    private static let innerFlameHeight: CGFloat = 70
    private static let outerFlameHeights: [CGFloat] = [77, 99]
    /// HDT puts the outer pair in a Grid inset -100 on every side.
    private static let outerFlameInset: CGFloat = 100
    /// Their `Margin`s, verbatim; the offsets below are derived from these the way
    /// WPF derives them, rather than being measured off a screenshot.
    private static let outerFlameMargins = [
        EdgeInsets(top: 0, leading: -84, bottom: 0, trailing: 0),
        EdgeInsets(top: 0, leading: 65, bottom: 4, trailing: 0)
    ]

    private static var innerFlameOrigins: [CGPoint] {
        let width = ArenaFlame.width(forHeight: innerFlameHeight)
        return [
            CGPoint(x: -25, y: 10),
            CGPoint(x: 16, y: 23),
            // The third is placed from the canvas's right edge: Canvas.Right="-27".
            CGPoint(x: ArenaPlaqueViewModel.size.width + 27 - width, y: 20)
        ]
    }

    /// The Grid the outer pair lives in, 100pt proud of the plate on every side.
    private static var outerFlameBox: CGSize {
        CGSize(width: ArenaPlaqueViewModel.size.width + 2 * outerFlameInset,
               height: ArenaPlaqueViewModel.size.height + 2 * outerFlameInset)
    }

    /// A fixed-size child in a stretched Grid slot ends up centred in what the
    /// margins leave of it, which is what decides where these land. In the Grid's
    /// own space, so the stack below can be sized to it.
    private static func outerFlameOrigin(index: Int) -> CGPoint {
        let height = outerFlameHeights[index]
        let margin = outerFlameMargins[index]
        let box = outerFlameBox
        let free = CGSize(width: box.width - margin.leading - margin.trailing,
                          height: box.height - margin.top - margin.bottom)
        return CGPoint(x: margin.leading + (free.width - ArenaFlame.width(forHeight: height)) / 2,
                       y: margin.top + (free.height - height) / 2)
    }

    private var innerFlames: some View {
        flameStack(canvas: size,
                   heights: [Self.innerFlameHeight, Self.innerFlameHeight, Self.innerFlameHeight],
                   origins: Self.innerFlameOrigins,
                   data: viewModel.innerFlames)
            // The XAML dims them to 0.6 until level 5, and tightens the clip from
            // Rect 2,2,86,54 to 3,3,84,52 at the same time.
            .opacity(viewModel.isLevel5 ? 1 : 0.6)
            .clipShape(RoundedRectangle(cornerRadius: 3).inset(by: viewModel.isLevel5 ? 3 : 2))
    }

    @ViewBuilder
    private var outerFlames: some View {
        if viewModel.isLevel5 {
            outerFlameStack
        }
    }

    private var outerFlameStack: some View {
        // Laid out in the oversized Grid and then shifted back over the plate.
        // The stack has to be that big: nothing clips these, and the rasterization
        // below would otherwise cut them off at the plate's edge.
        flameStack(canvas: Self.outerFlameBox,
                   heights: Self.outerFlameHeights,
                   origins: (0..<2).map { Self.outerFlameOrigin(index: $0) },
                   data: viewModel.outerFlames)
            .offset(x: -Self.outerFlameInset, y: -Self.outerFlameInset)
    }

    private func flameStack(canvas: CGSize,
                            heights: [CGFloat],
                            origins: [CGPoint],
                            data: [ArenaPlaqueViewModel.FlameData]) -> some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            ForEach(Array(data.enumerated()), id: \.offset) { index, flame in
                ArenaFlameView(isUnderground: viewModel.isUnderground)
                    .frame(width: ArenaFlame.width(forHeight: heights[index]), height: heights[index])
                    // HDT applies these as a LayoutTransform, which resizes the
                    // layout box and so shifts the centring; taking them as a
                    // render transform about the centre instead moves each flame by
                    // a point or two, which is inside the jitter they already carry.
                    .scaleEffect(x: CGFloat(flame.scaleX), y: CGFloat(flame.scaleY))
                    .rotationEffect(.degrees(flame.angle))
                    .offset(x: origins[index].x, y: origins[index].y)
            }
        }
        .frame(width: canvas.width, height: canvas.height, alignment: .topLeading)
        // HDT caches both flame grids as bitmaps (BitmapCache RenderAtScale="2").
        // Worth matching: these are by far the heaviest drawings in the overlay,
        // and they sit next to a particle emitter that redraws every frame.
        .drawingGroup()
        .allowsHitTesting(false)
    }

    private var bolts: some View {
        ZStack {
            bolt(present: viewModel.hasTopLeftBolt, alignment: .topLeading)
            bolt(present: viewModel.hasTopRightBolt, alignment: .topTrailing)
            bolt(present: viewModel.hasBottomLeftBolt, alignment: .bottomLeading)
            bolt(present: viewModel.hasBottomRightBolt, alignment: .bottomTrailing)
        }
        .padding(viewModel.boltInset)
    }

    /// The hole is always drawn - an unfitted bolt leaves an empty socket, which is
    /// what makes the level-1 plate read as barely held on.
    private func bolt(present: Bool, alignment: Alignment) -> some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.07))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.13), lineWidth: 1))
                .padding(1)
            if present {
                Circle().fill(viewModel.boltGradient)
                Circle().strokeBorder(Color.white.opacity(0.53), lineWidth: 1)
            }
        }
        .frame(width: 8, height: 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
}

/// Level-5 sparkle. Port of HDT's `ParticleEmitter.xaml.cs`, which spawns motes on
/// a timer and drifts them upward.
///
/// Canvas and TimelineView are macOS 12, so on 10.15/11 the plate simply renders
/// without its sparkle rather than the whole badge being unavailable.
@available(macOS 12.0, *)
struct ArenaPlaqueParticlesView: View {
    let gradients: [Gradient]

    private struct Particle {
        let seed: Double
        let gradient: Int
        let size: CGFloat
        let xOffset: CGFloat
        let duration: Double
        let delay: Double
    }

    // Fixed set rather than a live spawner: the plate is small and short-lived on
    // screen, and a deterministic set avoids per-frame allocation in the overlay.
    private let particles: [Particle] = {
        var rng = SeededGenerator(seed: 0x5A17)
        return (0..<14).map { index in
            Particle(seed: rng.nextDouble(),
                     gradient: index % 3,
                     size: 3 + CGFloat(rng.nextDouble()) * 4,
                     xOffset: CGFloat(rng.nextDouble()),
                     duration: 1.6 + rng.nextDouble() * 1.8,
                     delay: rng.nextDouble() * 2.4)
        }
    }()

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    for particle in particles {
                        let phase = ((now + particle.delay) / particle.duration)
                            .truncatingRemainder(dividingBy: 1)
                        let y = size.height * (1 - phase)
                        let x = size.width * particle.xOffset
                        // Fade in at the bottom, out at the top.
                        let alpha = sin(phase * .pi)
                        let rect = CGRect(x: x - particle.size / 2,
                                          y: y - particle.size / 2,
                                          width: particle.size,
                                          height: particle.size)
                        let gradient = gradients[particle.gradient % gradients.count]
                        context.opacity = alpha
                        context.fill(Path(ellipseIn: rect),
                                     with: .radialGradient(gradient,
                                                           center: CGPoint(x: rect.midX, y: rect.midY),
                                                           startRadius: 0,
                                                           endRadius: particle.size))
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}
