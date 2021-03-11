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

// MARK:- IP address manipulation and translation
// -------------------------------------
/**
 Convert an address *`src` from network format (usually a struct `in_addr` or
 some other binary form, in network byte order) to  presentation format
 (suitable for external display purposes).

 This function is presently valid for `.inet4` and `.inet6`.
 
 - Parameters:
    - addressFamily: The address family of the address being translated.
    - address: The `Address` to be translated
 
 - Returns: On success, the returned `Result` contains the specified `address`
    represented as a `String`.   On failure, it contains the `Error`.
 */
@inlinable
public func inet_ntop<IPAddress: HostOSAddress>(
    _ addressFamily: AddressFamily,
    _ address: IPAddress) -> Result<String, Error>
{
    assert([.inet4, .inet6].contains(addressFamily))
    
    var buffer = [CChar](repeating: 0, count: 1024)
    return buffer.withUnsafeMutableBufferPointer
    { bufferPtr in
        return withUnsafeBytes(of: address)
        { addressPtr in
            let p = inet_ntop(
                addressFamily.rawValue,
                addressPtr.baseAddress!,
                bufferPtr.baseAddress!,
                socklen_t(bufferPtr.count)
            )
            
            return p == nil
                ? .failure(Error())
                : .success(String(cString: bufferPtr.baseAddress!))
        }
    }
}

// -------------------------------------
/**
 Convert an IPv4 address expressed as a string into its equivalent `in_addr`.
 
 - Parameter address: a `String` representation of an IPv4 address in
    dotted quad notation (eg: `127.0.0.1`).

 - Returns: On success, the `in_addr` struct described by `address`; otherwise,
    `nil`.
 
 - Note: This function is a rare example where the underlying POSIX function
    returns `1` for success and `0` for failure (ie. ordinary boolean), and
    does *not* set `errno` on failure.  Since there is no error code to be
    returned, we simply return the resulting address on success and `nil` on
    failure.
 */
@inlinable
public func inet_pton<S: StringProtocol>(_ address: S) -> in_addr? {
    return inet_pton(.inet4, address)
}


// -------------------------------------
/**
 Convert an IPv6 address expressed as a string into its equivalent `in6_addr`.
 
 The address can be expressed in canonical form as a colon-separated list of
 eight  4-digit hexadecimal numbers, or may be compressed per IPv6 rules,
 which are, in the order they are applied:
 
 1. Within each field, leading zeros may be omitted, unless it is the
     only digit.
 2. If there is one longest sequence of *two* or more consecutive zero fields,
    that entire sequence may be replaced with `"::"`
 3. If there are more than one equally long sequence of two or more consecutive
    zero fields that compete for the longest sequence, the left-most sequence
    may be replaced by `"::"`, while the others must be kept as-is.
 
 As an example, here is how the rules apply to a specific canonical IPv6
 address:
 
        "2001:0db8:0000:0000:85a3:0000:0000:7334"
 
 Applying rule 1, leading zeros are removed within each field
 
        "2001:db8:0:0:85a3:0:0:7334"
 
 Applying rule 2, we see there are two equally "longest" sequences of
 consecutive zero fields.
 
        "2001:db8:0:0:85a3:0:0:7334"
                  ^^^      ^^^

 Applying rule 3 breaks the tie by compressing the left-most sequence, and
 leaving the other as-is.
 
        "2001:db8::85a3:0:0:7334"
 
 When there are many of consecutive zero fields, the compression can be
 dramatic.  For example, the invalid and loopback addresses compress to almost
 nothing:
 
        "0000:0000:0000:0000:0000:0000:0000:0000" -> "::"
        "0000:0000:0000:0000:0000:0000:0000:0001" -> "::1"

 - Parameter address: a `String` representation of an IPv6 address as described
    above.
 
 - Returns: On success, the `in6_addr` struct described by `address`; otherwise,
    `nil`.
 
 - Note: This function is a rare example where the underlying POSIX function
    returns `1` for success and `0` for failure (ie. ordinary boolean), and
    does *not* set `errno` on failure.  Since there is no error code to be
    returned, we simply return the resulting address on success and `nil` on
    failure.
*/
@inlinable
public func inet_pton<S: StringProtocol>(_ address: S) -> in6_addr? {
    return inet_pton(.inet6, address)
}

// -------------------------------------
/**
 Convert an IP address expressed as a string into its equivalent binary address.
 
 - Parameters:
    - addressFamily: The `AddresFamily` of the IP address expressed in
        `address`.  Only `.inet4` and `.inet6` are currently supported.
    - address: a `String` representation of an IP address.

 - Returns: On success, the binary address described by `address`; otherwise,
    `nil`.
 
 - Note: This function is a rare example where the underlying POSIX function
    returns `1` for success and `0` for failure (ie. ordinary boolean), and
    does *not* set `errno` on failure.  Since there is no error code to be
    returned, we simply return the resulting address on success and `nil` on
    failure.
 */
@usableFromInline
internal func inet_pton<IPAddress: HostOSAddress, S: StringProtocol>(
    _ addressFamily: AddressFamily,
    _ address: S) -> IPAddress?
{
    assert([.inet4, .inet6].contains(addressFamily))
    
    var netAddr = IPAddress()
    let result = withUnsafeMutableBytes(of: &netAddr)
    { netAddrPtr in
        return address.withCString
        {
            return HostOS.inet_pton(
                addressFamily.rawValue,
                $0,
                netAddrPtr.baseAddress
            )
        }
    }
    
    return result == 1 ? netAddr : nil
}

// -------------------------------------
/**
 Obtain an `Array` of `SocketAddress` instances that correspond to the
 specified `host` name and `port`.
 
 - Parameters:
    - host: The name of the host to look up
    - port: The port `on` host to look up.
    - socketType: The socket type for the connection desired.
 
 - Returns: On success, the returned `Result` will contain an array of
    `SocketAddress` instances suitable for making a connection to the
    specified `host` and `port`.  Typically it will consist of one IPv4
    address and one IPv6 address.  On failure, the returned result will
    contain the underlying `Error`; (however currently the error actually be
    the wrong error.   The underlying POSIX call does not set `errno` as most
    do.  Instead it returns an error representing a different set of error
    numbers.  This will be fixed in the future.
 */
public func sockaddr(for host: String, port: Int, socketType: SocketType)
    -> Result<[SocketAddress], Error>
{
    host.withCString
    { host in
        "\(port)".withCString
        { port in
            var hints = HostOS.addrinfo()
            hints.ai_flags = HostOS.PF_UNSPEC
            hints.ai_socktype = socketType.rawValue
            var addrInfo: UnsafeMutablePointer<HostOS.addrinfo>? = nil
            let error = getaddrinfo(host, port, &hints, &addrInfo)
            guard error == 0 else
            {
                /*
                 FIXME: error here is actually described by
                 gai_strerror(error) rather than by strerror(error).
                 */
                return .failure(Error(error))
            }
            defer { HostOS.freeaddrinfo(addrInfo) }
            
            var addresses: [SocketAddress] = []
            while let curInfo = addrInfo?.pointee
            {
                switch curInfo.ai_family
                {
                    case AF_INET:
                        curInfo.ai_addr.withMemoryRebound(
                            to: sockaddr_in.self,
                            capacity: 1)
                            { addresses.append(SocketAddress($0.pointee)) }
                        
                    case AF_INET6:
                        curInfo.ai_addr.withMemoryRebound(
                            to: sockaddr_in6.self,
                            capacity: 1)
                            { addresses.append(SocketAddress($0.pointee)) }
                        
                    default: break
                }
                addrInfo = curInfo.ai_next
            }
            
            return .success(addresses)
        }
    }
}
