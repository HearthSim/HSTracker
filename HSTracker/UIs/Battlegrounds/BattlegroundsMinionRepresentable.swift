//
//  BattlegroundsMinionRepresentable.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HSTracker draws a Battlegrounds board minion (art, border, keyword badges and
// stats) with a custom NSView rather than a SwiftUI view, so the SwiftUI
// overlays that need one host the existing view instead of re-implementing that
// drawing: the session panel's final-board tooltip and the hovered opponent's
// warband both go through here.
//
// BattlegroundsMinionView composes its art at 300x350 and then stretches that
// composite into whatever bounds it is given, so callers must size the slot at
// that aspect (see `height(forWidth:)`) - a square slot renders every minion
// visibly squashed.
@available(macOS 10.15, *)
struct BattlegroundsMinionRepresentable: NSViewRepresentable {
    let entity: Entity

    // The 300x350 composite's aspect, as the height that goes with a given
    // slot width.
    static func height(forWidth width: CGFloat) -> CGFloat {
        width * 350 / 300
    }

    func makeNSView(context: Context) -> BattlegroundsMinionView {
        let view = BattlegroundsMinionView()
        view.entity = entity
        return view
    }

    func updateNSView(_ nsView: BattlegroundsMinionView, context: Context) {
        nsView.entity = entity
        nsView.needsDisplay = true
    }
}
