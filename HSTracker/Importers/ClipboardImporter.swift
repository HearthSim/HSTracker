//
//  ClipboardImporter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/6/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class ClipboardImporter {
    static func clipboardImport() -> DeckSerializer.SerializedDeck? {
        if let string = NSPasteboard.general.string(forType: .string) {
            return DeckSerializer.deserialize(input: string)
        }
        return nil
    }
}
