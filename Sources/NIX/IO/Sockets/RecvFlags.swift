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
/**
 Flags for options to alter the behavior of `recv` and `recvfrom` and
 `recvmsg`
 */
public struct RecvFlags: NIXFlags
{
    public typealias RawValue = Int32
    
    @usableFromInline internal var _rawValue: RawValue
    @inlinable public var rawValue: RawValue { _rawValue }

    /// Process out-of-band data
    public static let outOfBand = Self(rawValue: HostOS.MSG_OOB)
    
    /// Read data from the receive queue without removing it
    public static let peek = Self(rawValue: HostOS.MSG_PEEK)
    
    /**
     Blocks until all the requested data is read.  However, it may still
     return with few bytes than requested if a signal is received, an error
     or disconnetion occurs, or the data is of a different type than that
     returned..
     */
    public static let waitAll = Self(rawValue: HostOS.MSG_WAITALL)
    
    public static let all = Self([outOfBand, peek, waitAll])
    
    // -------------------------------------
    @inlinable public init(rawValue: RawValue) {
        self._rawValue = rawValue
    }
}
