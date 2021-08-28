//
//  MonoHelper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class MonoHelper {
    static var _monoInstance: OpaquePointer? // MonoDomain
    static var _assembly: OpaquePointer? // MonoClass
    static var _image: OpaquePointer? // MonoImage

    static func load() -> Bool {
        guard let path = Bundle.main.resourcePath else {
            logger.debug("Failed to resolve resourcePath")
            return false
        }
        // this flag is needed to avoid a deadlock/hang. Haven't found a better alternative
        // without it, the Mono stack will hang during GC and our calls to wait for the
        // simulation result
        setenv("MONO_THREADS_SUSPEND", "preemptive", 1)
        // The following can help debug issues with packaging of needed libraries
        //setenv("MONO_LOG_LEVEL", "debug", 1)
        //setenv("MONO_LOG_MASK", "asm,dll", 1)

        let managedDir = path + "/Resources/Managed"
        if let version = mono_get_runtime_build_info() {
            let str = String(cString: version)
            logger.debug("Loading mono version \(str)")
            version.deallocate()
        }
        mono_config_parse(managedDir + "/etc/mono/config")
        mono_set_dirs(managedDir, managedDir + "/etc")
        //mono_config_parse(nil)

        let mono = mono_jit_init("HSTracker")
        
        if mono != nil {
            MonoHelper._monoInstance = mono
        }
        mono_domain_set_config(mono, path + "/Resources/Managed", "HSTracker.config")
        //mono_jit_set_trace_options("BobsBuddy")
            
        MonoHelper._assembly = mono_domain_assembly_open(mono, path + "/Resources/Managed/BobsBuddy.dll")
        
        if let ass = MonoHelper._assembly {
            _assembly = ass
            
            _image = mono_assembly_get_image(ass)
            
            let aname = mono_assembly_get_name(ass)
            let version = UnsafeMutablePointer<UInt16>.allocate(capacity: 3)
            let major = mono_assembly_name_get_version(aname, version.advanced(by: 0), version.advanced(by: 1), version.advanced(by: 2))
            logger.info("Loaded BobsBuddy version \(major).\(version[0]).\(version[1]).\(version[2])")
            version.deallocate()
            
        } else {
            logger.error("Failed to load BobsBuddy")
            return false
        }
        
        return true
    }
    
    static func testSimulation() {
        let handle = mono_thread_attach(MonoHelper._monoInstance)
        
        let sim = SimulatorProxy()
        
        if sim.valid() {
            let test = TestInputProxy(simulator: sim)
            
            test.setHealths(player: 4, opponent: 4)
            
            test.setTiers(player: 3, opponent: 3)
            
            test.setPowerID(player: "TB_BaconShop_HP_043", opponent: "TB_BaconShop_HP_061")
            test.setHeroPower(player: false, opponent: false)

            _ = test.addMinionToPlayerSide(minion: "UNG_073")
            _ = test.addMinionToPlayerSide(minion: "UNG_073")
            _ = test.addMinionToPlayerSide(minion: "EX1_506a")
            _ = test.addMinionToPlayerSide(minion: "EX1_506a")

            _ = test.addMinionToOpponentSide(minion: "UNG_073")
            _ = test.addMinionToOpponentSide(minion: "EX1_506")
            let murloc = test.addMinionToOpponentSide(minion: "EX1_506a")
            murloc.setPoisonous(poisonous: true)
            _ = test.addMinionToOpponentSide(minion: "EX1_506a")

            let races: [Race] = [ Race.beast, Race.mechanical, Race.dragon, Race.murloc ]
            
            test.addAvailableRaces(races: races)
            
            let runner = SimulationRunnerProxy()
            let obj = runner.simulateMultiThreaded(input: test, maxIterations: 1000, threadCount: 4, maxDuration: 1500)
            let c = mono_object_get_class(obj.get())
            let inst2 = obj.get()

            let mw = mono_class_get_method_from_name(mono_class_get_parent(c), "Wait", 0)

            _ = mono_runtime_invoke(mw, inst2, nil, nil)
            
            let meth2 = mono_class_get_method_from_name(c, "get_Result", 0)
            let output = mono_runtime_invoke(meth2, inst2, nil, nil)
            let top = TestOutputProxy(obj: output)

            let ostr = MonoHelper.toString(obj: top)
            logger.debug("testSimulation result is \(ostr)")
            
            // For testing the damage result code which is a little trickier
            //let damage = top.getResultDamage()
            //logger.debug("testSimulation damage is \(damage)")
        }
        
        mono_thread_detach(handle)
    }
    
    static func loadClass(ns: String, name: String) -> OpaquePointer? {
        let result = mono_class_from_name(_image, ns, name)
        
        return result
    }
    
    static func objectNew(clazz: OpaquePointer) -> UnsafeMutablePointer<MonoObject>? {
        let result = mono_object_new(MonoHelper._monoInstance, clazz)
        
        return result
    }
    
    static func getField(obj: MonoHandle, field: OpaquePointer!) -> MonoHandle {
        let inst = obj.get()
        
        let r = mono_field_get_value_object(MonoHelper._monoInstance, field, inst)
        
        return MonoHandle(obj: r)
    }
    
    static func getIntField(inst: UnsafeMutablePointer<MonoObject>?, field: OpaquePointer!) -> Int32 {
        let params = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        
        mono_field_get_value(inst, field, params)
        
        let res: Int32 = params.pointee
        
        params.deallocate()
        
        return res
    }

    static func getIntField(obj: MonoHandle, field: OpaquePointer!) -> Int32 {
        let inst = obj.get()
        
        return getIntField(inst: inst, field: field)
    }

    static func setIntField(obj: MonoHandle, field: OpaquePointer!, value: Int32) {
        let inst = obj.get()
        
        let params = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        params.pointee = value
        mono_field_set_value(inst, field, params)
        params.deallocate()
    }
    
    static func setBoolField(obj: MonoHandle, field: OpaquePointer!, value: Bool) {
        let inst = obj.get()
        
        let params = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        params.pointee = value ? 1 : 0
        mono_field_set_value(inst, field, params)
        params.deallocate()
    }
    
    static func getFloatField(obj: MonoHandle, field: OpaquePointer!) -> Float {
        let inst = obj.get()
        
        let params = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        
        mono_field_get_value(inst, field, params)
        
        let res: Float = params.pointee
        
        params.deallocate()
        
        return res
    }
    
    static func getStringField(obj: MonoHandle, field: OpaquePointer) -> String {
        let inst = obj.get()
        
        let r = mono_field_get_value_object(MonoHelper._monoInstance, field, inst)
        
        if r == nil {
             return ""
        }
        
        let opaque = OpaquePointer(r)
        let str = mono_string_to_utf8(opaque)
         
        let cstr = String(cString: str!)
        
        str?.deallocate()
        
        return cstr
    }
    
    static func getBool(obj: MonoHandle, method: OpaquePointer!) -> Bool {
        let inst = obj.get()

        let temp = mono_runtime_invoke(method, inst, nil, nil)
        let r = mono_object_unbox(temp)
        return (r?.bindMemory(to: Int32.self, capacity: 1)[0] ?? 0) != 0
    }

    static func setBool(obj: MonoHandle, method: OpaquePointer!, value: Bool) {
        let params = UnsafeMutablePointer<UnsafeMutablePointer<Int32>>.allocate(capacity: 1)
        let a = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        a.pointee = value ? 1 : 0
        params[0] = a
        
        params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1, {
            let inst = obj.get()

            mono_runtime_invoke(method, inst, $0, nil)
        })
        a.deallocate()
        params.deallocate()
    }

    static func setInt(obj: MonoHandle, method: OpaquePointer!, value: Int32) {
        let params = UnsafeMutablePointer<UnsafeMutablePointer<Int32>>.allocate(capacity: 1)
        let a = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        a.pointee = value
        params[0] = a
        
        params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1, {
            let inst = obj.get()

            mono_runtime_invoke(method, inst, $0, nil)
        })
        a.deallocate()
        params.deallocate()
    }
    
    static func getInt(obj: MonoHandle, method: OpaquePointer!) -> Int32 {
        let inst = obj.get()

        let temp = mono_runtime_invoke(method, inst, nil, nil)
        let r = mono_object_unbox(temp)
        return r?.bindMemory(to: Int32.self, capacity: 1)[0] ?? 0
    }
    
    static func setIntInt(obj: MonoHandle, method: OpaquePointer, v1: Int32, v2: Int32) {
        let params = UnsafeMutablePointer<UnsafeMutablePointer<Int32>>.allocate(capacity: 2)
        let ptrs = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
        ptrs[0] = v1
        ptrs[1] = v2
        params[0] = ptrs.advanced(by: 0)
        params[1] = ptrs.advanced(by: 1)
        
        params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 2, {
            let inst = obj.get()

            mono_runtime_invoke(method, inst, $0, nil)
        })
        
        ptrs.deallocate()
        params.deallocate()
    }
    
    static func setBoolBool(obj: MonoHandle, method: OpaquePointer, v1: Bool, v2: Bool) {
        let params = UnsafeMutablePointer<UnsafeMutablePointer<Int32>>.allocate(capacity: 2)
        let ptrs = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
        ptrs[0] = v1 ? 1 : 0
        ptrs[1] = v2 ? 1 : 0
        params[0] = ptrs.advanced(by: 0)
        params[1] = ptrs.advanced(by: 1)

        params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 2, {
            let inst = obj.get()

            mono_runtime_invoke(method, inst, $0, nil)
        })
        ptrs.deallocate()
        params.deallocate()
    }
    
    static func setStringString(obj: MonoHandle, method: OpaquePointer, v1: String, v2: String) {
        let params = UnsafeMutablePointer<OpaquePointer>.allocate(capacity: 2)
        v1.withCString({
            params[0] = mono_string_new(MonoHelper._monoInstance, $0)
        })

        v2.withCString({
            params[1] = mono_string_new(MonoHelper._monoInstance, $0)
        })
        
        params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 2, {
            let inst = obj.get()

            mono_runtime_invoke(method, inst, $0, nil)
        })
        params.deallocate()
    }

    static func invokeString(obj: MonoHandle, method: OpaquePointer, str: String) -> UnsafeMutablePointer<MonoObject>? {
        let params = UnsafeMutablePointer<OpaquePointer>.allocate(capacity: 1)
        str.withCString({
            params[0] = mono_string_new(MonoHelper._monoInstance, $0)
        })
        let res: UnsafeMutablePointer<MonoObject>? = params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1, {
            let inst = obj.get()

            return mono_runtime_invoke(method, inst, $0, nil)
        })
        params.deallocate()
        return res
    }
    
    static func invoke(obj: MonoHandle, method: OpaquePointer) -> UnsafeMutablePointer<MonoObject>? {
        return mono_runtime_invoke(method, obj.get(), nil, nil)
    }

    static func listCount(obj: MonoHandle) -> Int32 {
        let inst = obj.get()
        
        let cl = mono_object_get_class(inst)
        
        let meth = mono_class_get_method_from_name(cl, "get_Count", 0)
        
        return getInt(obj: obj, method: meth)
    }
    
    static func toString(obj: MonoHandle) -> String {
        let res = mono_object_to_string(obj.get(), nil)
        
        if res == nil {
            return ""
        }
        
        let str = mono_string_to_utf8(res)
        
        let cstr = String(cString: str!)
        
        str?.deallocate()
        
        return cstr
    }
}
