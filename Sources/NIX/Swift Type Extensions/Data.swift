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

public extension Data
{
    // -------------------------------------
    /**
     Add padding to the receiving Data instance so that its `count` is 16-bit
     aligned.

     - Parameter padValue: 8-bit value to use for padding bytes.
     */
    @inlinable
    mutating func pad16(padValue: UInt8 = 0) {
        padEnd(padValue: padValue, toAlignWith: UInt16.self)
    }
    
    // -------------------------------------
    /**
     Add padding to the receiving Data instance so that its `count` is 32-bit
     aligned.

     - Parameter padValue: 8-bit value to use for padding bytes.
     */
    @inlinable
    mutating func pad32(padValue: UInt8 = 0) {
        padEnd(padValue: padValue, toAlignWith: UInt32.self)
    }

    // -------------------------------------
    /**
     Add padding to the receiving Data instance so that its `count` is 64-bit
     aligned.
     
     - Parameter padValue: 8-bit value to use for padding bytes.
     */
    @inlinable
    mutating func pad64(padValue: UInt8 = 0) {
        padEnd(padValue: padValue, toAlignWith: UInt64.self)
    }
    
    // -------------------------------------
    /**
     Add padding to the receiving Data instance so that its `count` is evenly
     divisible by the size of the specified `FixedWidthInteger` type
     
     - Parameter padValue: 8-bit value to use for padding bytes.
     */
    @usableFromInline @inline(__always)
    internal mutating func padEnd<T: FixedWidthInteger>(
        padValue: UInt8,
        toAlignWith type: T.Type)
    {
        let paddingCount = self.count % MemoryLayout<T>.size
        var i = 0
        while i < paddingCount
        {
            append(padValue)
            i += 1
        }
    }
    
    // -------------------------------------
    /**
     Append the bytes of `value` to the receiving `Data` instance
     
     - Parameter value: Any value conforming to `ContiguousBytes` whose bytes
        are to be appended.
     */
    @inlinable
    mutating func appendBytes<T:ContiguousBytes>(of value: T)
    {
        value.withUnsafeBytes {
            self.append(contentsOf: $0)
        }
    }
    
    // -------------------------------------
    /**
        **UNSAFE - UNSAFE - UNSAFE - UNSAFE - UNSAFE**
     
     This is really unsafe, but we need it to support functions that use an
     array of `iovec` like `readv` and `writev`.
     
     Swift tries really hard to prevent pointers into Swift values from escaping
     closures where it can ensure that they are valid, but there are contexts
     where they are valid apart from the ones that the Swift compiler can prove,
     so we *must* ensure that these pointers don't escape such contexts.
     
     Do not use this function when you intend to alter pointed to data (ie.
     don't use it for functions like `readv` that will write data to it).  Use
     `mutableIOVec` for that instead.
     
     Basically, this function takes the training wheels off... so be really sure
     you know what you're doing.  You have been warned.
     */
    internal func iovec() -> HostOS.iovec {
        return HostOS.iovec(iov_base: unsafeDataPointer(), iov_len: count)
    }
    
    // -------------------------------------
    /**
        **UNSAFE - UNSAFE - UNSAFE - UNSAFE - UNSAFE**
     
     This is really unsafe, but we need it to support functions that use an
     array of `iovec` like `readv` and `writev`.
     
     Swift tries really hard to prevent pointers into Swift values from escaping
     closures where it can ensure that they are valid, but there are contexts
     where they are valid apart from the ones that the Swift compiler can prove,
     so we *must* ensure that these pointers don't escape such contexts.
     
     Use this function when you are planning to alter the contents of this
    `Data` through the pointer.  Otherwise use the `iovec()` method instead.
     
     Basically, this function takes the training wheels off... so be really sure
     you know what you're doing.  You have been warned.
     */
    internal mutating func mutableIOVec() -> HostOS.iovec
    {
        return HostOS.iovec(
            iov_base: unsafeMutableDataPointer(),
            iov_len: count
        )
    }
    
    // -------------------------------------
    /**
        **UNSAFE - UNSAFE - UNSAFE - UNSAFE - UNSAFE**
     
     This is really unsafe, but we need it to support functions that use an
     array of `iovec` like `readv` and `writev`.
     
     Swift tries really hard to prevent pointers into Swift values from escaping
     closures where it can ensure that they are valid, but there are contexts
     where they are valid apart from the ones that the Swift compiler can prove,
     so we *must* ensure that these pointers don't escape such contexts.
     
     In short, we must ensure that no pointer obtained through this function
     escapes the immediate context in which its obtained.  That is to say, if
     such a pointer is passed to another function, that function must not make
     a copy and store it for later use.
     
     This function returns UnsafeMutableRawPointer rather than UnsafeRawPointer
     because `iovec` is defined to use UnsafeMutableRawPointer; however this
     function is not "mutating" so the caller has to ensure that the pointer
     isn't used for setting the data it points to... yet another reason this is
     unsafe.
     
     Basically, this function takes the training wheels off... so be really sure
     you know what you're doing.  You have been warned.
     */
    internal func unsafeDataPointer() -> UnsafeMutableRawPointer?
    {
        if count == 0 { return nil }

        /*
         Because this is so unsafe, we have to do a little dance to defeat
         Swift's pointer invalidation mechanism in order to return the pointer.
         Basically we have to capture the address as a UInt inside the closure
         where it's valid, then convert it back to a pointer after the closure
         returns.
         */
        let address: UInt  = self.withUnsafeBytes
        {
            if let p = $0.baseAddress {
                return UInt(bitPattern: p)
            }
            return 0
        }
        
        return address == 0
            ? nil
            : UnsafeMutableRawPointer(bitPattern: address)
    }
    
    // -------------------------------------
    /**
        **UNSAFE - UNSAFE - UNSAFE - UNSAFE - UNSAFE**
     
     This is really unsafe, but we need it to support functions that use an
     array of `iovec` like `readv` and `writev`.
     
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
    internal mutating func unsafeMutableDataPointer()
        -> UnsafeMutableRawPointer?
    {
        if count == 0 { return nil }
        
        /*
         Because this is so unsafe, we have to do a little dance to defeat
         Swift's pointer invalidation mechanism in order to return the pointer.
         Basically we have to capture the address as a UInt inside the closure
         where it's valid, then convert it back to a pointer after the closure
         returns.
         */
        let address: UInt = withUnsafeMutableBytes
        {
            if let p = $0.baseAddress {
                return UInt(bitPattern: p)
            }
            return 0
        }
        
        return address == 0
            ? nil
            : UnsafeMutableRawPointer(bitPattern: address)
    }
}
