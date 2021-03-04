import XCTest
@testable import NIX

// -------------------------------------
class HostOSAddress_UnitTests: XCTestCase
{
    static var allTests =
    [
        ("test_IP4_description_is_correct", test_IP4_description_is_correct),
        ("test_IP6_description_is_correct", test_IP6_description_is_correct),
        ("test_IP4_address_can_be_initialized_from_a_string_description", test_IP4_address_can_be_initialized_from_a_string_description),
        ("test_IP6_address_can_be_initialized_from_a_string_description", test_IP6_address_can_be_initialized_from_a_string_description),
        ("test_IP4_address_fails_to_initialize_from_an_invalid_string_description", test_IP4_address_fails_to_initialize_from_an_invalid_string_description),
        ("test_IP6_address_fails_to_initialize_from_an_invalid_string_description", test_IP6_address_fails_to_initialize_from_an_invalid_string_description),
    ]
    
    // -------------------------------------
    func test_IP4_description_is_correct()
    {
        let testCases: [(input: in_addr_t, expected: String)] =
        [
            (input: 0x00000000, expected: "0.0.0.0"),
            (input: 0x00000001, expected: "0.0.0.1"),
            (input: 0x00000100, expected: "0.0.1.0"),
            (input: 0x00010000, expected: "0.1.0.0"),
            (input: 0x01000000, expected: "1.0.0.0"),
            (input: 0x7F000001, expected: "127.0.0.1"),
            (input: 0xFFFFFFFF, expected: "255.255.255.255"),
            (input: 0x1F0110F1, expected: "31.1.16.241"),
        ]
        for (input, expected) in testCases
        {
            let address = in_addr(s_addr: input.toNetworkByteOrder)
            
            let actual = address.description
            XCTAssertEqual(actual, expected)
        }
    }
    
    // -------------------------------------
    func test_IP6_description_is_correct()
    {
        typealias BinaryAddress = (
            __uint16_t, __uint16_t, __uint16_t, __uint16_t,
            __uint16_t, __uint16_t, __uint16_t, __uint16_t
        )
        
        // IPv6 addresses are compressed when rendered in string format
        // So ensure that rules about leading zeros and zero fields are
        // followed.
        let testCases: [(input:BinaryAddress, expected: String)] =
        [
            (   // 0000:0000:0000:0000:0000:0000:0000:0000
                input: (
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder
                ),
                expected: "::"
            ),
            (   // 0000:0000:0000:0000:0000:0000:0000:0001
                input: (
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0001).toNetworkByteOrder
                ),
                expected: "::1"
            ),
            (   // 0000:0000:0000:0000:0000:0000:0000:0001
                input: (
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x1000).toNetworkByteOrder
                ),
                expected: "::1000"
            ),
            (   // 0001:0000:0000:0000:0000:0000:0000:0000
                input: (
                    __uint16_t(0x0001).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder
                ),
                expected: "1::"
            ),
            (   // 1000:0000:0000:0000:0000:0000:0000:0000
                input: (
                    __uint16_t(0x1000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder
                ),
                expected: "1000::"
            ),
            (   // 0000:0000:0000:0000:0000:8a2e:0370:7334
                input: (
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x8a2e).toNetworkByteOrder,
                    __uint16_t(0x0370).toNetworkByteOrder,
                    __uint16_t(0x7334).toNetworkByteOrder
                ),
                expected: "::8a2e:370:7334"
            ),
            (   // 2001:0db8:85a3:0000:0000:0000:0000:0000
                input: (
                    __uint16_t(0x2001).toNetworkByteOrder,
                    __uint16_t(0x0db8).toNetworkByteOrder,
                    __uint16_t(0x85a3).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder
                ),
                expected: "2001:db8:85a3::"
            ),
            (   // 2001:0db8:85a3:0000:0000:8a2e:0370:7334
                input: (
                    __uint16_t(0x2001).toNetworkByteOrder,
                    __uint16_t(0x0db8).toNetworkByteOrder,
                    __uint16_t(0x85a3).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x8a2e).toNetworkByteOrder,
                    __uint16_t(0x0370).toNetworkByteOrder,
                    __uint16_t(0x7334).toNetworkByteOrder
                ),
                expected: "2001:db8:85a3::8a2e:370:7334"
            ),
            (   // 2001:0db8:0000:0000:85a3:0000:0000:7334
                input: (
                    __uint16_t(0x2001).toNetworkByteOrder,
                    __uint16_t(0x0db8).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x85a3).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x7334).toNetworkByteOrder
                ),
                expected: "2001:db8::85a3:0:0:7334"
            ),
        ]
        
        for (input, expected) in testCases
        {
            let address = in6_addr(
                __u6_addr: in6_addr.__Unnamed_union___u6_addr.init(
                    __u6_addr16: input
                )
            )
            
            let actual = address.description
            XCTAssertEqual(actual, expected)
        }
    }
    
    // -------------------------------------
    func test_IP4_address_can_be_initialized_from_a_string_description()
    {
        let testCases: [(expected: in_addr_t, input: String)] =
        [
            (expected: 0x00000000, input: "0.0.0.0"),
            (expected: 0x00000001, input: "0.0.0.1"),
            (expected: 0x00000100, input: "0.0.1.0"),
            (expected: 0x00010000, input: "0.1.0.0"),
            (expected: 0x01000000, input: "1.0.0.0"),
            (expected: 0x7F000001, input: "127.0.0.1"),
            (expected: 0xFFFFFFFF, input: "255.255.255.255"),
            (expected: 0x1F0110F1, input: "31.1.16.241"),
        ]
        for (expected, input) in testCases
        {
            guard let actual = in_addr(address: input) else
            {
                XCTFail("Failed to initialize address from \"input\"")
                continue
            }
            XCTAssertEqual(actual.s_addr.toHostByteOrder, expected)
        }
    }
    
    // -------------------------------------
    func test_IP6_address_can_be_initialized_from_a_string_description()
    {
        typealias BinaryAddress = (
            __uint16_t, __uint16_t, __uint16_t, __uint16_t,
            __uint16_t, __uint16_t, __uint16_t, __uint16_t
        )
        
        // IPv6 addresses are compressed when rendered in string format
        // So ensure that rules about leading zeros and zero fields are
        // followed.
        let testCases: [(expected:BinaryAddress, input: String)] =
        [
            (   // 0000:0000:0000:0000:0000:0000:0000:0000
                expected: (
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder
                ),
                input: "0000:0000:0000:0000:0000:0000:0000:0000"
            ),
            (   // 0000:0000:0000:0000:0000:0000:0000:0000
                expected: (
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder
                ),
                input: "::"
            ),
            (   // 0000:0000:0000:0000:0000:0000:0000:0001
                expected: (
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0001).toNetworkByteOrder
                ),
                input: "0000:0000:0000:0000:0000:0000:0000:0001"
            ),
            (   // 0000:0000:0000:0000:0000:0000:0000:0001
                expected: (
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0001).toNetworkByteOrder
                ),
                input: "::1"
            ),
            (   // 0000:0000:0000:0000:0000:0000:0000:0001
                expected: (
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x1000).toNetworkByteOrder
                ),
                input: "::1000"
            ),
            (   // 0001:0000:0000:0000:0000:0000:0000:0000
                expected: (
                    __uint16_t(0x0001).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder
                ),
                input: "1::"
            ),
            (   // 1000:0000:0000:0000:0000:0000:0000:0000
                expected: (
                    __uint16_t(0x1000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder
                ),
                input: "1000::"
            ),
            (   // 0000:0000:0000:0000:0000:8a2e:0370:7334
                expected: (
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x8a2e).toNetworkByteOrder,
                    __uint16_t(0x0370).toNetworkByteOrder,
                    __uint16_t(0x7334).toNetworkByteOrder
                ),
                input: "::8a2e:370:7334"
            ),
            (   // 2001:0db8:85a3:0000:0000:0000:0000:0000
                expected: (
                    __uint16_t(0x2001).toNetworkByteOrder,
                    __uint16_t(0x0db8).toNetworkByteOrder,
                    __uint16_t(0x85a3).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder
                ),
                input: "2001:0db8:85a3:0000:0000:0000:0000:0000"
            ),
            (   // 2001:0db8:85a3:0000:0000:0000:0000:0000
                expected: (
                    __uint16_t(0x2001).toNetworkByteOrder,
                    __uint16_t(0x0db8).toNetworkByteOrder,
                    __uint16_t(0x85a3).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder
                ),
                input: "2001:db8:85a3::"
            ),
            (   // 2001:0db8:85a3:0000:0000:8a2e:0370:7334
                expected: (
                    __uint16_t(0x2001).toNetworkByteOrder,
                    __uint16_t(0x0db8).toNetworkByteOrder,
                    __uint16_t(0x85a3).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x8a2e).toNetworkByteOrder,
                    __uint16_t(0x0370).toNetworkByteOrder,
                    __uint16_t(0x7334).toNetworkByteOrder
                ),
                input: "2001:db8:85a3::8a2e:370:7334"
            ),
            (   // 2001:0db8:0000:0000:85a3:0000:0000:7334
                expected: (
                    __uint16_t(0x2001).toNetworkByteOrder,
                    __uint16_t(0x0db8).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x85a3).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x0000).toNetworkByteOrder,
                    __uint16_t(0x7334).toNetworkByteOrder
                ),
                input: "2001:db8::85a3:0:0:7334"
            ),
        ]
        for (expected16, input) in testCases
        {
            guard let actual = in6_addr(address: input) else
            {
                XCTFail("Failed to initialize address from \"input\"")
                continue
            }
            let expected = in6_addr(
                __u6_addr: in6_addr.__Unnamed_union___u6_addr(
                    __u6_addr16: expected16
                )
            )
            XCTAssertEqual(actual, expected)
        }
    }
    
    // -------------------------------------
    func test_IP4_address_fails_to_initialize_from_an_invalid_string_description()
    {
        let testCases: [String] =
        [
            "",
            "0",
            "0.0",
            "0.0.0",
            "192",
            "192.168",
            "192.168.42",
            "0.0.0.0.0",
            "0.0.0.f",
            "0.0.a.0",
            "0.c.0.0",
            "e.0.0.0",
            "256.255.255.255",
            "255.256.255.255",
            "255.255.256.255",
            "255.255.255.256",
            "31.1.16.241.42",
            "some-site.org",
        ]
        for input in testCases
        {
            let actual = in_addr(address: input)
            XCTAssertNil(actual)
        }
    }
    
    // -------------------------------------
    func test_IP6_address_fails_to_initialize_from_an_invalid_string_description()
    {
        let testCases: [String] =
        [
            "",
            ":",
            ":1",
            "1:",
            "0:0",
            "0:0:",
            "0:0:0",
            "0:0:0:",
            "0:0:0:0",
            "0:0:0:0:",
            "0:0:0:0:0",
            "0:0:0:0:0:0",
            "0:0:0:0:0:0:",
            "0:0:0:0:0:0:0",
            "0:0:0:0:0:0:0:",
            "0:0:0:0:0:0:0:0:",
            "0:0:0:0:0:0:0:0:0",
            "10000::",
            "::10000",
            "fa:10000::",
            "::10000:5",
            "some-site.org",
        ]
        for input in testCases
        {
            let actual = in6_addr(address: input)
            XCTAssertNil(actual)
        }
    }
}
