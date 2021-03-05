// Copyright 2021 Chip Jarred
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

// -------------------------------------
/**
 Swift-side proxy for `HostOS.cmsghdr`
 */
public struct ControlMessage
{
    @usableFromInline internal static let cmsghdrSize =
        align32(MemoryLayout<HostOS.cmsghdr>.stride)
    @usableFromInline internal let lenIndex   = 0
    @usableFromInline internal let levelIndex = 1
    @usableFromInline internal let typeIndex  = 2
    
    // -------------------------------------
    @inlinable
    public static func align<T: FixedWidthInteger>(_ value: T) -> T {
        return NIX.align32(value)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func pad() { storage.pad32() }
    
    // -------------------------------------
    /// data byte count, including hdr
    @usableFromInline internal var len: CUnsignedInt
    {
        get { getValue(at: lenIndex) }
        set { setValue(at: lenIndex, to: newValue) }
    }
    
    // -------------------------------------
    /// originating protocol
    @inlinable public var level: CInt
    {
        get { getValue(at: levelIndex) }
        set { setValue(at: levelIndex, to: newValue) }
    }

    // -------------------------------------
    /// protocol-specific type
    @inlinable public var type: CInt
    {
        get { getValue(at: typeIndex) }
        set { setValue(at: typeIndex, to: newValue) }
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal func getValue<T: FixedWidthInteger>(at index: Int) -> T
    {
        let byteIndex = MemoryLayout<T>.stride * index
        return storage.withUnsafeBytes
        {
            $0.baseAddress!.advanced(by: byteIndex)
                .bindMemory(to: T.self, capacity: 1).pointee
        }
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func setValue<T: FixedWidthInteger>(
        at index: Int,
        to value: T)
    {
        let byteIndex = MemoryLayout<T>.stride * index
        storage.withUnsafeMutableBytes
        {
            $0.baseAddress!.advanced(by: byteIndex)
                .bindMemory(to: T.self, capacity: 1).pointee = value
        }
    }

    // -------------------------------------
    public var messageData: Data {
        get { return Data(storage[Self.align(Self.cmsghdrSize)...]) }
    }
    
    // -------------------------------------
    public mutating func appendBytes<Bytes: ContiguousBytes>(of value: Bytes)
    {
        value.withUnsafeBytes {
            storage.append(contentsOf: $0)
        }
    }
    
    @usableFromInline internal var storage: Data
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal init(storage: Data)
    {
        assert(storage.count >= Self.align(Self.cmsghdrSize))
        self.storage = storage
    }

    // -------------------------------------
    @inlinable
    public init()
    {
        self.storage = Data(
            repeating: 0,
            count: Self.align(MemoryLayout<HostOS.cmsghdr>.size)
        )
        self.len = socklen_t(Self.cmsghdrSize)
    }

    // -------------------------------------
    @inlinable
    public init(messageCapacity: Int = 0)
    {
        let capacity =
            Self.align(MemoryLayout<HostOS.cmsghdr>.size) + messageCapacity
        
        self.storage = Data(
            repeating: 0,
            count: capacity
        )
        self.len = socklen_t(capacity)
    }

    // -------------------------------------
    @inlinable
    public init(level: CInt, type: CInt, messageData: Data)
    {
        self.init()
        self.storage.reserveCapacity(storage.count + messageData.count)
        self.storage.append(messageData)
        
        self.level = level
        self.type = type
        self.len = socklen_t(storage.count)
    }
}

// -------------------------------------
internal extension Data.SubSequence
{
    var cmgshdrSize: Int { MemoryLayout<HostOS.cmsghdr>.size }
    var cmgshdrStride: Int { NIX.align32(cmgshdrSize) }

    // -------------------------------------
    func nextControlMessage() -> Self?
    {
        guard let current = getControlMessageHeader() else { return nil }
        
        let newStart = startIndex + ControlMessage.align(Int(current.cmsg_len))
        
        guard newStart < endIndex else { return nil }
        
        return self[newStart...]
    }
    
    // -------------------------------------
    func getControlMessageHeader() -> HostOS.cmsghdr?
    {
        guard count >= cmgshdrSize else { return nil }
        return self.withUnsafeBytes {
            return $0.bindMemory(to: HostOS.cmsghdr.self).baseAddress!.pointee
        }
    }
}
