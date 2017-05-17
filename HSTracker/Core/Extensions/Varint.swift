//
//  Varint.swift
//  BlueSteel
//
//  Created by Matt Isaacs.
//  Copyright (c) 2014 Gilt. All rights reserved.
//  https://github.com/gilt/BlueSteel/blob/master/Sources/Varint.swift
//

import Foundation

public struct Varint {
    let backing: [UInt8]

    public var count: Int {
        return backing.count
    }

    public var description: String {
            return backing.description
    }

    // This initializer should never be used directly.
    // VarintFromBytes should be used instead.
    init(fromBytes bytes: [UInt8]) {
        self.backing = bytes
    }

    public init(fromValue value: UInt) {
        self.init(fromValue: UInt64(value))
    }

    public init(fromValue value: UInt64) {
        var buffer: [UInt8] = []
        if value == 0 {
            buffer.append(0)
        } else {
            var tmp = value
            var idx: Int = 0
            while tmp > 0 {
                buffer.append(UInt8(truncate: tmp))
                if idx > 0 {
                    buffer[idx - 1] |= 0x80
                }

                // Next index
                idx += 1
                tmp >>= 7
            }
        }

        self.backing = buffer
    }

    public func toInt64() -> Int64 {
        return Int64(bitPattern: self.toUInt64())
    }

    public func toUInt64() -> UInt64 {
        var result: UInt64 = 0

        for idx: Int in 0 ..< backing.count {
            let tmp: UInt8 = backing[idx]

            result |= UInt64(tmp & 0x7F) << UInt64(7 * idx)
        }
        return result
    }

    public static func VarintFromBytes(_ bytes: [UInt8]) -> Varint? {
        var buf = [UInt8]()

        for x in bytes {
            buf.append(x)

            if (x & 0x80) == 0 {
                break
            }
        }
        if buf.count > 0 {
            return Varint(fromBytes: buf)
        }
        return nil
    }
}

extension Varint {

    public init(fromValue value: Int64) {
        self = Varint(fromValue: UInt64(value))
    }

    public init(fromValue value: Int) {
        self.init(fromValue: Int64(value))
    }
}

// MARK: - Integer extensions
extension UInt8 {

    init(truncate val: UInt) {
        self.init(val & 0xFF)
    }

    init(truncate val: UInt64) {
        self.init(val & 0xFF)
    }

    init(truncate val: UInt32) {
        self.init(val & 0xFF)
    }

    init(truncate val: UInt16) {
        self.init(val & 0xFF)
    }

}

extension UInt16 {

    init(truncate val: UInt) {
        self.init(val & 0xFFFF)
    }

    init(truncate val: UInt64) {
        self.init(val & 0xFFFF)
    }

    init(truncate val: UInt32) {
        self.init(val & 0xFFFF)
    }

    init(truncate val: UInt16) {
        self.init(val & 0xFFFF)
    }
}

// MARK: Zig Zag encoding
extension Int64 {
    public func encodeZigZag() -> UInt64 {
        let encoded: Int64 = ((self << 1) ^ (self >> 63))
        return UInt64(bitPattern:  encoded)
    }
}

extension UInt64 {
    public func decodeZigZag() -> Int64 {
        let decoded = ((self & 0x1) * UInt64.max) ^ (self >> 1)
        return Int64(bitPattern: decoded)
    }
}
