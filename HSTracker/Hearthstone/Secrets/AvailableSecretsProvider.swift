//
//  AvailableSecretsProvider.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/27/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol AvailableSecretsProvider {
    var byType: [String: Set<String>]? { get }
    var createdByTypeByCreator: [String: [String: Set<String>]]? { get }
}
