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
public protocol SocketAddress { }
public extension SocketAddress
{
    @inlinable
    static var byteSize: socklen_t {
        return socklen_t(MemoryLayout<Self>.size)
    }
}

extension sockaddr: SocketAddress { }
extension sockaddr_in: SocketAddress { }
extension sockaddr_in6: SocketAddress { }
extension sockaddr_un: SocketAddress { }

// -------------------------------------
public extension sockaddr_in
{
    // -------------------------------------
    @inlinable var family: AddressFamily
    {
        get
        {
            guard let family = NIX.IP4AddressFamily(rawValue: Int32(sin_family))
            else { fatalError("Invalid IPv4 address family: \(sin_family)") }
            
            return family.rawValue
        }
        set
        {
            guard let family = NIX.IP4AddressFamily(rawValue: newValue) else {
                fatalError("Invalid IPv4 address family: \(newValue.rawValue)")
            }
            
            sin_family = sa_family_t(family.rawValue.rawValue)
        }
    }
    
    // -------------------------------------
    @inlinable var port: Int
    {
        get { return Int(sin_port.toHostByteOrder) }
        set { sin_port = in_port_t(newValue).toNetworkByteOrder }
    }
}

// -------------------------------------
public extension sockaddr_in6
{
    // -------------------------------------
    @inlinable var family: NIX.AddressFamily
    {
        get
        {
            precondition(
                sin6_family == AF_INET6,
                "Invalid IPv6 address family: \(sin6_family)"
            )
            return .inet6
        }
        set
        {
            precondition(
                newValue == .inet6,
                "Invalid IPv6 address family: \(newValue.rawValue)"
            )
            sin6_family = sa_family_t(newValue.rawValue)
        }
    }
    
    // -------------------------------------
    @inlinable var port: Int
    {
        get { return Int(sin6_port.toHostByteOrder) }
        set { sin6_port = in_port_t(newValue).toNetworkByteOrder }
    }
}

// -------------------------------------
public extension sockaddr_un
{
    @inlinable static var maxPathLen: Int
    {
        MemoryLayout<Self>.size
            - 1 // for sun_len
            - MemoryLayout<sa_family_t>.size // for sun_family
    }
    
    // -------------------------------------
    @inlinable var family: NIX.AddressFamily
    {
        get
        {
            precondition(
                sun_family == AF_UNIX,
                "Invalid Unix domain address family: \(sun_family)"
            )
            return .unix
        }
        set
        {
            precondition(
                newValue == .unix,
                "Invalid Unix domain family: \(newValue.rawValue)"
            )
            sun_family = sa_family_t(newValue.rawValue)
        }
    }

    // -------------------------------------
    var path: NIX.UnixSocketPath
    {
        // -------------------------------------
        get
        {
            withUnsafeBytes(of: sun_path)
            {
                let p = $0.bindMemory(to: CChar.self)
                let len = min(Self.maxPathLen, strlen(p.baseAddress!))
                return NIX.UnixSocketPath(
                    String.init(bytes: $0[..<len], encoding: .utf8)!
                )!
            }
        }
        
        // -------------------------------------
        set
        {
            newValue.rawValue.withCString
            { src in
                withUnsafeMutableBytes(of: &sun_path)
                {
                    let dst = $0.bindMemory(to: CChar.self)
                    _ = memset(dst.baseAddress!, 0, sockaddr_un.maxPathLen)
                    _ = strncpy(dst.baseAddress!, src, sockaddr_un.maxPathLen)
                }
            }
        }
    }
}

// -------------------------------------
/*
 Cretae an IPv4 socket address with the specified IP `address` and `port`.
 */
@inlinable
public func socketAddress(
    for ip4Address: in_addr,
    port: Int,
    family: IP4AddressFamily = .inet4) -> some SocketAddress
{
    var sAddr = sockaddr_in()
    
    sAddr.sin_len = __uint8_t(sockaddr_in.byteSize)
    sAddr.family = family.rawValue
    sAddr.sin_addr = ip4Address
    sAddr.port = port
    
    return sAddr
}

// -------------------------------------
@inlinable
public func socketAddress(
    for ip6Address: in6_addr,
    port: Int) -> some SocketAddress
{
    var sAddr = sockaddr_in6()
    
    sAddr.sin6_len = __uint8_t(sockaddr_in6.byteSize)
    sAddr.sin6_flowinfo = 0
    sAddr.family = .inet6
    sAddr.sin6_addr = ip6Address
    sAddr.port = port
    
    return sAddr
}

// -------------------------------------
@inlinable
public func socketAddress(for path: UnixSocketPath) -> some SocketAddress
{
    var sAddr = sockaddr_un()
    
    sAddr.sun_len = __uint8_t(sockaddr_un.byteSize)
    sAddr.family = .unix
    sAddr.path = path
    
    return sAddr
}
