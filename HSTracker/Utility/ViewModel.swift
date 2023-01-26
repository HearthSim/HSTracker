//
//  ViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/10/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class ViewModel: Equatable {
    static func == (lhs: ViewModel, rhs: ViewModel) -> Bool {
        return lhs === rhs
    }
    
    private var _data = SynchronizedDictionary<String, Any>()
    
    var propertyChanged: ((_ propertyName: String?) -> Void)?
    
    func onPropertyChanged(_ propertyName: String? = nil) {
        propertyChanged?(propertyName)
    }
    
    func getProp<T>(_ defaultValue: T, _ memberName: String = #function) -> T {
        if let value = _data[memberName] as? T {
            return value
        }
        return defaultValue
    }
    
    func setProp<T: Equatable>(_ value: T, _ memberName: String = #function) {
        if let current = _data[memberName] as? T, current == value {
            return
        }
        _data[memberName] = value
        onPropertyChanged(memberName)
    }
}
