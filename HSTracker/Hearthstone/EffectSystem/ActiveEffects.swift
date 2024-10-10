//
//  ActiveEffects.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/16/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ActiveEffects {
    private var playerEffects = SynchronizedArray<EntityBasedEffect>()
    private var opponentEffects = SynchronizedArray<EntityBasedEffect>()
    private let effectFactory = EffectFactory()

    private func getTargetEffectsList(effect: EntityBasedEffect, controlledByPlayer: Bool) -> SynchronizedArray<EntityBasedEffect> {
        return (controlledByPlayer && effect.effectTarget == .myself) || (!controlledByPlayer && effect.effectTarget == .enemy) ? playerEffects : opponentEffects
    }

    func tryAddEffect(sourceEntity: Entity, controlledByPlayer: Bool) {
        guard let effect = effectFactory.createFromEntity(entity: sourceEntity, controlledByPlayer: controlledByPlayer) else { return }

        let effects = getTargetEffectsList(effect: effect, controlledByPlayer: controlledByPlayer)

        if effect.uniqueEffect && effects.any({ e in e.cardId == effect.cardId }) {
            return
        }
        if effect.effectTarget == .both {
            playerEffects.append(effect)
            opponentEffects.append(effect)
            notifyEffectsChanged()
            return
        }

        effects.append(effect)
        notifyEffectsChanged()
    }

    func tryRemoveEffect(sourceEntity: Entity, controlledByPlayer: Bool) {
        guard let sampleEffect = effectFactory.createFromEntity(entity: sourceEntity, controlledByPlayer: controlledByPlayer) else { return }

        if sampleEffect.effectTarget == .both {
            playerEffects.removeAll { $0.entityId == sourceEntity.id }
            opponentEffects.removeAll { $0.entityId == sourceEntity.id }
            notifyEffectsChanged()
            return
        }

        let effects = getTargetEffectsList(effect: sampleEffect, controlledByPlayer: controlledByPlayer)
        guard let effect = effects.first(where: { $0.entityId == sourceEntity.id }) else { return }

        effects.removeAll { $0.entityId == effect.entityId }
        notifyEffectsChanged()
    }

    func getVisibleEffects(controlledByPlayer: Bool) -> [EntityBasedEffect] {
        let effects = controlledByPlayer ? playerEffects : opponentEffects
        return effects.filter { $0.effectDuration != .multipleTurns }
    }

    func reset() {
        playerEffects.removeAll()
        opponentEffects.removeAll()
        notifyEffectsChanged()
    }

    var effectsChanged: (() -> Void)?

    private func notifyEffectsChanged() {
        effectsChanged?()
    }
}

