//
//  ISpellSchoolTutor.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/26/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

protocol ISpellSchoolTutor: ICardWithHighlight {
    var tutoredSpellSchools: [Int] { get }
}
