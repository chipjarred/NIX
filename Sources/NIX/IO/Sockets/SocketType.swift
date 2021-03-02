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
public enum SocketType: Int32
{
    /// Stream socket
    case stream
    
    /// Datagram socket
    case datagram
    
    /// Raw-protocol socket
    case raw
    
    /// Reliably Delivered Message scoket
    case reliablyDeliveredMessage
    
    /// Sequenced packet stream socket
    case sequencedPacketStream
    
    // -------------------------------------
    public init?(rawValue: Int32)
    {
        switch rawValue
        {
            case HostOS.SOCK_STREAM    : self = .stream
            case HostOS.SOCK_DGRAM     : self = .datagram
            case HostOS.SOCK_RAW       : self = .raw
            case HostOS.SOCK_RDM       : self = .reliablyDeliveredMessage
            case HostOS.SOCK_SEQPACKET : self = .sequencedPacketStream
                
            default: return nil
        }
    }
    
    // -------------------------------------
    public var rawValue: Int32
    {
        switch self
        {
            case .stream                   : return HostOS.SOCK_STREAM
            case .datagram                 : return HostOS.SOCK_DGRAM
            case .raw                      : return HostOS.SOCK_RAW
            case .reliablyDeliveredMessage : return HostOS.SOCK_RDM
            case .sequencedPacketStream    : return HostOS.SOCK_SEQPACKET
        }
    }
}
