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
public func inet_ntop<IPAddress: Address>(
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
                AF_INET6,
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
