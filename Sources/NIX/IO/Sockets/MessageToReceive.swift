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
public struct MessageToReceive: MessageProtocol
{
    /// optional address - specifies destination address if socket is unconnected
    public var messageName: Data? = nil
    
    /// scatter/gather array
    public var messages: [Data] = []
    
    /// ancillary data
    public var controlMessages: [ControlMessage] = []
    
    /// flags on received message
    public var flags: MessageFlags = .none
    
    // -------------------------------------
    public init(
        messageName: Data?,
        messages: [Data],
        flags: MessageFlags = .none)
    {
        self.messageName = messageName
        self.messages = messages
        self.controlMessages = []
        self.flags = flags
    }
}

// -------------------------------------
internal extension MessageToReceive
{
    // -------------------------------------
    mutating func scatterDataToControlMessages(_ data: Data)
    {
        assert(controlMessages.count == 0)
        assert(data.count == align(data.count))
        
        var data = data[...]
        while let hdr = data.getControlMessageHeader(),
              hdr.cmsg_len >= MemoryLayout<HostOS.cmsghdr>.size
        {
            let messageEnd = data.startIndex + Int(hdr.cmsg_len)
        
            controlMessages.append(ControlMessage(storage: data[..<messageEnd]))
            
            data = data.nextControlMessage() ?? data
        }
    }
    
    // -------------------------------------
    @usableFromInline
    mutating func withMutableMsgHdr<R>(
        _ block: (UnsafeMutablePointer<HostOS.msghdr>) throws -> R) rethrows
        -> R
    {
        let namePtr = messageName?.unsafeDataPointer()
        var iovecs = messages.iovecs()

        var controlMessageData = ControlMessageBufferCache.allocate()
        defer { ControlMessageBufferCache.deallocate(&controlMessageData) }
        
        let ctrlPtr = controlMessageData.unsafeMutableDataPointer()

        return try iovecs.withUnsafeMutableBufferPointer
        {
            let nameLen = socklen_t(messageName?.count ?? 0)
            
            var hdr = HostOS.msghdr(
                msg_name: namePtr,
                msg_namelen: nameLen,
                msg_iov: $0.baseAddress,
                msg_iovlen: Int32($0.count),
                msg_control: ctrlPtr,
                msg_controllen: socklen_t(controlMessageData.count),
                msg_flags: flags.rawValue
            )
            
            let result = try withUnsafeMutablePointer(to: &hdr) {
                return try block($0)
            }

            scatterDataToControlMessages(controlMessageData)
            
            // If pointers in hdr have changed, we need to copy the new data
            // I don't think this happens, but if it does, we need to handle it
            if Int(bitPattern: hdr.msg_name) != Int(bitPattern: namePtr)
            {
                self.messageName =
                    Data(bytes: hdr.msg_name, count: Int(hdr.msg_namelen))
            }
                        
            #if DEBUG
            /*
             I've defined all the flags that are stated on the man page for
             recvmsg; however, Darwin defines more.  So this check is to
             determine if they are used in user-land messages.  They might only
             be used internally.
             */
            if hdr.msg_flags & MessageFlags.all.rawValue != 0
            {
                print(
                    "\(#file):\(#line):\(#function):"
                    + "msg_flags contains unknown flag bits = "
                    + "\(hdr.msg_flags & MessageFlags.all.rawValue)"
                )
            }
            #endif
            
            self.flags = MessageFlags(rawValue: hdr.msg_flags)
            
            return result
        }
    }
}
