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

import HostOS

public struct MessageFlags: NIXFlags
{
    public typealias RawValue = Int32
    
    public internal(set) var rawValue: RawValue
    
    /// Data completes record
    public static let endOfRecord = Self(rawValue: HostOS.MSG_EOR)
    
    /**
     Data discarded before delivery
     
     Indicates that the trailing portion of a datagram was discarded because
     the datagram was larger than the buffer supplied.
     */
    public static let messageTruncated = Self(rawValue: HostOS.MSG_TRUNC)
    
    /**
     Control data lost before delivery
     
     Indicates that some control data were discarded due to lack of space in
     the buffer for ancillary data.
     */
    public static let controlDataTruncated = Self(rawValue: HostOS.MSG_CTRUNC)
    
    /**
     Out-of-band data
     
     Indicates that expedited or out-of-band data were received.
     */
    public static let outOfBand = Self(rawValue: HostOS.MSG_OOB)
    
    public static var all: MessageFlags = Self(
        [
            .endOfRecord,
            .messageTruncated,
            .controlDataTruncated,
            outOfBand,
        ]
    )

    // -------------------------------------
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}
