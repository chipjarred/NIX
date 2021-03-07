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
import Foundation

// -------------------------------------
extension Array where Element == Data
{
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
     `mutableIOVecs` for that instead.
     
     Basically, this function takes the training wheels off... so be really sure
     you know what you're doing.  You have been warned.
     */
    @usableFromInline
    internal func iovecs() -> [HostOS.iovec]
    {
        var a = [HostOS.iovec]()
        a.reserveCapacity(count)
        
        for i in self.indices {
            a.append(self[i].iovec())
        }
        
        return a
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
    `Data` through the pointer.  Otherwise use the `iovecs()` method instead.
     
     Basically, this function takes the training wheels off... so be really sure
     you know what you're doing.  You have been warned.
     */
    @usableFromInline
    internal mutating func mutableIOVecs() -> [HostOS.iovec]
    {
        var a = [HostOS.iovec]()
        a.reserveCapacity(count)
        
        for i in self.indices {
            a.append(self[i].mutableIOVec())
        }
        
        return a
    }
}
