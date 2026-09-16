//
//  MathUtil.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/14/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Port of HDT's Utility/MathUtil.cs. Only the interpolation chain it uses to
// remap the arena tray card's Unity-space position into screen space is here;
// the rest of that file (CubicEaseIn, Clamp) has Swift equivalents already in
// use and no caller that needs HDT's spelling.
enum MathUtil {
    static func lerp(from: Double, to: Double, value: Double) -> Double {
        return (1 - value) * from + value * to
    }

    static func inverseLerp(value: Double, min: Double, max: Double) -> Double {
        return (value - min) / (max - min)
    }

    static func remap(_ value: Double, _ inMin: Double, _ inMax: Double,
                      _ outMin: Double, _ outMax: Double) -> Double {
        let t = inverseLerp(value: value, min: inMin, max: inMax)
        return lerp(from: outMin, to: outMax, value: t)
    }
}
