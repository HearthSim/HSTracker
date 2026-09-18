//
//  SecretsPanelViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit
import SwiftUI

/// The secret helper - HDT's `SecretsContainer` and the `CardListSecrets` inside
/// it (`Windows/OverlayWindow.xaml`), which sits on its own canvas beside the two
/// deck stacks and is placed, scaled and resized exactly the way they are:
///
///   Canvas.SetTop(SecretsContainer, Height * SecretsTop / 100)
///   Canvas.SetLeft(SecretsContainer, Width * SecretsLeft / 100)
///   SecretsContainer.RenderTransform = new ScaleTransform(SecretsPanelScaling, ...)
///   SecretsHeight => (SecretsPanelHeight / 100 * Height) / SecretsPanelScaling
///
/// It replaces the `CardList` window controller HSTracker framed with
/// `SizeHelper.secretTrackerFrame`.
class SecretsPanelViewModel: ObservableObject {
    @Published var isShown = false
    @Published private(set) var cards = TrackerCardListContent()

    @Published var top = Settings.secretsPanelTop
    @Published var left = Settings.secretsPanelLeft
    @Published var height = Settings.secretsPanelHeight
    @Published var scaling = Settings.secretsPanelScaling

    private var version = 0

    func set(cards: [Card]) {
        version += 1
        self.cards = TrackerCardListContent(cards: cards, version: version, reset: false)
    }

    var cardCount: Int { cards.cards.count }

    func reloadSettings() {
        // Not while a drag is in flight - see TrackerPanelViewModel.reloadSettings.
        if lastDragTranslation == nil {
            top = Settings.secretsPanelTop
            left = Settings.secretsPanelLeft
            height = Settings.secretsPanelHeight
        }
        scaling = Settings.secretsPanelScaling
    }

    private func save() {
        Settings.secretsPanelTop = top
        Settings.secretsPanelLeft = left
        Settings.secretsPanelHeight = height
    }

    private var lastDragTranslation: CGSize?

    /// HDT scales the secrets panel's drag delta by `SecretsPanelScaling`
    /// (`OverlayWindow.Input.cs`), unlike the deck stacks'.
    func drag(translation: CGSize, canvasSize: CGSize) {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return }
        let previous = lastDragTranslation ?? .zero
        let dx = translation.width - previous.width
        let dy = translation.height - previous.height
        lastDragTranslation = translation

        top += Double(dy / canvasSize.height) * 100.0 * scaling
        left += Double(dx / canvasSize.width) * 100.0 * scaling
    }

    func resize(translation: CGSize, canvasSize: CGSize) {
        guard canvasSize.height > 0 else { return }
        let previous = lastDragTranslation ?? .zero
        let dy = translation.height - previous.height
        lastDragTranslation = translation

        height = max(height + Double(dy / canvasSize.height) * 100.0, 5)
    }

    func endDrag() {
        lastDragTranslation = nil
        save()
    }
}
