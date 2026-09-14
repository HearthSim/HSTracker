//
//  MonoList.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// A typed, read-only view over a C# `List<T>` reached through a `MonoHandle`.
///
/// `MonoHelper.listCount` and `MonoHelper.listItem` look the backing class, `get_Count` and the
/// `Item` indexer up in Mono metadata on every call, so an index loop pays those lookups once per
/// element. `MonoList` resolves them once. It also vends elements as the proxy type the caller
/// asked for, instead of a bare `MonoHandle` that the caller has to re-wrap — re-wrapping allocates
/// (and then immediately frees) a second GC handle for every element visited.
///
/// Because it is a `RandomAccessCollection`, the usual `for`/`first(where:)`/`contains(where:)`
/// spellings work, and `lazy` keeps a search from materializing proxies past the match.
///
/// `count` is read once, when the view is created; the view is a snapshot and must not be used
/// across a mutation of the underlying list. A handle whose object is null reads as empty rather
/// than trapping.
struct MonoList<T: MonoHandle>: RandomAccessCollection {
    private let list: MonoHandle
    private let itemProperty: OpaquePointer?

    let endIndex: Int

    var startIndex: Int { 0 }

    init(_ list: MonoHandle) {
        self.list = list

        guard let inst = list.get() else {
            itemProperty = nil
            endIndex = 0
            return
        }
        let clazz = mono_object_get_class(inst)
        itemProperty = mono_class_get_property_from_name(clazz, "Item")
        endIndex = Int(MonoHelper.getInt(obj: list, method: mono_class_get_method_from_name(clazz, "get_Count", 0)))
    }

    subscript(position: Int) -> T {
        precondition(position >= 0 && position < endIndex, "MonoList index out of range")

        var index = Int32(position)
        let obj: UnsafeMutablePointer<MonoObject>? = withUnsafeMutablePointer(to: &index) { indexPtr in
            var params: [UnsafeMutableRawPointer?] = [UnsafeMutableRawPointer(indexPtr)]
            return params.withUnsafeMutableBufferPointer { buffer in
                mono_property_get_value(itemProperty, list.get(), buffer.baseAddress, nil)
            }
        }
        return T(obj: obj)
    }
}
