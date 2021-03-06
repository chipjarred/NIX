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

import Foundation

public protocol MessageProtocol { }

public extension MessageProtocol
{
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal func align<T: FixedWidthInteger>(_ value: T) -> T {
        return NIX.align32(value)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal func padAlign(_ data: inout Data) { data.pad32() }
}

// -------------------------------------
/**
 Swift-side proxy for `HostOS.msghdr` as used with `recvmsg`
 
 - Note: Attempts to send multiple `ControlMessage`s in testing on macOS have,
    so far, always resulted in an invalid argument error.  After doing some
    digging, [this discussion](https://tech.openbsd.narkive.com/w8dC35JD/multiple-cmsghdrs-in-msghdr)
    suggests that disallowing multiple control messages is intentional on some Unix variants, including macOS,
    because of security issues.
 
    Because of that, `NIX` defines different message structures for sending and
    receiving.   The `MessageToSend` is defined with just a an option
    `controlMessage` property, while `MessageToReceive` defines a
    `controlMessages` property that is an array.  In this way one can still
    receive multiple control messages, which may be inserted by the protocol,
    but only send a single control message..
 */
public struct MessageToSend: MessageProtocol
{
    /// optional address - specifies destination address if socket is unconnected
    public var name: SocketAddress? = nil
    
    /// scatter/gather array
    public var messages: [Data] = []
    
    /// ancillary data
    public var controlMessage: ControlMessage?
    
    // -------------------------------------
    public init(
        name: SocketAddress?,
        messages: [Data],
        controlMessage: ControlMessage? = nil)
    {
        self.name = name
        self.messages = messages
        self.controlMessage = controlMessage
    }
}

// -------------------------------------
internal extension MessageToSend
{
    // -------------------------------------
    func gatherDataFromControlMessages() -> Data?
    {
        guard var data = controlMessage?.storage else { return nil }
        padAlign(&data)
        return data
    }
    
    // -------------------------------------
    @usableFromInline
    func withMsgHdr<R>(
        _ block: (UnsafePointer<HostOS.msghdr>) throws -> R) rethrows -> R
    {
        var iovecs = messages.iovecs()

        let controlMessageData = gatherDataFromControlMessages()
        let ctrlPtr = controlMessageData?.unsafeDataPointer()
        
        var name = self.name
        return try withUnsafeMutableBytes(of: &name)
        { namePtr in
            return try iovecs.withUnsafeMutableBufferPointer
            {
                let hdr = HostOS.msghdr(
                    msg_name: namePtr.baseAddress,
                    msg_namelen: socklen_t(namePtr.count),
                    msg_iov: $0.baseAddress,
                    msg_iovlen: Int32($0.count),
                    msg_control: ctrlPtr,
                    msg_controllen: socklen_t(controlMessageData?.count ?? 0),
                    msg_flags: 0
                )
                
                return try withUnsafePointer(to: hdr) { return try block($0) }
            }
        }
    }
}
