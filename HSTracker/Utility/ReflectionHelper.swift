//
//  ReflectionHelper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation
import MachO

class ReflectionHelper {
    // RelatedCardsSystem/DiscoverPoolCard.swift and every RelatedCardsSystem/Cards/Pools
    // class (e.g. SpellPool, ClassOrNeutralCost3MinionPool) are abstract pool-definition
    // base classes, never meant to be instantiated as a "card" on their own - only their
    // own further (leaf card) subclasses are. HDT's C# reflection excludes these
    // automatically via `!t.IsAbstract`; Swift has no such runtime flag, so they're
    // named here instead, the same way ResurrectionCard is excluded below for a
    // different reason. A few (FireSpellPool, MageSecretPool, ShadowSpellPool) also
    // conform to ICardGenerator and need excluding from that sweep too.
    static let abstractPoolBaseClassNames: Set<String> = [
        "DiscoverPoolCard", "FromThePastPoolCard",
        "RelativeCostPoolCard", "StateValuePoolCard", "AnimalCompanionUpgradeCard",
        "Attack468BeastMinionPool", "BeastMinionPool",
        "ClassOrNeutralBattlecryMinionPool", "ClassOrNeutralBeastMinionPool", "ClassOrNeutralCardPool",
        "ClassOrNeutralChooseOneCardPool", "ClassOrNeutralCost1CardPool", "ClassOrNeutralCost1MinionPool",
        "ClassOrNeutralCost2CardPool", "ClassOrNeutralCost3CardPool", "ClassOrNeutralCost3MinionPool",
        "ClassOrNeutralCost4CardPool", "ClassOrNeutralCost5CardPool", "ClassOrNeutralCost5MinionPool",
        "ClassOrNeutralCost6MinionPool", "ClassOrNeutralCost8MinionPool", "ClassOrNeutralCostAtLeast5MinionPool",
        "ClassOrNeutralCostAtLeast5SpellPool", "ClassOrNeutralCostAtLeast8MinionPool", "ClassOrNeutralCostAtMost3SpellPool",
        "ClassOrNeutralDeathrattleCardPool", "ClassOrNeutralDeathrattleMinionPool", "ClassOrNeutralDemonMinionPool",
        "ClassOrNeutralDragonMinionPool", "ClassOrNeutralElementalMinionPool", "ClassOrNeutralFelSpellPool",
        "ClassOrNeutralLegendaryMinionPool", "ClassOrNeutralMechMinionPool", "ClassOrNeutralNagaMinionPool",
        "ClassOrNeutralNatureSpellPool", "ClassOrNeutralPirateMinionPool", "ClassOrNeutralSecretPool",
        "ClassOrNeutralSpellPool", "ClassOrNeutralStealthMinionPool", "ClassOrNeutralTauntMinionPool",
        "ClassOrNeutralUndeadMinionPool", "ClassOrNeutralWeaponPool",
        "ComboCardPool",
        "Cost1MinionPool", "Cost2MinionPool", "Cost3BeastMinionPool", "Cost3MinionPool", "Cost4MinionPool",
        "Cost5MinionPool", "Cost6MinionPool", "Cost7MinionPool", "Cost8MinionPool", "CostAtLeast5SpellPool",
        "DeathrattleMinionPool", "DemonHunterSpellPool", "DemonMinionPool", "DragonMinionPool",
        "DruidCardPool", "DruidSpellPool",
        "ElementalMinionPool",
        "FelSpellPool", "FireSpellPool", "FrostRuneCardPool", "FrostSpellPool",
        "HolySpellPool",
        "LegendaryMinionPool",
        "MageMinionPool", "MageSecretPool", "MageSpellPool", "MechMinionPool", "MinionPool", "MurlocMinionPool",
        "NatureSpellPool",
        "OffClassCardPool", "OffClassLegendaryMinionPool", "OffClassSecretPool", "OffClassSpellPool",
        "OutcastCardPool",
        "PaladinCardPool", "PlayerClassCost1SpellPool", "PlayerClassSpellPool", "PriestSpellPool",
        "RewindCardPool",
        "ShadowSpellPool", "ShamanSpellPool", "SpellPool",
        "TauntMinionPool",
        "UndeadMinionPool",
        "WeaponPool"
    ]

    private static var cacheMonoClassList = [MonoClassInitializer.Type]()
    private static var cacheActiveEffectClassList = [EntityBasedEffect.Type]()
    private static var cacheCounterClassList = [BaseCounter.Type]()
    private static var cacheRelatedClassList = [ICardWithRelatedCards.Type]()
    private static var cacheHighlightClassList = [ICardWithHighlight.Type]()
    private static var cacheSpellSchoolTutorClassList = [ISpellSchoolTutor.Type]()
    private static var cacheCardGeneratorClassList = [ICardGenerator.Type]()

    static func initialize() {
        let start = Date()
        let metadata = ModuleMetadata()

        var monoClasses = [MonoClassInitializer.Type]()
        var activeEffectClasses = [EntityBasedEffect.Type]()
        var counterClasses = [BaseCounter.Type]()
        var relatedClasses = [ICardWithRelatedCards.Type]()
        var highlightClasses = [ICardWithHighlight.Type]()
        var spellSchoolTutorClasses = [ISpellSchoolTutor.Type]()
        var cardGeneratorClasses = [ICardGenerator.Type]()

        for entry in metadata.classes {
            let cl: AnyClass = entry.type
            let isAbstractPoolBase = abstractPoolBaseClassNames.contains(entry.name)
            if let mcl = metadata.conformance(of: cl, to: "MonoClassInitializer", as: MonoClassInitializer.Type.self) {
                monoClasses.append(mcl)
            } else if let aecl = cl as? EntityBasedEffect.Type {
                activeEffectClasses.append(aecl)
            } else if let dccl = cl as? BaseCounter.Type, cl != BaseCounter.self && cl != StatsCounter.self && cl != NumericCounter.self {
                counterClasses.append(dccl)
            } else if let rccl = metadata.conformance(of: cl, to: "ICardWithRelatedCards", as: ICardWithRelatedCards.Type.self),
                      cl != ResurrectionCard.self, !isAbstractPoolBase {
                relatedClasses.append(rccl)
            } else if let hccl = metadata.conformance(of: cl, to: "ICardWithHighlight", as: ICardWithHighlight.Type.self) {
                highlightClasses.append(hccl)
            }
            if let sstcl = metadata.conformance(of: cl, to: "ISpellSchoolTutor", as: ISpellSchoolTutor.Type.self) {
                spellSchoolTutorClasses.append(sstcl)
            }
            if let cgcl = metadata.conformance(of: cl, to: "ICardGenerator", as: ICardGenerator.Type.self), !isAbstractPoolBase {
                cardGeneratorClasses.append(cgcl)
            }
        }

        cacheMonoClassList = monoClasses
        cacheActiveEffectClassList = activeEffectClasses
        cacheCounterClassList = counterClasses
        cacheRelatedClassList = relatedClasses
        cacheHighlightClassList = highlightClasses
        cacheSpellSchoolTutorClassList = spellSchoolTutorClasses
        cacheCardGeneratorClassList = cardGeneratorClasses

        logger.info("Found \(metadata.classes.count) classes in \(String(format: "%.3f", Date().timeIntervalSince(start)))s")
    }
    
    static func getMonoClasses() -> [MonoClassInitializer.Type] {
        return cacheMonoClassList
    }
    
    static func getActiveEffectClasses() -> [EntityBasedEffect.Type] {
        return cacheActiveEffectClassList
    }
    
    static func getCounterClasses() -> [BaseCounter.Type] {
        return cacheCounterClassList
    }
    
    static func getRelatedClases() -> [ICardWithRelatedCards.Type] {
        return cacheRelatedClassList
    }
    
    static func getHighlightClasses() -> [ICardWithHighlight.Type] {
        return cacheHighlightClassList
    }
    
    static func getSpellSchoolTutorClasses() -> [ISpellSchoolTutor.Type] {
        return cacheSpellSchoolTutorClassList
    }
    
    static func getCardGeneratorClasses() -> [ICardGenerator.Type] {
        return cacheCardGeneratorClassList
    }
}

// Reads the module's classes and protocol conformances straight from its own Swift metadata
// sections, instead of listing every Objective-C class in the process with objc_copyClassList
// and casting each HSTracker one with `as? SomeProtocol.Type`. Each of those casts is a
// runtime conformance lookup, some 12,000 of them, and when Xcode launches the app each
// lookup falls back to scanning every conformance record of every loaded image: the startup
// queue sat on this for 5-7 seconds, holding the splash screen, against 0.2s otherwise.
//
// Only what the casts above need is read: top-level, non-generic classes of this module, which
// are exactly the ones whose Objective-C name starts with "HSTracker.", and conformances to
// this module's own protocols. The layouts are Swift's stable ABI (swift/ABI/Metadata.h).
private struct ModuleMetadata {
    private static let moduleName = "HSTracker"

    // A conformance whose witness table the runtime has to build, rather than one emitted
    // whole by the compiler, is left to a regular cast.
    private enum Witness {
        case table(UnsafeRawPointer)
        case runtime
    }

    // The module's classes in declaration order, keyed by their name within the module.
    private(set) var classes = [(name: String, type: AnyClass)]()
    // Protocol name -> conforming class -> witness table.
    private var conformances = [String: [ObjectIdentifier: Witness]]()

    init() {
        guard let header = ModuleMetadata.imageHeader() else {
            logger.error("Could not find the image holding the Swift metadata")
            return
        }

        var classByDescriptor = [UnsafeRawPointer: AnyClass]()
        for record in ModuleMetadata.section("__swift5_types", in: header) {
            // A TypeMetadataRecord: a relative pointer whose low two bits say whether it points
            // at the descriptor or at a pointer to it.
            let offset = record.load(as: Int32.self)
            let target = record + Int(offset & ~3)
            let descriptor = offset & 3 == 1 ? target.load(as: UnsafeRawPointer.self) : target

            let flags = descriptor.load(as: UInt32.self)
            let isClass = flags & 0x1F == 16
            let isGeneric = flags & 0x80 != 0
            guard isClass, !isGeneric, ModuleMetadata.isModuleContext(ModuleMetadata.parent(of: descriptor)) else {
                continue
            }
            let name = ModuleMetadata.name(of: descriptor)
            guard let cl = objc_getClass("\(ModuleMetadata.moduleName).\(name)") as? AnyClass else {
                continue
            }
            classes.append((name, cl))
            classByDescriptor[descriptor] = cl
        }

        for record in ModuleMetadata.section("__swift5_proto", in: header) {
            // A ProtocolConformanceRecord points at a ProtocolConformanceDescriptor:
            // protocol, type reference, witness table pattern, flags.
            let conformance = ModuleMetadata.relative(record)
            let proto = ModuleMetadata.indirectable(conformance)
            guard proto.load(as: UInt32.self) & 0x1F == 3,
                  ModuleMetadata.isModuleContext(ModuleMetadata.parent(of: proto)) else {
                continue
            }

            let flags = (conformance + 12).load(as: UInt32.self)
            let typeReference = conformance + 4
            let descriptor: UnsafeRawPointer
            switch (flags >> 3) & 0x7 {
            case 0:
                descriptor = ModuleMetadata.relative(typeReference)
            case 1:
                descriptor = ModuleMetadata.relative(typeReference).load(as: UnsafeRawPointer.self)
            default:
                continue
            }
            guard let cl = classByDescriptor[descriptor] else {
                continue
            }

            let hasConditionalRequirements = (flags >> 8) & 0xFF != 0
            let hasResilientWitnesses = flags & (1 << 16) != 0
            let hasGenericWitnessTable = flags & (1 << 17) != 0
            let witness: Witness = hasConditionalRequirements || hasResilientWitnesses || hasGenericWitnessTable
                ? .runtime
                : .table(ModuleMetadata.relative(conformance + 8))
            conformances[ModuleMetadata.name(of: proto), default: [:]][ObjectIdentifier(cl)] = witness
        }
    }

    // What `cl as? T` gives for T the existential metatype of the protocol named `protocolName`,
    // which must be this module's. A class inherits its superclasses' conformances, with their
    // witness tables.
    func conformance<T>(of cl: AnyClass, to protocolName: String, as type: T.Type) -> T? {
        guard let conforming = conformances[protocolName] else {
            return nil
        }
        var current: AnyClass? = cl
        while let candidate = current {
            switch conforming[ObjectIdentifier(candidate)] {
            case .table(let table):
                // An existential metatype is the type's metadata followed by its witness table,
                // and a Swift class's metadata is its class object.
                assert(MemoryLayout<T>.size == 2 * MemoryLayout<UnsafeRawPointer>.size)
                let metadata = unsafeBitCast(cl, to: UnsafeRawPointer.self)
                return unsafeBitCast((metadata, table), to: T.self)
            case .runtime:
                return (cl as Any) as? T
            case nil:
                current = class_getSuperclass(candidate)
            }
        }
        return nil
    }

    // The image this code lives in: the executable, or HSTracker.debug.dylib in a debug build.
    private static func imageHeader() -> UnsafePointer<mach_header_64>? {
        var info = Dl_info()
        let address = unsafeBitCast(ReflectionHelper.self as AnyClass, to: UnsafeRawPointer.self)
        guard dladdr(address, &info) != 0, let base = info.dli_fbase else {
            return nil
        }
        return UnsafePointer(base.assumingMemoryBound(to: mach_header_64.self))
    }

    // The addresses of a section's 32-bit relative pointer records.
    private static func section(_ name: String, in header: UnsafePointer<mach_header_64>) -> [UnsafeRawPointer] {
        var size: UInt = 0
        guard let data = getsectiondata(header, "__TEXT", name, &size) else {
            return []
        }
        let start = UnsafeRawPointer(data)
        return (0..<Int(size) / 4).map { start + $0 * 4 }
    }

    private static func relative(_ field: UnsafeRawPointer) -> UnsafeRawPointer {
        return field + Int(field.load(as: Int32.self))
    }

    // A relative pointer whose low bit says the target is a pointer to the real one.
    private static func indirectable(_ field: UnsafeRawPointer) -> UnsafeRawPointer {
        let offset = field.load(as: Int32.self)
        let target = field + Int(offset & ~1)
        return offset & 1 != 0 ? target.load(as: UnsafeRawPointer.self) : target
    }

    // Every context descriptor starts with flags, its parent and, for the kinds read here,
    // its name.
    private static func parent(of descriptor: UnsafeRawPointer) -> UnsafeRawPointer? {
        guard (descriptor + 4).load(as: Int32.self) != 0 else {
            return nil
        }
        return indirectable(descriptor + 4)
    }

    private static func name(of descriptor: UnsafeRawPointer) -> String {
        return String(cString: relative(descriptor + 8).assumingMemoryBound(to: CChar.self))
    }

    private static func isModuleContext(_ descriptor: UnsafeRawPointer?) -> Bool {
        guard let descriptor, descriptor.load(as: UInt32.self) & 0x1F == 0 else {
            return false
        }
        return name(of: descriptor) == moduleName
    }
}
