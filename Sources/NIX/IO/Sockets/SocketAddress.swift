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
    @usableFromInline internal typealias Storage = sockaddr_storage
    @usableFromInline internal var storage: Storage
    
    public var family: AddressFamily {
        return AddressFamily(rawValue: Int32(storage.ss_family))!
    }
    public var len: UInt32 { return UInt32(storage.ss_len) }
    
    // -------------------------------------
    public var asINET4: sockaddr_in?
    {
        guard storage.ss_family == AF_INET else { return nil }
        return withPointer(to: storage, recastTo: sockaddr_in.self) {
            $0.pointee
        }
    }
    
    // -------------------------------------
    public var asINET6: sockaddr_in6?
    {
        guard storage.ss_family == AF_INET6 else { return nil }
        return withPointer(to: storage, recastTo: sockaddr_in6.self) {
            $0.pointee
        }
    }
    
    // -------------------------------------
    public var asUnix: sockaddr_un?
    {
        guard storage.ss_family == AF_UNIX else { return nil }
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
            switch Int32($0.pointee.ss_family)
            {
                case AF_INET, AF_INET6, AF_UNIX: break
                default: assertionFailure(
                        "Unsupported address family: \($0.pointee.ss_family)"
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
    
    // -------------------------------------
    /**
     Initialize a `SocketAddress` with a string describing a valid socket
     address.
     
     A valid socket address description is one that describes one of the
     following:
     
        - An IPv4 address and port (eg. `"192.168.1.4:80"`)
        - An IPv6 address and port (eg. `"[::8f:8a21]:80"`)
        - A Unix domain socket path (eg. `"/run/myserviced.socket"`)
     
     In order to create the proper underlying socket address type, this
     initializer first attempts to initialize as an IPv4 socket address.
     If that fails, then it tries IPv6.  And if that fails, it tries Unix
     domain.  If that fails, then initialization fails, and it returns `nil`
     
     - Parameter address: `String` describing a valid socket address as
        described above.
     
     - Returns: On success,the newly created `SocketAddress`; otherwise `nil`
     */
    init?<S: StringProtocol>(_ address: S)
    {
        if let ip4Addr = sockaddr_in(address) {
            self.init(ip4Addr)
        }
        else if let ip6Addr = sockaddr_in6(address) {
            self.init(ip6Addr)
        }
        else if let unixAddr = sockaddr_un(address) {
            self.init(unixAddr)
        }
        else { return nil }
    }
}

// -------------------------------------
extension SocketAddress: CustomStringConvertible
{
    public var description: String
    {
        switch Int32(storage.ss_family)
        {
            case AF_INET: return asINET4!.description
            case AF_INET6: return asINET6!.description
            case AF_UNIX : return asUnix!.description
            default:
                assertionFailure(
                    "Unsupported address family: \(storage.ss_family)"
                )
                return "<<UNSUPPORTED ADDRESS FAMILY>>"
        }
    }
}

// -------------------------------------
extension SocketAddress: Equatable
{
    // -------------------------------------
    @inlinable public static func == (left: Self, right: Self) -> Bool
    {
        guard left.storage.ss_family == right.storage.ss_family else {
            return false
        }
        
        switch Int32(left.storage.ss_family)
        {
            case HostOS.AF_INET: return left.asINET4 == right.asINET4
            case HostOS.AF_INET6: return left.asINET6 == right.asINET6
            case HostOS.AF_UNIX: return left.asUnix == right.asUnix
            default: break
        }
        
        return withUnsafeBytes(of: left)
        { leftPtr in
            withUnsafeBytes(of: right)
            {
                return 0 == memcmp(
                    leftPtr.baseAddress!,
                    $0.baseAddress!,
                    Int(max(left.len, right.len))
                )
            }
        }
    }
}

// MARK:- IPv6 Domain
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
    
    // -------------------------------------
    /**
     Initialize a `sockaddr_in` with a string describing the IPv4 address and
     port.
     
     `addressAndPort` must be a `String` containing only a the IPv4 address in a
     dot-separated list of four decimal numbers in the range 0...255, followed
     by a `":"`, followed by a decimal port number, with no whitespace.
     
     For example the string for describing port `80` on the loopback address is
     
            "127.0.0.1:80"
     
     - Parameter addressAndPort: String describing the IPv4 address and port.
     
     - Returns: On success,the newly created `sockaddr_in`; otherwise `nil`
     */
    @inlinable init?<S: StringProtocol>(_ addressAndPort: S)
    {
        guard var portStart = addressAndPort.firstIndex(of: ":"),
              let address = in_addr(address: addressAndPort[..<portStart])
        else { return nil }
        
        portStart = addressAndPort.index(after: portStart)
        guard let port = in_port_t(addressAndPort[portStart...]) else {
            return nil
        }
        
        self = Self()
        self.sin_len = __uint8_t(MemoryLayout<Self>.size)
        self.sin_family = sa_family_t(HostOS.AF_INET)
        self.sin_port = port.toNetworkByteOrder
        self.sin_addr = address
    }
}

// -------------------------------------
extension sockaddr_in: CustomStringConvertible
{
    public var description: String { "\(sin_addr):\(sin_port.toHostByteOrder)" }
}

// -------------------------------------
extension sockaddr_in: Equatable
{
    @inlinable public static func == (left: Self, right: Self) -> Bool
    {
        return left.sin_len == right.sin_len
            && left.sin_family == right.sin_family
            && left.sin_port == right.sin_port
            && left.sin_addr == right.sin_addr
    }
}


// MARK:- IPv6 Domain
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
    
    // -------------------------------------
    /**
     Initialize a `sockaddr_in6` with a string describing the IPv6 address and
     port.
     
     `addressAndPort` must be a `String` containing only a bracket-enclosed IPv6
     address, which may be compressed per IPv6 rules, followed a `":"`,
     followed by a decimal port number, with no whitespace.
     
     For example the string for describing port `80` on the loopback address is
     
            "[::1]:80"
     
     - Parameter addressAndPort: String describing the IPv6 address and port.
     
     - Returns: On success,the newly created `sockaddr_in6`; otherwise `nil`
     */
    @inlinable init?<S: StringProtocol>(_ addressAndPort: S)
    {
        guard addressAndPort.first == "[",
              let addressEnd = addressAndPort.firstIndex(of: "]")
        else { return nil }
        
        var portStart = addressAndPort.index(after: addressEnd)
        guard addressAndPort[portStart] == ":" else { return nil }
        
        portStart = addressAndPort.index(after: portStart)
        guard let port = in_port_t(addressAndPort[portStart...]) else {
            return nil
        }
        
        let addressStart =
            addressAndPort.index(after: addressAndPort.startIndex)
        
        guard let address =
                in6_addr(address: addressAndPort[addressStart..<addressEnd])
        else { return nil }
        
        self = Self()
        self.sin6_len = __uint8_t(MemoryLayout<Self>.size)
        self.sin6_family = sa_family_t(HostOS.AF_INET6)
        self.sin6_port = port.toNetworkByteOrder
        self.sin6_addr = address
        self.sin6_flowinfo = 0
    }
}

// -------------------------------------
extension sockaddr_in6: CustomStringConvertible
{
    public var description: String {
        "[\(sin6_addr)]:\(sin6_port.toHostByteOrder)"
    }
}

// -------------------------------------
extension sockaddr_in6: Equatable
{
    @inlinable public static func == (left: Self, right: Self) -> Bool
    {
        return left.sin6_len == right.sin6_len
            && left.sin6_family == right.sin6_family
            && left.sin6_port == right.sin6_port
            && left.sin6_addr == right.sin6_addr
            && left.sin6_flowinfo == right.sin6_flowinfo
    }
}

// MARK:- Unix Domain
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
    
    // -------------------------------------
    @inlinable init(_ path: UnixSocketPath)
    {
        self = Self()
        self.sun_len = UInt8(MemoryLayout<Self>.size)
        self.sun_family = sa_family_t(HostOS.AF_UNIX)
        self.path = path
    }
    
    // -------------------------------------
    @inlinable init?<S: StringProtocol>(_ path: S)
    {
        guard let unixPath = UnixSocketPath(path) else { return nil }
        self.init(unixPath)
    }
}

// -------------------------------------
extension sockaddr_un: CustomStringConvertible {
    public var description: String { path.description }
}

// -------------------------------------
extension sockaddr_un: Equatable
{
    // -------------------------------------
    @inlinable public static func == (left: Self, right: Self) -> Bool
    {
        return left.family == right.family
            && left.sun_len == right.sun_len
            && left.path == right.path
    }
}
