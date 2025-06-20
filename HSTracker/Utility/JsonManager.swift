//
//  JsonManager.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/16/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol Initializable: Codable, Decodable {
    init()
}

final class JsonManager {
    public static func load<T: Initializable>(_ url: URL) -> T {
        if !FileManager.default.fileExists(atPath: url.path) {
            return T()
        }
        do {
            let data = try Data(contentsOf: url)
            let dec = JSONDecoder()
            dec.dateDecodingStrategy = .iso8601
            let value = try dec.decode(T.self, from: data)
            return value
        } catch {
            logger.error("Error loading file of type \(T.self) from cache: \(error)")
        }
        return T()
    }
    
    public static func save<T: Codable>(_ url: URL, _ data: T) {
        do {
            let enc = JSONEncoder()
            enc.dateEncodingStrategy = .iso8601
            let json = try enc.encode(data)
            try json.write(to: url)
        } catch {
            logger.error("Error while saving \(T.self) data: \(error)")
        }
    }
}
