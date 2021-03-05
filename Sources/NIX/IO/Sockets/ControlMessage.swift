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
    @usableFromInline internal let cmsghdrSize =
        MemoryLayout<HostOS.cmsghdr>.stride
    @usableFromInline internal let lenIndex   = 0
    @usableFromInline internal let levelIndex = 1
    @usableFromInline internal let typeIndex  = 2
    
    // -------------------------------------
    /// data byte count, including hdr
    @usableFromInline internal var len: CUnsignedInt
    {
        get
        {
            return storage.withUnsafeBytes
            {
                return $0.baseAddress!
                    .bindMemory(to: CUnsignedInt.self, capacity: 3)[lenIndex]
            }
        }
        set
        {
            storage.withUnsafeMutableBytes
            {
                $0.baseAddress!
                    .bindMemory(to: CUnsignedInt.self, capacity: 3)[lenIndex] =
                        newValue
            }
        }
    }
    
    // -------------------------------------
    /// originating protocol
    @inlinable public var level: CInt
    {
        get
        {
            return storage.withUnsafeBytes
            {
                return $0.baseAddress!
                    .bindMemory(to: CInt.self, capacity: 3)[levelIndex]
            }
        }
        set
        {
            storage.withUnsafeMutableBytes
            {
                $0.baseAddress!
                    .bindMemory(to: CInt.self, capacity: 3)[levelIndex] =
                        newValue
            }
        }
    }

    // -------------------------------------
    /// protocol-specific type
    @inlinable public var type: CInt
    {
        get
        {
            return storage.withUnsafeBytes
            {
                return $0.baseAddress!
                    .bindMemory(to: CInt.self, capacity: 3)[typeIndex]
            }
        }
        set
        {
            storage.withUnsafeMutableBytes
            {
                $0.baseAddress!
                    .bindMemory(to: CInt.self, capacity: 3)[typeIndex] =
                        newValue
            }
        }
    }
    
    // -------------------------------------
    public var messageData: Data
    {
        get { return Data(storage[cmsghdrSize...]) }
        set
        {
            assert(storage.count >= cmsghdrSize)
            self.storage.removeLast(storage.count - cmsghdrSize)
            self.append(newValue)
        }
    }
    
    @usableFromInline internal var storage: Data
    
    // -------------------------------------
    /**
        **UNSAFE - UNSAFE - UNSAFE - UNSAFE - UNSAFE**
     
     This is really unsafe, but we need it to support functions  like `recvmsg`
     and `sendmsg`.
     
     Swift tries really hard to prevent pointers into Swift values from escaping
     closures where it can ensure that they are valid, but there are contexts
     where they are valid apart from the ones that the Swift compiler can prove,
     so we *must* ensure that these pointers don't escape such contexts.
     
     In short, we must ensure that no pointer obtained through this function
     escapes the immediate context in which its obtained.  That is to say, if
     such a pointer is passed to another function, that function must not make
     a copy and store it for later use.
     
     This is the method to use when the intention is only to read the data
     pointed to.
     
     Basically, this function takes the training wheels off... so be really sure
     you know what you're doing.  You have been warned.
     */
    @usableFromInline
    internal func cmsghdrPtr()
        -> UnsafeMutablePointer<HostOS.cmsghdr>
    {
        return storage.unsafeDataPointer()!.bindMemory(
            to: HostOS.cmsghdr.self,
            capacity: 1
        )
    }
    
    // -------------------------------------
    /**
        **UNSAFE - UNSAFE - UNSAFE - UNSAFE - UNSAFE**
     
     This is really unsafe, but we need it to support functions  like `recvmsg`
     and `sendmsg`.
     
     Swift tries really hard to prevent pointers into Swift values from escaping
     closures where it can ensure that they are valid, but there are contexts
     where they are valid apart from the ones that the Swift compiler can prove,
     so we *must* ensure that these pointers don't escape such contexts.
     
     In short, we must ensure that no pointer obtained through this function
     escapes the immediate context in which its obtained.  That is to say, if
     such a pointer is passed to another function, that function must not make
     a copy and store it for later use.
     
     This is the method to use when the intention is to alter the data pointed
     to.
     
     Basically, this function takes the training wheels off... so be really sure
     you know what you're doing.  You have been warned.
     */
    @usableFromInline
    internal mutating func mutableCmsghdrPtr()
        -> UnsafeMutablePointer<HostOS.cmsghdr>
    {
        return storage.unsafeMutableDataPointer()!.bindMemory(
            to: HostOS.cmsghdr.self,
            capacity: 1
        )
    }

    // -------------------------------------
    @inlinable public init(capacity: Int)
    {
        self.storage = Data(repeating: 0, count: cmsghdrSize + capacity)
        self.len = CUnsignedInt(cmsghdrSize + capacity)
    }

    // -------------------------------------
    @usableFromInline internal init?(
        cmsghdr controlMessage: UnsafeMutableRawPointer?,
        bytes: Int)
    {
        guard let controlMessage = controlMessage else { return nil }
        self.storage = Data(bytes: controlMessage, count: bytes)
    }

    // -------------------------------------
    @inlinable
    public init() { self.init(capacity: 0) }

    // -------------------------------------
    @inlinable
    public init(level: CInt, type: CInt, messageData: Data)
    {
        self.init(capacity: messageData.count)
        self.level = level
        self.type = type
        self.storage.append(messageData)
        self.len = CUnsignedInt(storage.count)
    }
    
    // -------------------------------------
    @inlinable
    public mutating func append(_ other: Data)
    {
        storage.append(other)
        len += CUnsignedInt(other.count)
    }
    
    // -------------------------------------
    @inlinable
    public mutating func append<S: Sequence>(_ other: S)
        where S.Element == Data.Element
    {
        storage.append(contentsOf: other)
        len = CUnsignedInt(storage.count)
    }
    
    // -------------------------------------
    @inlinable
    public mutating func append<S: Collection>(_ other: S)
        where S.Element == Data.Element
    {
        storage.reserveCapacity(storage.count + other.count)
        storage.append(contentsOf: other)
        len = CUnsignedInt(storage.count)
    }
}

// MARK:- Indexing support
// -------------------------------------
public extension ControlMessage
{
    @inlinable var startIndex: Int { storage.startIndex + cmsghdrSize }
    @inlinable var endIndex: Int { storage.endIndex }
    @inlinable var count: Int { endIndex - startIndex }
    @inlinable var indices: Range<Int> { startIndex..<endIndex }

    // -------------------------------------
    @inlinable
    subscript(index: Int) -> UInt8
    {
        get
        {
            assert(
                indices.contains(index),
                "Index out of bounds: \(index) not in "
                + "\(startIndex)..<\(endIndex)"
            )
            return self.storage[index + cmsghdrSize]
        }
        set
        {
            assert(
                indices.contains(index),
                "Index out of bounds: \(index) not in "
                + "\(startIndex)..<\(endIndex)"
            )
            self.storage[index + cmsghdrSize] = newValue
        }
    }

    // -------------------------------------
    @inlinable
    subscript(range: Range<Int>) -> Data.SubSequence
    {
        get
        {
            assert(range.lowerBound >= startIndex)
            assert(range.upperBound <= endIndex)
            return self.storage[range]
        }
    }

    // -------------------------------------
    @inlinable
    subscript(range: ClosedRange<Int>) -> Data.SubSequence
    {
        get
        {
            assert(range.lowerBound >= startIndex)
            assert(range.upperBound < endIndex)
            return self.storage[range]
        }
    }

    // -------------------------------------
    @inlinable
    subscript(range: PartialRangeFrom<Int>) -> Data.SubSequence {
        return self[range.lowerBound..<endIndex]
    }

    // -------------------------------------
    @inlinable
    subscript(range: PartialRangeUpTo<Int>) -> Data.SubSequence {
        return self[startIndex..<range.upperBound]
    }

    // -------------------------------------
    @inlinable
    subscript(range: PartialRangeThrough<Int>) -> Data.SubSequence {
        return self[startIndex...range.upperBound]
    }

    // -------------------------------------
    @inlinable
    subscript(range: UnboundedRange) -> Data.SubSequence {
        return self[indices]
    }
}

// -------------------------------------
internal extension Data.SubSequence
{
    var cmgshdrSize: Int { MemoryLayout<HostOS.cmsghdr>.size }
    var cmgshdrStride: Int { MemoryLayout<HostOS.cmsghdr>.stride }

    // -------------------------------------
    func nextControlMessage() -> Self?
    {
        guard let current = getControlMessageHeader() else { return nil }
        
        let newStart = align_(startIndex + Int(current.cmsg_len))
        
        guard newStart <= endIndex else { return nil }
        
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
