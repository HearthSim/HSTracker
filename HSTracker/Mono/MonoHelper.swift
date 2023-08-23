//
//  MonoHelper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppCenterCrashes

protocol MonoClassInitializer {
    static var _class: OpaquePointer? { get }
    static var _members: [String: OpaquePointer] { get set }

    static func initialize()
    static func initializeFields(fields: [String])
    static func initializeProperties(properties: [String])
    static func getMember(name: String) -> OpaquePointer
}

extension MonoClassInitializer {
    static func initializeFields(fields: [String]) {
        for f in fields {
            _members[f] = MonoHelper.getField(_class, f)
        }
    }
    
    static func initializeProperties(properties: [String]) {
        for p in properties {
            _members[p] = MonoHelper.getProperty(_class, p)
        }
    }

    static func getMember(name: String) -> OpaquePointer {
        if let member = _members[name] {
            return member
        }
        fatalError("Member \(name) not found")
    }
}

@propertyWrapper struct MonoHandleField<T> where T: MonoHandle {
    let field: OpaquePointer

    public static subscript<EnclosingSelf>(
      _enclosingInstance observed: EnclosingSelf,
      wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, T>,
      storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> T where EnclosingSelf: MonoHandle {
      get {
          let field = observed[keyPath: storageKeyPath].field
          
          let inst = observed.get()
          let obj = mono_field_get_value_object(MonoHelper._monoInstance, field, inst)
          return T(obj: obj)
      }
      set {
          let field = observed[keyPath: storageKeyPath].field
          let inst = observed.get()
          mono_field_set_value(inst, field, newValue.get())
      }
    }

    public var wrappedValue: T {
      get { fatalError("called wrappedValue getter") }
        //swiftlint:disable unused_setter_value
      set { fatalError("called wrappedValue setter") }
        //swiftlint:enable unused_setter_value
    }
    
    init(field: String, owner: MonoClassInitializer.Type) {
        self.field = owner.getMember(name: field)
    }
}

@propertyWrapper struct MonoPrimitiveField<T> {
    let field: OpaquePointer!

    public static subscript<EnclosingSelf>(
      _enclosingInstance observed: EnclosingSelf,
      wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, T>,
      storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> T where EnclosingSelf: MonoHandle {
      get {
          let field = observed[keyPath: storageKeyPath].field
          let inst = observed.get()
          let params = UnsafeMutablePointer<T>.allocate(capacity: 1)
          
          mono_field_get_value(inst, field, params)
          
          let res: T = params.pointee
          
          params.deallocate()
          
          return res
      }
      set {
          let field = observed[keyPath: storageKeyPath].field
          let inst = observed.get()
          
          let params = UnsafeMutablePointer<T>.allocate(capacity: 1)
          params.pointee = newValue
          mono_field_set_value(inst, field, params)
          params.deallocate()
      }
    }

    public var wrappedValue: T {
      get { fatalError("called wrappedValue getter") }
        //swiftlint:disable unused_setter_value
      set { fatalError("called wrappedValue setter") }
        //swiftlint:enable unused_setter_value
    }
    
    init(field: String, owner: MonoClassInitializer.Type) {
        self.field = owner.getMember(name: field)
    }
}

@propertyWrapper struct MonoStringField {
    let field: OpaquePointer

    public static subscript<EnclosingSelf>(
      _enclosingInstance observed: EnclosingSelf,
      wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, String>,
      storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> String where EnclosingSelf: MonoHandle {
      get {
          let field = observed[keyPath: storageKeyPath].field
          
          let inst = observed.get()
          let obj = mono_field_get_value_object(MonoHelper._monoInstance, field, inst)
          let opaque = OpaquePointer(obj)
          let str = mono_string_to_utf8(opaque)
          let cstr = String(cString: str!)
          str?.deallocate()
          return cstr
      }
      set {
          let field = observed[keyPath: storageKeyPath].field
          let inst = observed.get()
          newValue.withCString({
              let str = mono_string_new(MonoHelper._monoInstance, $0)
              let mstr = UnsafeMutableRawPointer(str)
              mono_field_set_value(inst, field, mstr)
          })
      }
    }

    public var wrappedValue: String {
      get { fatalError("called wrappedValue getter") }
        //swiftlint:disable unused_setter_value
      set { fatalError("called wrappedValue setter") }
        //swiftlint:enable unused_setter_value
    }
    
    init(field: String, owner: MonoClassInitializer.Type) {
        self.field = owner.getMember(name: field)
    }
}

@propertyWrapper struct MonoPrimitiveProperty<T> {
    let property: OpaquePointer!

    public static subscript<EnclosingSelf>(
      _enclosingInstance observed: EnclosingSelf,
      wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, T>,
      storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> T where EnclosingSelf: MonoHandle {
      get {
          let property = observed[keyPath: storageKeyPath].property
          let inst = observed.get()
          
          let temp = mono_property_get_value(property, inst, nil, nil)
          
          if let v = mono_object_unbox(temp) {
              return v.bindMemory(to: T.self, capacity: 1).pointee
          }
          fatalError("Unexpected nil found")
      }
      set {
          let property = observed[keyPath: storageKeyPath].property
          let inst = observed.get()
          
          let params = UnsafeMutablePointer<UnsafeMutablePointer<T>>.allocate(capacity: 1)
          let a = UnsafeMutablePointer<T>.allocate(capacity: 1)
          a.pointee = newValue
          params[0] = a
          params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1, {
              mono_property_set_value(property, inst, $0, nil)
          })
          a.deallocate()
          params.deallocate()
      }
    }

    public var wrappedValue: T {
      get { fatalError("called wrappedValue getter") }
        //swiftlint:disable unused_setter_value
      set { fatalError("called wrappedValue setter") }
        //swiftlint:enable unused_setter_value
    }
    
    init(property: String, owner: MonoClassInitializer.Type) {
        self.property = owner.getMember(name: property)
    }
}

@propertyWrapper struct MonoStringProperty {
    let property: OpaquePointer!

    public static subscript<EnclosingSelf>(
      _enclosingInstance observed: EnclosingSelf,
      wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, String>,
      storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> String where EnclosingSelf: MonoHandle {
      get {
          let property = observed[keyPath: storageKeyPath].property
          let inst = observed.get()
          
          let obj = mono_property_get_value(property, inst, nil, nil)
          
          let opaque = OpaquePointer(obj)
          let str = mono_string_to_utf8(opaque)
          let cstr = String(cString: str!)
          str?.deallocate()
          return cstr
      }
      set {
          let property = observed[keyPath: storageKeyPath].property
          let inst = observed.get()
          
          let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)
          newValue.withCString({
              let str = mono_string_new(MonoHelper._monoInstance, $0)
              let mstr = UnsafeMutableRawPointer(str)
              params[0] = mstr
              mono_property_set_value(property, inst, params, nil)
          })

          params.deallocate()
      }
    }

    public var wrappedValue: String {
      get { fatalError("called wrappedValue getter") }
        //swiftlint:disable unused_setter_value
      set { fatalError("called wrappedValue setter") }
        //swiftlint:enable unused_setter_value
    }
    
    init(property: String, owner: MonoClassInitializer.Type) {
        self.property = owner.getMember(name: property)
    }
}
class MonoHelper {
    static var _monoInstance: OpaquePointer? // MonoDomain
    static var _assembly: OpaquePointer? // MonoClass
    static var _image: OpaquePointer? // MonoImage

    static let monoClasses: [MonoClassInitializer.Type] = [ BrukanInvocationDeathrattles.self,
                                                            GenericDeathrattles.self,
                                                            HeroPowerDataProxy.self,
                                                            InputProxy.self,
                                                            MinionFactoryProxy.self,
                                                            MinionProxy.self,
                                                            OutputProxy.self,
                                                            QuestDataProxy.self,
                                                            ReplicatingMenace.self,
                                                            SimulatorProxy.self,
                                                            SimulationRunnerProxy.self,
                                                            CardEntityProxy.self,
                                                            BloodGemProxy.self,
                                                            SpellCardEntityProxy.self,
                                                            UnknownCardEntityProxy.self,
                                                            MinionCardEntityProxy.self,
                                                            AnomalyProxy.self,
                                                            AnomalyFactoryProxy.self]
    
    static func initialize() {
        for cl in monoClasses {
            cl.initialize()
        }
    }
    
    static func load() -> Bool {
        #if !HSTTEST
        guard let path = Bundle.main.resourceURL else {
            logger.debug("Failed to resolve resourceURL")
            return false
        }
        // this flag is needed to avoid a deadlock/hang. Haven't found a better alternative
        // without it, the Mono stack will hang during GC and our calls to wait for the
        // simulation result
        setenv("MONO_THREADS_SUSPEND", "preemptive", 1)
        // The following can help debug issues with packaging of needed libraries
        //setenv("MONO_LOG_LEVEL", "debug", 1)
        //setenv("MONO_LOG_MASK", "asm,dll", 1)

        if let files = Bundle.main.urls(forResourcesWithExtension: "dll", subdirectory: "Resources/Managed") {
            let libs = files.compactMap { x in x.path }
            let props = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: 1)
            "TRUSTED_PLATFORM_ASSEMBLIES".withCString {
                props.pointee = $0
            }
            let values = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: 1)
            libs.joined(separator: ":").withCString {
                values.pointee = $0
            }
            monovm_initialize(1, props, values)
        } else {
            logger.debug("Failed to resolve urls for managed assemblies")
            return false
        }

        if let version = mono_get_runtime_build_info() {
            let str = String(cString: version)
            logger.debug("Loading mono version \(str)")
            version.deallocate()
        }
        let mono = mono_jit_init("HSTracker")
        
        if mono != nil {
            MonoHelper._monoInstance = mono
        }
        //mono_jit_set_trace_options("BobsBuddy")
            
        MonoHelper._assembly = mono_domain_assembly_open(mono, path.path + "/Resources/Managed/BobsBuddy.dll")
        
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
        #endif
        
        return true
    }
    
    static func getMethod(_ clazz: OpaquePointer?, _ method: String, _ params: Int) -> OpaquePointer {
        var class_ = clazz
        while class_ != nil {
            let result = mono_class_get_method_from_name(class_, method, Int32(params))
            if let result = result {
                return result
            }
            class_ = mono_class_get_parent(class_)
        }
        fatalError("Method \(method) not found")
    }
    
    static func getField(_ clazz: OpaquePointer?, _ field: String) -> OpaquePointer {
        let result = mono_class_get_field_from_name(clazz, field)
        if let result = result {
            return result
        }
        fatalError("Field \(field) not found")
    }

    static func getProperty(_ clazz: OpaquePointer?, _ property: String) -> OpaquePointer {
        let result = mono_class_get_property_from_name(clazz, property)
        if let result = result {
            return result
        }
        fatalError("Property \(property) not found")
    }
    
    static func testSimulation() {
        let handle = mono_thread_attach(MonoHelper._monoInstance)
        
        initialize()
        
        let sim = SimulatorProxy()
        
        if sim.valid() {
            let test = InputProxy(simulator: sim)
            
            test.setHealths(player: 4, opponent: 4)
            
            test.setTiers(player: 3, opponent: 3)
            
            test.setOpponentHeroPower(heroPowerCardId: "TB_BaconShop_HP_061", isActivated: true, data: 0, data2: 0)
            test.setPlayerHeroPower(heroPowerCardId: "TB_BaconShop_HP_043", isActivated: false, data: 0, data2: 0)
            
            let ps = test.playerSide
            let os = test.opponentSide
            let factory = sim.minionFactory
            
            MonoHelper.addToList(list: ps, element: factory.createFromCardid(id: "UNG_073", player: true))
            MonoHelper.addToList(list: ps, element: factory.createFromCardid(id: "UNG_073", player: true))
            MonoHelper.addToList(list: ps, element: factory.createFromCardid(id: "EX1_506a", player: true))
            MonoHelper.addToList(list: ps, element: factory.createFromCardid(id: "EX1_506a", player: true))
            
            MonoHelper.addToList(list: os, element: factory.createFromCardid(id: "BG26_801", player: false))
            MonoHelper.addToList(list: os, element: factory.createFromCardid(id: "UNG_073", player: false))
            MonoHelper.addToList(list: os, element: factory.createFromCardid(id: "EX1_506", player: false))
            let murloc = factory.createFromCardid(id: "EX1_506a", player: false)
            murloc.poisonous = true
            logger.debug("Murloc poisonous property \(murloc.poisonous), name \(murloc.minionName)")
            MonoHelper.addToList(list: os, element: murloc)
            
            let playerSecrets = test.playerSecrets
            test.addSecretFromDbfid(id: Int32(Cards.any(byId: "TB_Bacon_Secrets_12")?.dbfId ?? 0), target: playerSecrets)
            logger.debug("Opponent HP \(test.opponentHeroPower.cardId)")
            //            let oppSecrets = test.getOpponentSecrets()
            //            test.addSecretFromDbfid(id: Int32(Cards.any(byId: "TB_Bacon_Secrets_02")?.dbfId ?? 0), target: oppSecrets)
            let races: [Race] = [ Race.beast, Race.mechanical, Race.dragon, Race.murloc ]
            
            test.addAvailableRaces(races: races)
            
            let str = test.unitestCopyableVersion()
            
            logger.debug(str)

            let runner = SimulationRunnerProxy()
            let obj = runner.simulateMultiThreaded(input: test, maxIterations: 1000, threadCount: 4, maxDuration: 1500)
            let c = mono_object_get_class(obj.get())
            let inst2 = obj.get()

            let mw = MonoHelper.getMethod(c, "Wait", 0)

            _ = mono_runtime_invoke(mw, inst2, nil, nil)
            
            let meth2 = MonoHelper.getMethod(c, "get_Result", 0)
            let output = mono_runtime_invoke(meth2, inst2, nil, nil)
            let top = OutputProxy(obj: output)

            let ostr = MonoHelper.toString(obj: top)
            logger.debug("testSimulation result is \(ostr)")
            
            // For testing the damage result code which is a little trickier
            //let damage = top.getResultDamage()
            //logger.debug("testSimulation damage is \(damage)")
        }
        
        mono_thread_detach(handle)
    }
    
    static func loadClass(ns: String, name: String) -> OpaquePointer {
        let result = mono_class_from_name(_image, ns, name)
        
        if let result = result {
            return result
        }
        
        fatalError("Failed to load class \(ns).\(name)")
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
    
    static func setIntMonoHandle(obj: MonoHandle, method: OpaquePointer, v1: Int32, v2: MonoHandle) {
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 2)
        let ptrs = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        ptrs[0] = v1
        params[0] = UnsafeMutableRawPointer(ptrs.advanced(by: 0))
        params[1] = UnsafeMutableRawPointer(v2.get())
        
        mono_runtime_invoke(method, obj.get(), params, nil)
        
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
    
    static func setStringBoolIntInt(obj: MonoHandle, method: OpaquePointer, v1: String, v2: Bool, v3: Int32, v4: Int32) {
        let params = UnsafeMutablePointer<OpaquePointer>.allocate(capacity: 4)
        let ptrs = UnsafeMutablePointer<Int32>.allocate(capacity: 3)
        ptrs[0] = v2 ? 1 : 0
        ptrs[1] = v3
        ptrs[2] = v4
        v1.withCString({
            params[0] = mono_string_new(MonoHelper._monoInstance, $0)
        })
        params[1] = OpaquePointer(ptrs.advanced(by: 0))
        params[2] = OpaquePointer(ptrs.advanced(by: 1))
        params[3] = OpaquePointer(ptrs.advanced(by: 2))
        
        params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 4, {
            let inst = obj.get()

            mono_runtime_invoke(method, inst, $0, nil)
        })
        
        ptrs.deallocate()
        params.deallocate()
    }

    static func setString(obj: MonoHandle, method: OpaquePointer, value: String) {
        let params = UnsafeMutablePointer<OpaquePointer>.allocate(capacity: 1)
        value.withCString({
            params[0] = mono_string_new(MonoHelper._monoInstance, $0)
        })
        
        params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1, {
            let inst = obj.get()

            mono_runtime_invoke(method, inst, $0, nil)
        })
        params.deallocate()
    }
    
    static func getString(obj: MonoHandle, method: OpaquePointer) -> String {
        let inst = obj.get()
        
        let temp = mono_runtime_invoke(method, inst, nil, nil)
        
        if temp == nil {
            return ""
        }
        
        let res = mono_object_to_string(temp, nil)
        
        let str = mono_string_to_utf8(res)
        
        let cstr = String(cString: str!)
        
        str?.deallocate()
        
        return cstr
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
    
    static func invokeStringIntInt(obj: MonoHandle, method: OpaquePointer, str: String, a: Int32, b: Int32) -> UnsafeMutablePointer<MonoObject>? {
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 3)
        str.withCString({
            params[0] = UnsafeMutableRawPointer(mono_string_new(MonoHelper._monoInstance, $0))
        })
        let ptrs = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
        ptrs[0] = a
        ptrs[1] = b
        params[1] = UnsafeMutableRawPointer(ptrs.advanced(by: 0))
        params[2] = UnsafeMutableRawPointer(ptrs.advanced(by: 1))

        let res: UnsafeMutablePointer<MonoObject>? = params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1, {
            let inst = obj.get()

            return mono_runtime_invoke(method, inst, $0, nil)
        })
        ptrs.deallocate()
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

    static func addToList(list: MonoHandle, element: MonoHandle) {
        let obj = list.get()
        let clazz = mono_object_get_class(obj)
        let method = mono_class_get_method_from_name(clazz, "Add", 1)
        
        let params = UnsafeMutablePointer<UnsafeMutablePointer<MonoObject>>.allocate(capacity: 1)

        params[0] = element.get()!
            
        _ = params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1, {
            mono_runtime_invoke(method, obj, $0, nil)
        })
        params.deallocate()
    }
}
