//
//  ArenaPlaqueViewModel.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

/// The riveted metal plate that carries an Arenasmith score or a hero tier.
///
/// Port of HDT's `ArenaPlaqueViewModel`. Level 1-5 drives how ornate the plate is:
/// level 1 is a bare plate with a single crooked bolt, level 5 gets all four bolts,
/// both highlight borders, flames and a particle emitter.
///
/// The wobble is deterministic - HDT seeds `Random` with the card id's hash so a
/// given card always draws the same plate - and reproduced here with a small
/// linear congruential generator rather than Swift's `SystemRandomNumberGenerator`,
/// which has no seeding.
@available(macOS 10.15, *)
final class ArenaPlaqueViewModel: ObservableObject {
    struct FlameData {
        let angle: Double
        let scaleX: Double
        let scaleY: Double
    }

    let score: String
    let level: Int
    let isUnderground: Bool
    let innerFlames: [FlameData]
    let outerFlames: [FlameData]

    private let seed: Int

    init(score: String, level: Int, randomSeed: Int, isUnderground: Bool) {
        self.score = score
        self.level = level
        self.isUnderground = isUnderground
        self.seed = randomSeed

        var rng = SeededGenerator(seed: randomSeed)
        func randomScale(_ value: Double) -> Double {
            value * (1 + (rng.nextDouble() * 0.1 - 0.05))
        }

        innerFlames = [
            FlameData(angle: randomScale(25), scaleX: randomScale(-1), scaleY: randomScale(0.8)),
            FlameData(angle: randomScale(25), scaleX: randomScale(-1), scaleY: randomScale(0.7)),
            FlameData(angle: randomScale(4), scaleX: randomScale(-1.2), scaleY: randomScale(1))
        ]
        outerFlames = [
            FlameData(angle: randomScale(-30), scaleX: randomScale(1), scaleY: randomScale(1)),
            FlameData(angle: randomScale(29), scaleX: randomScale(1), scaleY: randomScale(0.75))
        ]
    }

    var isLoading: Bool { score.isEmpty }
    var isLevel5: Bool { level == 5 }
    var isLevel4OrHigher: Bool { level >= 4 }
    var isLevel3OrHigher: Bool { level >= 3 }
    var isLevel2OrHigher: Bool { level >= 2 }
    var isLevel1: Bool { level == 1 }

    /// At level 1 only one bolt is fitted, and the plate hangs crooked from it.
    var singleBoltIndex: Int { abs(seed) % 4 }

    var hasTopLeftBolt: Bool { level != 1 || singleBoltIndex == 0 }
    var hasTopRightBolt: Bool { level != 1 || singleBoltIndex == 1 }
    var hasBottomRightBolt: Bool { level != 1 || singleBoltIndex == 2 }
    var hasBottomLeftBolt: Bool { level != 1 || singleBoltIndex == 3 }

    var angle: Double {
        guard level == 1 else { return 0 }
        let sign: Double = (singleBoltIndex == 0 || singleBoltIndex == 3) ? 1 : -1
        return sign * Double(2 + abs(seed) % 3)
    }

    /// The plate rotates about whichever bolt is holding it up.
    var rotateOrigin: CGPoint {
        let width = 90.0
        let height = 58.0
        let boltRadius = 4.0
        let boltCenter = boltRadius + (level >= 4 ? 6 : level == 2 ? 5 : 4)
        switch singleBoltIndex {
        case 0: return CGPoint(x: boltCenter, y: boltCenter)
        case 1: return CGPoint(x: width - boltCenter, y: boltCenter)
        case 2: return CGPoint(x: width - boltCenter, y: height - boltCenter)
        default: return CGPoint(x: boltCenter, y: height - boltCenter)
        }
    }

    /// Inset of the layers inside the plate, which grows with the level to make
    /// room for the extra highlight borders.
    var innerInset: CGFloat { isLevel5 ? 3 : isLevel3OrHigher ? 2 : 1 }
    var boltInset: CGFloat { isLevel5 ? 6 : isLevel3OrHigher ? 5 : 4 }

    static let size = CGSize(width: 90, height: 58)

    var backgroundGradient: LinearGradient {
        let stops: [Gradient.Stop] = isUnderground
            ? [.init(color: Color(hex: "#721212"), location: 0),
               .init(color: Color(hex: "#C65543"), location: 0.29),
               .init(color: Color(hex: "#B3362D"), location: 0.67),
               .init(color: Color(hex: "#D5644D"), location: 1)]
            : [.init(color: Color(hex: "#126272"), location: 0),
               .init(color: Color(hex: "#3AA9BF"), location: 0.29),
               .init(color: Color(hex: "#2D9AB1"), location: 0.67),
               .init(color: Color(hex: "#5DB2C4"), location: 1)]
        return LinearGradient(gradient: Gradient(stops: stops),
                              startPoint: UnitPoint(x: 0.55, y: -0.1),
                              endPoint: UnitPoint(x: 0.3, y: 1))
    }

    var boltGradient: LinearGradient {
        let stops: [Gradient.Stop] = isUnderground
            ? [.init(color: Color(hex: "#211010"), location: 0),
               .init(color: Color(hex: "#BA9B94"), location: 0.29),
               .init(color: Color(hex: "#4C3737"), location: 0.67),
               .init(color: Color(hex: "#705954"), location: 1)]
            : [.init(color: Color(hex: "#555E6D"), location: 0),
               .init(color: Color(hex: "#E1D9E3"), location: 0.29),
               .init(color: Color(hex: "#7B7E8F"), location: 0.67),
               .init(color: Color(hex: "#B5ABC1"), location: 1)]
        return LinearGradient(gradient: Gradient(stops: stops),
                              startPoint: UnitPoint(x: 0.9, y: 0.1),
                              endPoint: UnitPoint(x: 0, y: 1))
    }

    var glowColor: Color {
        isUnderground ? Color(hex: "#FBB052") : Color(hex: "#01DDFE")
    }

    var outerHighlightColor: Color {
        isUnderground ? Color(hex: "#FBB96F").opacity(0.53) : Color(hex: "#8899FF").opacity(0.8)
    }

    var innerHighlightColor: Color {
        Color.white.opacity(isUnderground ? 0.2 : 0.27)
    }

    /// Radial gradients the level-5 particle emitter tints its motes with.
    var particleGradients: [Gradient] {
        isUnderground
            ? [Gradient(colors: [Color(hex: "#FBD96F"), Color(hex: "#CD3E00").opacity(0)]),
               Gradient(colors: [Color(hex: "#FBD96F"), Color(hex: "#E13E08").opacity(0)]),
               Gradient(colors: [Color(hex: "#FBD96F"), Color(hex: "#FBB052").opacity(0)])]
            : [Gradient(colors: [.white, Color(hex: "#01DDFE").opacity(0)]),
               Gradient(colors: [.white, Color(hex: "#01FEDD").opacity(0)]),
               Gradient(colors: [.white, Color(hex: "#BADDFE").opacity(0)])]
    }
}

/// Deterministic PRNG so a card always renders the same plate.
/// Same shape as .NET's `Random` usage in HDT: seed in, uniform doubles out.
struct SeededGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed)) &* 6364136223846793005 &+ 1442695040888963407
    }

    mutating func nextDouble() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(1 << 53)
    }
}
