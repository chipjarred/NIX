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
 Simple buffer cache to avoid constantly actually allocating and reallocating
 Used by `MessageToReceive` for `recvmsg`
 */
internal struct ControlMessageBufferCache
{
    internal static let bufferSize = 4096
    
    internal static var cacheLock = SpinLock()
    internal static var cache: [Data] = []
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func allocate() -> Data
    {
        return cacheLock.withLock { cache.isEmpty ? nil : cache.removeLast() }
            ?? Data(repeating: 0, count: bufferSize)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func deallocate(_ data: inout Data)
    {
        assert(data.count == bufferSize, "returning incorrectly sized data")
        
        // Zero-fill returned Data instances for security reasons.
        data.resetBytes(in: data.startIndex..<data.endIndex)

        cacheLock.withLock { cache.append(data) }
    }
    
    private init() { }
}
