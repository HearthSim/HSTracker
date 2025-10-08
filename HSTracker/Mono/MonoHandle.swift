//
//  MonoHandle.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class MonoHandle {
    var _handle: UInt32
    
    init() {
        _handle = 0
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        _handle = (obj != nil) ? mono_gchandle_new(obj, 0) : 0
    }
    
    func set(obj: UnsafeMutablePointer<MonoObject>?) {
        assert(_handle == 0, "Handle should be empty")
        
        _handle = mono_gchandle_new(obj, 0)
    }
    
    func get() -> UnsafeMutablePointer<MonoObject>? {
        return mono_gchandle_get_target(_handle)
    }
    
    func valid() -> Bool {
        return _handle != 0
    }
    
    deinit {
        if _handle != 0 {
            mono_gchandle_free(_handle)
        }
    }
}
