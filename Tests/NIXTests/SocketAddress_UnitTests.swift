import XCTest
@testable import NIX

// -------------------------------------
class SocketAddress_UnitTests: XCTestCase
{
    static var allTests =
    [
        ("test_IP4_SocketAddress_description_is_correct", test_IP4_SocketAddress_description_is_correct),
        ("test_IP6_SocketAddress_description_is_correct", test_IP6_SocketAddress_description_is_correct),
        ("test_Unix_domain_SocketAddress_description_is_correct", test_Unix_domain_SocketAddress_description_is_correct),
        ("test_IP4_SocketAddress_initializes_from_IPv4_socket_address_description_string", test_IP4_SocketAddress_initializes_from_IPv4_socket_address_description_string),
        ("test_IP6_SocketAddress_initializes_from_IPv6_socket_address_description_string", test_IP6_SocketAddress_initializes_from_IPv6_socket_address_description_string),
        ("test_Unix_domain_SocketAddress_initializes_from_Unix_domain_socket_address_description_string", test_Unix_domain_SocketAddress_initializes_from_Unix_domain_socket_address_description_string),
    ]
    
    // -------------------------------------
    func test_IP4_SocketAddress_description_is_correct()
    {
        typealias AddressDescription = (address: in_addr_t, port: Int)
        let testCases: [(input: AddressDescription, expected: String)] =
        [
            (input: (0x00000000,   22), expected: "0.0.0.0:22"),
            (input: (0x00000001,   80), expected: "0.0.0.1:80"),
            (input: (0x00000100, 4092), expected: "0.0.1.0:4092"),
            (input: (0x00010000,    1), expected: "0.1.0.0:1"),
            (input: (0x01000000,    5), expected: "1.0.0.0:5"),
            (input: (0x7F000001,   22), expected: "127.0.0.1:22"),
            (input: (0xFFFFFFFF,   22), expected: "255.255.255.255:22"),
            (input: (0x1F0110F1,   22), expected: "31.1.16.241:22"),
        ]
        for (input, expected) in testCases
        {
            let address = in_addr(s_addr: input.address.toNetworkByteOrder)
            
            let sockAddress =
                SocketAddress(ip4Address: address, port: input.port)
            
            let actual = sockAddress.description
            XCTAssertEqual(actual, expected)
        }
    }
    
    // -------------------------------------
    func test_IP6_SocketAddress_description_is_correct()
    {
        typealias BinaryAddress = (
            __uint16_t, __uint16_t, __uint16_t, __uint16_t,
            __uint16_t, __uint16_t, __uint16_t, __uint16_t
        )
        typealias AddressDescription = (address: BinaryAddress, port: Int)
        let testCases: [(input: AddressDescription, expected: String)] =
        [
            (
                input:
                (
                    address:
                    (
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder
                    ),
                    port: 2020
                ),
                expected: "[::]:2020"
            ),
            (
                input:
                (
                    address:
                    (
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0001).toNetworkByteOrder
                    ),
                    port: 2020
                ),
                expected: "[::1]:2020"
            ),
            (   // 0000:0000:0000:0000:0000:0000:0000:0001
                input:
                (
                    address:
                    (
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x1000).toNetworkByteOrder
                    ),
                    port: 2
                ),
                expected: "[::1000]:2"
            ),
            (   // 0001:0000:0000:0000:0000:0000:0000:0000
                input:
                (
                    address:
                    (
                        __uint16_t(0x0001).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder
                    ),
                    port: 80
                ),
                expected: "[1::]:80"
            ),
            (   // 1000:0000:0000:0000:0000:0000:0000:0000
                input:
                (
                    address:
                    (
                        __uint16_t(0x1000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder
                    ),
                    port: 10
                ),
                expected: "[1000::]:10"
            ),
            (   // 0000:0000:0000:0000:0000:8a2e:0370:7334
                input:
                (
                    address:
                    (
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x8a2e).toNetworkByteOrder,
                        __uint16_t(0x0370).toNetworkByteOrder,
                        __uint16_t(0x7334).toNetworkByteOrder
                    ),
                    port: 42
                ),
                expected: "[::8a2e:370:7334]:42"
            ),
            (   // 2001:0db8:85a3:0000:0000:0000:0000:0000
                input:
                (
                    address:
                    (
                        __uint16_t(0x2001).toNetworkByteOrder,
                        __uint16_t(0x0db8).toNetworkByteOrder,
                        __uint16_t(0x85a3).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder
                    ),
                    port: 80
                ),
                expected: "[2001:db8:85a3::]:80"
            ),
            (   // 2001:0db8:85a3:0000:0000:8a2e:0370:7334
                input:
                (
                    address:
                    (
                        __uint16_t(0x2001).toNetworkByteOrder,
                        __uint16_t(0x0db8).toNetworkByteOrder,
                        __uint16_t(0x85a3).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x8a2e).toNetworkByteOrder,
                        __uint16_t(0x0370).toNetworkByteOrder,
                        __uint16_t(0x7334).toNetworkByteOrder
                    ),
                    port: 80
                ),
                expected: "[2001:db8:85a3::8a2e:370:7334]:80"
            ),
            (   // 2001:0db8:0000:0000:85a3:0000:0000:7334
                input:
                (
                    address:
                    (
                        __uint16_t(0x2001).toNetworkByteOrder,
                        __uint16_t(0x0db8).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x85a3).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x7334).toNetworkByteOrder
                    ),
                    port: 80
                ),
                expected: "[2001:db8::85a3:0:0:7334]:80"
            ),
        ]
        
        for (input, expected) in testCases
        {
            let address = in6_addr(
                __u6_addr: in6_addr.__Unnamed_union___u6_addr.init(
                    __u6_addr16: input.address
                )
            )

            let sockAddress =
                SocketAddress(ip6Address: address, port: input.port)
            
            let actual = sockAddress.description
            XCTAssertEqual(actual, expected)
        }
    }
    
    // -------------------------------------
    func test_Unix_domain_SocketAddress_description_is_correct()
    {
        let testCases: [(input: String, expected: String)] =
        [
            (input: "1234",                   expected: "1234"),
            (input: "1234.socket",            expected: "1234.socket"),
            (input: "socket",                 expected: "socket"),
            (input: "server.socket",          expected: "server.socket"),
            (input: "/var/run/server.socket", expected: "/var/run/server.socket"),
            (input: "/run/server.socket",     expected: "/run/server.socket"),
            (input: "/var/tmp/1234",          expected: "/var/tmp/1234"),
            (input: "/var/tmp/1234.socket",   expected: "/var/tmp/1234.socket"),
        ]
        for (input, expected) in testCases
        {
            guard let unixPath = UnixSocketPath(input) else
            {
                XCTFail("Invalid Unix domain socket path: \"\(input)\"")
                continue
            }
            
            let sockAddress = SocketAddress(unixPath: unixPath)
            
            let actual = sockAddress.description
            XCTAssertEqual(actual, expected)
        }
    }
    
    // -------------------------------------
    func test_IP4_SocketAddress_initializes_from_IPv4_socket_address_description_string()
    {
        typealias AddressDescription = (address: in_addr_t, port: Int)
        let testCases: [(expected: AddressDescription, input: String)] =
        [
            (expected: (0x00000000,   22), input: "0.0.0.0:22"),
            (expected: (0x00000001,   80), input: "0.0.0.1:80"),
            (expected: (0x00000100, 4092), input: "0.0.1.0:4092"),
            (expected: (0x00010000,    1), input: "0.1.0.0:1"),
            (expected: (0x01000000,    5), input: "1.0.0.0:5"),
            (expected: (0x7F000001,   22), input: "127.0.0.1:22"),
            (expected: (0xFFFFFFFF,   22), input: "255.255.255.255:22"),
            (expected: (0x1F0110F1,   22), input: "31.1.16.241:22"),
        ]
        for (expectedInfo, input) in testCases
        {
            let address = in_addr(s_addr: expectedInfo.address.toNetworkByteOrder)
            
            let expected =
                SocketAddress(ip4Address: address, port: expectedInfo.port)
            
            let actual = SocketAddress(input)
            XCTAssertEqual(actual, expected)
        }
    }
    
    // -------------------------------------
    func test_IP6_SocketAddress_initializes_from_IPv6_socket_address_description_string()
    {
        typealias BinaryAddress = (
            __uint16_t, __uint16_t, __uint16_t, __uint16_t,
            __uint16_t, __uint16_t, __uint16_t, __uint16_t
        )
        typealias AddressDescription = (address: BinaryAddress, port: Int)
        let testCases: [(expected: AddressDescription, input: String)] =
        [
            (
                expected:
                (
                    address:
                    (
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder
                    ),
                    port: 2020
                ),
                input: "[::]:2020"
            ),
            (
                expected:
                (
                    address:
                    (
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0001).toNetworkByteOrder
                    ),
                    port: 2020
                ),
                input: "[::1]:2020"
            ),
            (   // 0000:0000:0000:0000:0000:0000:0000:0001
                expected:
                (
                    address:
                    (
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x1000).toNetworkByteOrder
                    ),
                    port: 2
                ),
                input: "[::1000]:2"
            ),
            (   // 0001:0000:0000:0000:0000:0000:0000:0000
                expected:
                (
                    address:
                    (
                        __uint16_t(0x0001).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder
                    ),
                    port: 80
                ),
                input: "[1::]:80"
            ),
            (   // 1000:0000:0000:0000:0000:0000:0000:0000
                expected:
                (
                    address:
                    (
                        __uint16_t(0x1000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder
                    ),
                    port: 10
                ),
                input: "[1000::]:10"
            ),
            (   // 0000:0000:0000:0000:0000:8a2e:0370:7334
                expected:
                (
                    address:
                    (
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x8a2e).toNetworkByteOrder,
                        __uint16_t(0x0370).toNetworkByteOrder,
                        __uint16_t(0x7334).toNetworkByteOrder
                    ),
                    port: 42
                ),
                input: "[::8a2e:370:7334]:42"
            ),
            (   // 2001:0db8:85a3:0000:0000:0000:0000:0000
                expected:
                (
                    address:
                    (
                        __uint16_t(0x2001).toNetworkByteOrder,
                        __uint16_t(0x0db8).toNetworkByteOrder,
                        __uint16_t(0x85a3).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder
                    ),
                    port: 80
                ),
                input: "[2001:db8:85a3::]:80"
            ),
            (   // 2001:0db8:85a3:0000:0000:8a2e:0370:7334
                expected:
                (
                    address:
                    (
                        __uint16_t(0x2001).toNetworkByteOrder,
                        __uint16_t(0x0db8).toNetworkByteOrder,
                        __uint16_t(0x85a3).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x8a2e).toNetworkByteOrder,
                        __uint16_t(0x0370).toNetworkByteOrder,
                        __uint16_t(0x7334).toNetworkByteOrder
                    ),
                    port: 80
                ),
                input: "[2001:db8:85a3::8a2e:370:7334]:80"
            ),
            (   // 2001:0db8:0000:0000:85a3:0000:0000:7334
                expected:
                (
                    address:
                    (
                        __uint16_t(0x2001).toNetworkByteOrder,
                        __uint16_t(0x0db8).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x85a3).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x0000).toNetworkByteOrder,
                        __uint16_t(0x7334).toNetworkByteOrder
                    ),
                    port: 80
                ),
                input: "[2001:db8::85a3:0:0:7334]:80"
            ),
        ]
        
        for (expectedInfo, input) in testCases
        {
            let address = in6_addr(
                __u6_addr: in6_addr.__Unnamed_union___u6_addr.init(
                    __u6_addr16: expectedInfo.address
                )
            )

            let expected =
                SocketAddress(ip6Address: address, port: expectedInfo.port)
            
            let actual = SocketAddress(input)
            XCTAssertEqual(actual, expected)
        }
    }
    
    // -------------------------------------
    func test_Unix_domain_SocketAddress_initializes_from_Unix_domain_socket_address_description_string()
    {
        let testCases: [(expected: String, input: String)] =
        [
            (expected: "1234",                   input: "1234"),
            (expected: "1234.socket",            input: "1234.socket"),
            (expected: "socket",                 input: "socket"),
            (expected: "server.socket",          input: "server.socket"),
            (expected: "/var/run/server.socket", input: "/var/run/server.socket"),
            (expected: "/run/server.socket",     input: "/run/server.socket"),
            (expected: "/var/tmp/1234",          input: "/var/tmp/1234"),
            (expected: "/var/tmp/1234.socket",   input: "/var/tmp/1234.socket"),
        ]
        for (expectedPath, input) in testCases
        {
            guard let unixPath = UnixSocketPath(expectedPath) else
            {
                XCTFail("Invalid Unix domain socket path: \"\(expectedPath)\"")
                continue
            }
            let expected = SocketAddress(unixPath: unixPath)
            
            let actual = SocketAddress(input)
            XCTAssertEqual(actual, expected)
        }
    }
}
