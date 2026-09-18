//
//  MercenariesTaskViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// HDT's MercenariesTaskViewModel: one visitor task, already resolved down to
// the strings the row draws. Immutable (every property is get-only on HDT's
// side too), so a struct rather than an ObservableObject - the list view model
// republishes the whole array when the mirror is re-read.
struct MercenariesTaskViewModel: Identifiable {
    // The visitor the task belongs to. HDT has no equivalent - WPF's
    // ItemsControl identifies items by reference - but SwiftUI's ForEach needs
    // a stable key, and one visitor offers one task at a time.
    let id: Int

    // CardPortrait, which HDT wraps in a CardAssetViewModel for the Portrait
    // asset type; the SwiftUI side resolves that through ImageUtils.art
    // instead, same as every other portrait in these ports.
    let card: Card?
    let title: String
    let description: String
    let progressText: String
    let progress: Double

    init(id: Int, mercCard: Card, title: String, description: String, quota: Int, progress: Int) {
        self.id = id
        self.card = mercCard
        self.title = title
        self.description = description
        let completed = progress >= quota
        progressText = completed
            ? String.localizedString("Completed!", comment: "")
            : "\(progress) / \(quota)"
        // HDT divides straight through (1.0 * progress / quota). Guarded here
        // because a zero quota would hand SwiftUI a NaN frame width, which is a
        // hard crash rather than the harmless Infinity WPF's converter would
        // multiply into a bar width - and a task whose quota is zero has
        // already been called complete on the line above.
        self.progress = quota > 0 ? 1.0 * Double(progress) / Double(quota) : 1
    }
}
