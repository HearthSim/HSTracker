//
//  MinionFactoryProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/12/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class MinionFactoryProxy: MonoHandle, MonoClassInitializer {

    internal static var _class: OpaquePointer?
    private static var _classVT: OpaquePointer!
    
    private static var _createFromCardid: OpaquePointer!
    private static var _cardIdsWithoutPremiumImplementations: OpaquePointer!
    private static var _cardIdsWithCleave: OpaquePointer!
    private static var _cardIdsWithMegaWindfury: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        _class = MonoHelper.loadClass(ns: "BobsBuddy.Factory", name: "MinionFactory")
        
        mono_class_init(_class)
        
        _createFromCardid = MonoHelper.getMethod(MinionFactoryProxy._class, "CreateFromCardId", 2)
        
        _cardIdsWithoutPremiumImplementations = MonoHelper.getField(_class, "cardIdsWithoutPremiumImplementations")
        _cardIdsWithCleave = MonoHelper.getField(_class, "cardIDsWithCleave")
        _cardIdsWithMegaWindfury = MonoHelper.getField(_class, "cardIdsWithMegaWindfury")

        _classVT = mono_class_vtable(MonoHelper._monoInstance, mono_field_get_parent(_cardIdsWithoutPremiumImplementations))
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    func createFromCardid(id: String, player: Bool) -> MinionProxy {
        let params = UnsafeMutablePointer<OpaquePointer>.allocate(capacity: 2)
        let ptrs = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        ptrs[0] = player ? 1 : 0

        id.withCString({
            params[0] = mono_string_new(MonoHelper._monoInstance, $0)
            params[1] = OpaquePointer(ptrs.advanced(by: 0))
        })

        let res: MinionProxy = params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 2, {
            let r = mono_runtime_invoke(MinionFactoryProxy._createFromCardid, self.get(), $0, nil)
            return MinionProxy(obj: r)
        })
        ptrs.deallocate()
        params.deallocate()
        return res
    }
    
    static func getStringArrayField(field: OpaquePointer!) -> [String] {
        let value = UnsafeMutablePointer<UnsafeMutablePointer<MonoObject>>.allocate(capacity: 1)
        
        mono_field_static_get_value(MinionFactoryProxy._classVT, field, value)
        
        let obj = value.pointee
        
        let meth = mono_class_get_method_from_name(mono_object_get_class(obj), "ToArray", 0)

        let res = mono_runtime_invoke(meth, obj, nil, nil)
        
        let opaque = OpaquePointer(res)
        
        let len = mono_array_length(opaque)

        var arr: [String] = []
        
        for i in 0 ..< len {
            let addr = mono_array_addr_with_size(opaque, 8, i)
            
            addr?.withMemoryRebound(to: UnsafeMutablePointer<MonoObject>.self, capacity: 1, {
                let str = mono_string_to_utf8(OpaquePointer($0.pointee))

                let cstr = String(cString: str!)
                arr.append(cstr)
                
                str?.deallocate()
            })
        }
        value.deallocate()
        return arr
    }
    
    static func getCardIdsWithoutPremiumImplementations() -> [String] {
        return getStringArrayField(field: _cardIdsWithoutPremiumImplementations)
    }

    static func getCardIdsWithCleave() -> [String] {
        return getStringArrayField(field: _cardIdsWithCleave)
    }

    static func getCardIdsWithMegaWindfury() -> [String] {
        return getStringArrayField(field: _cardIdsWithMegaWindfury)
    }
}
