//
//  RewoundEntityCreationFilter.swift
//  HSTracker
//

import Foundation

/// Decides which lines of a rewound section of the power log still have to end up in the log
/// we upload.
///
/// A rewind undoes what the rewound play did, but it does not un-create the entities that were
/// created while it resolved: cards added to a hand and enchantments can survive into the
/// timeline the game keeps, and later lines still reference them. Dropping their FULL_ENTITY
/// blocks leaves the uploaded log with tag changes on entities that were never created, which
/// the replay parser rejects. So we keep the entity creations - and only those, because keeping
/// the rewound BLOCK_START PLAY as well would make the play count twice.
final class RewoundEntityCreationFilter {
    private static let powerLinePrefix = "GameState.DebugPrintPower() - "
    private static let entityCreation = "FULL_ENTITY - Creating"
    private static let entityTag = "tag="

    // Indentation of the creation we are currently inside of, -1 when we are not inside one.
    private var creationIndent = -1

    func reset() {
        creationIndent = -1
    }

    func keepInPowerLog(_ line: LogLine) -> Bool {
        guard line.namespace == .power, line.content.hasPrefix(RewoundEntityCreationFilter.powerLinePrefix) else {
            return notACreation()
        }

        let body = line.content.dropFirst(RewoundEntityCreationFilter.powerLinePrefix.count)
        let content = body.drop(while: { $0 == " " })
        let indent = body.count - content.count

        if content.hasPrefix(RewoundEntityCreationFilter.entityCreation) {
            creationIndent = indent
            return true
        }

        // The tags of a creation are logged as its indented children.
        if creationIndent >= 0 && indent > creationIndent && content.hasPrefix(RewoundEntityCreationFilter.entityTag) {
            return true
        }

        return notACreation()
    }

    private func notACreation() -> Bool {
        creationIndent = -1
        return false
    }
}
