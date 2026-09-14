//
//  OverlayOpacityMask.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's Utility/Overlay/OverlayOpacityMask.cs, which OverlayWindow
// owns as its OpacityMaskOverlay and hands straight to its own
// UIElement.OpacityMask.
//
// The overlay covers the whole Hearthstone client, so anything the game draws
// on top of its own board - a hovered card blown up to full size, its tooltips
// and enchantment list, the discover choices, the friends list - comes out
// underneath it. This keeps a set of rectangles, keyed by what put them there,
// that are cut out of the overlay so the game shows through unobstructed.
//
// The rectangles are normalized to the canvas (0..1 on both axes, y down), the
// space RegionDrawer works in. WPF has DrawingBrush to turn them into a mask;
// SwiftUI does not, so what is published here is the rectangle list itself and
// RootOverlayOpacityMaskView builds the equivalent mask out of it.
//
// Everything here runs on the main thread, as HDT's does on the WPF dispatcher
// thread - callers coming off a watcher queue hop first.
@available(macOS 10.15, *)
class OverlayOpacityMask: ObservableObject {
    // The masked regions that will be rendered as transparent, grouped by origin key
    private var maskedRegions = [String: [CGRect]]()

    // HDT's Mask, the DrawingBrush OverlayWindow assigns to its OpacityMask.
    @Published private(set) var maskedRects = [CGRect]()

    // Debug affordance, off in every shipped build: flip this to true and
    // nothing is cut out of the overlay at all - the regions are outlined in
    // red and named instead (RootOverlayOpacityMaskDebugView), so a screenshot
    // says which region is sitting over whatever the overlay has lost. Read at
    // render time, so flipping it means a rebuild.
    static var debugShowRegions = false

    // The key each rect in maskedRects came from, in the same order, for the
    // labels the debug view draws. Only filled while debugShowRegions is on.
    @Published private(set) var maskedRectKeys = [String]()

    private var batchChanges = 0
    private var batchInProgress = false
    private var disabled = false

    /// Suppress mask updates and change events until `body` returns.
    ///
    /// HDT spells this `using var _ = StartBatchUpdate()`, deferring to the end
    /// of the calling method; a closure is the Swift equivalent, and an early
    /// `return` out of it commits the batch just as leaving the method does
    /// there.
    func batchUpdate(_ body: () -> Void) {
        batchInProgress = true
        body()
        batchInProgress = false
        if batchChanges > 0 {
            batchChanges = 0
            createOpacityMask()
        }
    }

    // Traces the mask's own traffic while debugShowRegions is on, so a region
    // that is never asked to go away can be told apart from one that is asked
    // and stays. Silent - and free - in a normal build.
    static func trace(_ message: @autoclosure () -> String) {
        guard debugShowRegions else { return }
        logger.debug("[opacity mask] \(message())")
    }

    func addMaskedRegion(_ key: String, _ region: CGRect) {
        OverlayOpacityMask.trace("add \(key) \(region)")
        maskedRegions[key, default: [CGRect]()].append(region)

        if !batchInProgress {
            createOpacityMask()
        } else {
            batchChanges += 1
        }
    }

    func removeMaskedRegion(_ key: String) {
        OverlayOpacityMask.trace("remove \(key)"
                                 + (maskedRegions[key] == nil ? " (nothing to remove)" : ""))
        guard maskedRegions.removeValue(forKey: key) != nil else { return }

        if !batchInProgress {
            createOpacityMask()
        } else {
            batchChanges += 1
        }
    }

    // Drops the mask entirely while something the overlay draws itself has to
    // stay whole over the game - HDT disables it for the Inspiration panel,
    // which covers the middle of the screen and would otherwise be shot through
    // with whatever the cursor last hovered.
    func disable() {
        disabled = true
        if !maskedRects.isEmpty {
            maskedRects = [CGRect]()
        }
        createOpacityMask()
    }

    func enable() {
        disabled = false
        createOpacityMask()
    }

    private func createOpacityMask() {
        if disabled {
            return
        }
        // HDT excludes each region from a full-canvas RectangleGeometry in turn,
        // which is a true subtraction - overlapping regions stay excluded. The
        // rects go out as they are and RootOverlayOpacityMaskView punches them
        // out one by one with .destinationOut, which behaves the same way (an
        // even-odd fill would not: it would fill the overlaps back in, and card
        // regions routinely overlap their own tooltips).
        //
        // Ordered by key so the published list only changes when the regions
        // themselves do - a dictionary's own iteration order is not stable, and
        // HDT's Mask setter likewise only raises a change when the brush is a
        // different one.
        let keys = maskedRegions.keys.sorted()
        let rects = keys.flatMap { maskedRegions[$0] ?? [CGRect]() }
        if maskedRects != rects {
            maskedRects = rects
        }

        let names = OverlayOpacityMask.debugShowRegions
            ? keys.flatMap { key in (maskedRegions[key] ?? [CGRect]()).indices.map { "\(key) #\($0)" } }
            : [String]()
        if maskedRectKeys != names {
            maskedRectKeys = names
        }
    }
}

// The mask itself: an opaque canvas with every masked region punched out of it.
//
// Lives in its own view, observing the mask directly, so a change to the
// regions redraws this and not the whole overlay tree it is applied to.
@available(macOS 10.15, *)
struct RootOverlayOpacityMaskView: View {
    @ObservedObject var mask: OverlayOpacityMask
    let size: CGSize

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black)
            ForEach(Array(debugRects.enumerated()), id: \.offset) { _, rect in
                Rectangle()
                    .fill(Color.black)
                    .frame(width: max(rect.width, 0) * size.width,
                           height: max(rect.height, 0) * size.height)
                    .position(x: rect.midX * size.width, y: rect.midY * size.height)
                    .blendMode(.destinationOut)
            }
        }
        .compositingGroup()
    }

    // Nothing is punched out while the regions are being debugged, so the
    // overlay stays whole and the outlines can be compared against what it
    // draws.
    private var debugRects: [CGRect] {
        OverlayOpacityMask.debugShowRegions ? [CGRect]() : mask.maskedRects
    }
}

// The debug counterpart to the mask: every masked region outlined in red and
// named by the key that put it there. Draws nothing at all unless
// OverlayOpacityMask.debugShowRegions is on, and takes no hit testing either
// way - it is applied over the masked overlay in RootOverlayView, so the
// outlines survive the very cut-outs they describe.
@available(macOS 10.15, *)
struct RootOverlayOpacityMaskDebugView: View {
    @ObservedObject var mask: OverlayOpacityMask
    let size: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            if OverlayOpacityMask.debugShowRegions {
                ForEach(Array(mask.maskedRects.enumerated()), id: \.offset) { index, rect in
                    region(rect, index: index, name: index < mask.maskedRectKeys.count
                           ? mask.maskedRectKeys[index]
                           : "#\(index)")
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func region(_ rect: CGRect, index: Int, name: String) -> some View {
        let width = max(rect.width, 0) * size.width
        let height = max(rect.height, 0) * size.height

        return ZStack(alignment: .topLeading) {
            Rectangle()
                .stroke(Color.red, lineWidth: 2)
                .frame(width: width, height: height)

            // The key, plus the normalized origin the region was computed at -
            // which is what RegionDrawer's own numbers can be matched against.
            //
            // Stepped down the rect by its index in the list: one key routinely
            // contributes several regions sharing a top edge (a BigCard's card,
            // tooltip and enchantment list all start at the same y), and
            // labels drawn at the same spot would hide each other.
            Text(verbatim: String(format: "%@  %.3f, %.3f", name, rect.origin.x, rect.origin.y))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 3)
                .background(Color.red)
                .fixedSize()
                .offset(x: 2, y: 2 + CGFloat(index % 4) * 15)
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .offset(x: rect.origin.x * size.width, y: rect.origin.y * size.height)
    }
}
