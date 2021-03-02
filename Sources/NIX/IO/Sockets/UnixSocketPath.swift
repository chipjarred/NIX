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
 Type to respresent Unix paths suitable for Unix domain sockets.
 
 Such paths have length limitations imposed by the size of the `sun_path`
 property in `sockaddr_un`. This type ensures those requirements are met.
 */
public struct UnixSocketPath: CustomStringConvertible
{
    public private(set) var rawValue: String
    
    @inlinable public var description: String { rawValue }
    
    // -------------------------------------
    @inlinable public init?(_ path: String)
    {
        let socketPath = path.withCString {
            return strlen($0) <= sockaddr_un.maxPathLen
                ? path
                : nil
        }
        
        guard let sPath = socketPath else { return nil }
        
        self.init(path: sPath)
    }
    
    // -------------------------------------
    @usableFromInline internal init(path: String) {
        self.rawValue = path
    }
}
