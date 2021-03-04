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
public protocol HostOSAddress {
    init()
}

// MARK:- IPv4
// -------------------------------------
extension in_addr: HostOSAddress { }

// -------------------------------------
public extension in_addr
{
    // -------------------------------------
    @inlinable static var any: Self { Self(s_addr: 0) }
    @inlinable static var broadcast: Self { Self(s_addr: 0xffff_ffff) }
    @inlinable static var loopback: Self { Self(s_addr: 0x0100_007f) }
    
    // -------------------------------------
    init?(address: String)
    {
        guard let addr: Self = inet_pton(address) else { return nil }
        self = addr
    }
}

// -------------------------------------
extension in_addr: CustomStringConvertible
{
    public var description: String
    {
        switch inet_ntop(.inet4, self)
        {
            case .success(let s): return s
            case .failure(let error): return error.description
        }
    }
}

// -------------------------------------
extension in_addr: Equatable
{
    // -------------------------------------
    public static func == (lhs: in_addr, rhs: in_addr) -> Bool {
        return lhs.s_addr == rhs.s_addr
    }
}


// MARK:- IPv6
// -------------------------------------
extension in6_addr: HostOSAddress { }

// -------------------------------------
public extension in6_addr
{
    // -------------------------------------
    @inlinable static var any: Self { in6addr_any }
    @inlinable static var loopback: Self { in6addr_loopback }
    
    // -------------------------------------
    @inlinable static var linkLocalAllNodes: Self {
        in6addr_linklocal_allnodes
    }
    
    // -------------------------------------
    @inlinable static var linkLocalAllRouters: Self {
        in6addr_linklocal_allrouters
    }
    
    // -------------------------------------
    @inlinable static var linkLocalAllV2Routers: Self {
        in6addr_linklocal_allv2routers
    }
    
    // -------------------------------------
    init?(address: String)
    {
        guard let addr: Self = inet_pton(address) else { return nil }
        self = addr
    }
}

// -------------------------------------
extension in6_addr: CustomStringConvertible
{
    public var description: String
    {
        switch inet_ntop(.inet6, self)
        {
            case .success(let s): return s
            case .failure(let error): return error.description
        }
    }
}

// -------------------------------------
extension in6_addr: Equatable
{
    // -------------------------------------
    public static func == (lhs: in6_addr, rhs: in6_addr) -> Bool
    {
        return lhs.__u6_addr.__u6_addr32.0 == rhs.__u6_addr.__u6_addr32.0
            && lhs.__u6_addr.__u6_addr32.1 == rhs.__u6_addr.__u6_addr32.1
            && lhs.__u6_addr.__u6_addr32.2 == rhs.__u6_addr.__u6_addr32.2
            && lhs.__u6_addr.__u6_addr32.3 == rhs.__u6_addr.__u6_addr32.3

    }
    
}
