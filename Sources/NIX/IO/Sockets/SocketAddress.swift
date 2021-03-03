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
public protocol HostOSSocketAddress { }

extension sockaddr_in: HostOSSocketAddress { }
extension sockaddr_in6: HostOSSocketAddress { }
extension sockaddr_un: HostOSSocketAddress { }

// -------------------------------------
public struct SocketAddress
{
    // Storage should be the largest socket address type supported by host OS
    @usableFromInline internal typealias Storage = sockaddr_un
    @usableFromInline internal var storage: Storage
    
    public var family: AddressFamily { return storage.family }
    public var len: UInt32 { return UInt32(storage.sun_len) }
    
    // -------------------------------------
    public var asINET4: sockaddr_in?
    {
        guard family == .inet4 else { return nil }
        return withPointer(to: storage, recastTo: sockaddr_in.self) {
            $0.pointee
        }
    }
    
    // -------------------------------------
    public var asINET6: sockaddr_in6?
    {
        guard family == .inet6 else { return nil }
        return withPointer(to: storage, recastTo: sockaddr_in6.self) {
            $0.pointee
        }
    }
    
    // -------------------------------------
    public var asUnix: sockaddr_un?
    {
        guard family == .unix else { return nil }
        return withPointer(to: storage, recastTo: sockaddr_un.self) {
            $0.pointee
        }
    }
    
    // -------------------------------------
    public init() { self.storage = Storage() }
    
    // -------------------------------------
    public init<T: HostOSSocketAddress>(_ socketAddress: T)
    {
        self.storage = withPointer(to: socketAddress, recastTo: Storage.self)
        {
            #if DEBUG
            switch Int32($0.pointee.sun_family)
            {
                case AF_INET, AF_INET6, AF_UNIX: break
                default: assertionFailure(
                        "Unsupported address family: \($0.pointee.sun_family)"
                    )
            }
            #endif
            return $0.pointee
        }
    }
    
    // -------------------------------------
    public init(ip4Address address: in_addr, port: Int)
    {
        var addr = sockaddr_in()
        addr.sin_len = __uint8_t(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(HostOS.AF_INET)
        addr.sin_port = in_port_t(port).toNetworkByteOrder
        addr.sin_addr = address
        self.init(addr)
    }
    
    // -------------------------------------
    public init(ip6Address address: in6_addr, port: Int, flowInfo: UInt32 = 0)
    {
        var addr = sockaddr_in6()
        addr.sin6_len = __uint8_t(MemoryLayout<sockaddr_in6>.size)
        addr.sin6_family = sa_family_t(HostOS.AF_INET6)
        addr.sin6_flowinfo = flowInfo
        addr.sin6_port = in_port_t(port).toNetworkByteOrder
        addr.sin6_addr = address
        self.init(addr)
    }
    
    // -------------------------------------
    public init(unixPath path: UnixSocketPath)
    {
        var addr = sockaddr_un()
        addr.sun_len = __uint8_t(MemoryLayout<sockaddr_un>.size)
        addr.sun_family = sa_family_t(HostOS.AF_UNIX)
        
        path.rawValue.withCString
        { src in
            withUnsafeMutableBytes(of: &addr.sun_path)
            {
                let dst = $0.bindMemory(to: CChar.self)
                strncpy(dst.baseAddress, src, dst.count)
            }
        }

        self.init(addr)
    }
    
    // -------------------------------------
    @inlinable public func withGenericPointer<R>(
        _ block: (UnsafePointer<sockaddr>) throws -> R) rethrows -> R
    {
        return try withPointer(to: storage, recastTo: sockaddr.self) {
            return try block($0)
        }
    }
    
    // -------------------------------------
    @inlinable public mutating func withMutableGenericPointer<R>(
        _ block: (UnsafeMutablePointer<sockaddr>) throws -> R) rethrows -> R
    {
        return try withMutablePointer(to: &storage, recastTo: sockaddr.self) {
            return try block($0)
        }
    }
}

// -------------------------------------
public extension sockaddr_in
{
    // -------------------------------------
    @inlinable var family: AddressFamily
    {
        get
        {
            precondition(
                sin_family == AF_INET,
                "Invalid IPv4 address family: \(sin_family)"
            )
            
            return AddressFamily(rawValue: Int32(sin_family))!
        }
        set
        {
            precondition(
                newValue == .inet4,
                "Invalid IPv4 address family: \(sin_family)"
            )

            sin_family = sa_family_t(newValue.rawValue)
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
