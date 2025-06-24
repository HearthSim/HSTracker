//
//  StatTier.swift
//  HSTracker
//
//  Created by IHume on 2025-06-24.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
enum Tier: String {
    case S = "S"
    case A = "A"
    case B = "B"
    case C = "C"
    case D = "D"
    case F = "F"
    
    var gradient: Gradient {
        switch self {
        case .S:
            Gradient(colors: [
                Color(red: 0.25, green: 0.54, blue: 0.75),
                Color(red: 0.22, green: 0.37, blue: 0.48)
            ])
        case .A:
            Gradient(colors: [
                Color(red: 0.41, green: 0.61, blue: 0.21),
                Color(red: 0.34, green: 0.47, blue: 0.21)
            ])
        case .B:
            Gradient(colors: [
                Color(red: 0.57, green: 0.63, blue: 0.21),
                Color(red: 0.41, green: 0.47, blue: 0.21)
            ])
        case .C:
            Gradient(colors: [
                Color(red: 0.63, green: 0.48, blue: 0.21),
                Color(red: 0.47, green: 0.37, blue: 0.21)
            ])
        case .D:
            Gradient(colors: [
                Color(red: 0.63, green: 0.28, blue: 0.21),
                Color(red: 0.47, green: 0.26, blue: 0.21)
            ])
        case .F:
            Gradient(colors: [
                Color(red: 0.63, green: 0.21, blue: 0.21),
                Color(red: 0.47, green: 0.21, blue: 0.21)
            ])
        }
    }
}

@available(macOS 10.15, *)
struct StatTier: View {
    let tier: Tier

    var body: some View {
        VStack(spacing: 0, content: {
            Text("TIER")
                .font(Font.system(size: 11, weight: .light))
            Text(tier.rawValue)
                .font(Font.system(size: 22, weight: .bold))
        })
        .foregroundColor(Color.white)
        .frame(width: 60, height: 60)
        .background(LinearGradient(gradient: tier.gradient, startPoint: .top, endPoint: .bottom))
        .cornerRadius(5)
    }
}

@available(macOS 10.15, *)
#Preview {
    HStack {
        StatTier(tier: Tier.S)
        StatTier(tier: Tier.A)
        StatTier(tier: Tier.B)
        StatTier(tier: Tier.C)
        StatTier(tier: Tier.D)
        StatTier(tier: Tier.F)
    }
}
