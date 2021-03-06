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

#if canImport(Darwin)
public struct SpinLock
{
    @usableFromInline var osLock = os_unfair_lock()
    
    @usableFromInline @inline(__always)
    internal mutating func lock() { os_unfair_lock_lock(&osLock) }
    
    @usableFromInline @inline(__always)
    internal mutating func unlock() { os_unfair_lock_unlock(&osLock) }
}
#else
#error("Define SpinLock with same interface as for Darwin - see above")
#endif

// -------------------------------------
public extension SpinLock
{
    // -------------------------------------
    @inlinable
    mutating func withLock<R>(_ block: () throws -> R) rethrows -> R
    {
        lock(); defer { unlock() }
        return try block()
    }
}
