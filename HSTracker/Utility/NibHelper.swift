//
//  NibHelper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/14/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class NibHelper {
    static func loadNib(_ type: AnyClass, _ owner: Any?) {
        guard let resource = NSNib(nibNamed: String(describing: type),
                                   bundle: Bundle(for: type)) else {
            let message = "Failed to load NIB \(String(describing: type))"
            Influx.breadcrumb(eventName: "NibLoader_NsNib", message: message)
            fatalError(message)
        }
        guard resource.instantiate(withOwner: owner, topLevelObjects: nil) else {
            let message = "Failed to instantiate resouce from NIB"
            Influx.breadcrumb(eventName: "NibLoader_instantiate", message: message)
            fatalError(message)
        }
    }
    
    static func loadViewFromNib<T>(_ type: AnyClass, _ owner: Any?) -> T {
        guard let resource = NSNib(nibNamed: String(describing: type),
                                   bundle: Bundle(for: type)) else {
            let message = "Failed to load NIB \(String(describing: type))"
            Influx.breadcrumb(eventName: "NibLoader_NsNib", message: message)
            fatalError(message)
        }
        var array: NSArray? = NSArray()
        guard resource.instantiate(withOwner: owner, topLevelObjects: &array) else {
            let message = "Failed to instantiate resouce from NIB"
            Influx.breadcrumb(eventName: "NibLoader_instantiate", message: message)
            fatalError(message)
        }
        guard let res = array?.first(where: { e in
            return e as? T != nil
        }) as? T else {
            let message = "Failed to instance of type \(T.self)"
            Influx.breadcrumb(eventName: "NibLoader_filter", message: message)
            fatalError(message)

        }
        return res
    }

}
