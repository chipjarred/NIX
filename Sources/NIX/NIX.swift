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

import HostOS

// -------------------------------------
/// Wrapper for standard C/Darwin's `errno`
public struct Error: Swift.Error, CustomStringConvertible
{
    public let errno: Int32
    
    public init() { self.errno = HostOS.errno }
    public init(_ errno: Int32) { self.errno = errno }
    
    public var localizedDescription: String {
        return String(cString: strerror(errno))
    }
    
    public var description: String {
        return "\(errno): \(localizedDescription)"
    }
}

// MARK:- Private helper functions
// -------------------------------------
@usableFromInline @inline(__always)
internal func withPointer<T, U, R>(
    to value: T,
    recastTo: U.Type,
    do block: (UnsafePointer<U>) throws -> R) rethrows -> R
{
    return try withUnsafePointer(to: value) {
        return try $0.withMemoryRebound(to: U.self, capacity: 1) {
            return try block($0)
        }
    }
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func withMutablePointer<T, U, R>(
    to value: inout T,
    recastTo: U.Type,
    do block: (UnsafeMutablePointer<U>) throws -> R) rethrows -> R
{
    return try withUnsafeMutablePointer(to: &value) {
        return try $0.withMemoryRebound(to: U.self, capacity: 1) {
            return try block($0)
        }
    }
}
