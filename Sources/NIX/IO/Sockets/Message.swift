//
//  MessageHeader.swift
//  
//
//  Created by Chip Jarred on 3/4/21.
//

import Foundation

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

// -------------------------------------
/**
 Swift-side proxy for `HostOS.msghdr`
 */
public struct Message
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
        controlMessages: [ControlMessage] = [],
        flags: MessageFlags = .none)
    {
        self.messageName = messageName
        self.messages = messages
        self.controlMessages = controlMessages
        self.flags = flags
    }
}

// -------------------------------------
internal extension Message
{
    // -------------------------------------
    @usableFromInline var controlMessageArrayBytes: Int {
        return controlMessages.reduce(0) { $0 + align_(Int($1.len)) }
    }
    
    // -------------------------------------
    func dataFromControlMessages() -> Data
    {
        let dataLen = controlMessageArrayBytes
        var data = Data(capacity: dataLen)
        for controlMessage in controlMessages {
            data.append(controlMessage.storage)
        }
        return data
    }
    
    // -------------------------------------
    mutating func dataToControlMessages(_ data: Data)
    {
        var data = data[...]
        for i in controlMessages.indices
        {
            guard let hdr = data.getControlMessageHeader() else
            {
                controlMessages[i].storage.resetBytes(in: 0...)
                continue
            }
            
            let messageSize = Int(hdr.cmsg_len)
            
            let _ = controlMessages[i].storage.withUnsafeMutableBytes
            { (ptr: UnsafeMutableRawBufferPointer) in
                data.copyBytes(to: ptr, count: messageSize)
            }
            controlMessages[i].storage.resetBytes(in: messageSize...)
            
            data = data.nextControlMessage() ?? data
        }
    }
    
    // -------------------------------------
    @usableFromInline
    func withMsgHdr<R>(
        _ block: (UnsafePointer<HostOS.msghdr>) throws -> R) rethrows -> R
    {
        let namePtr = messageName?.unsafeDataPointer()
        var iovecs = messages.iovecs()

        let controlMessageData = dataFromControlMessages()
        let ctrlPtr = controlMessageData.unsafeDataPointer()
        
        return try iovecs.withUnsafeMutableBufferPointer
        {
            let hdr = HostOS.msghdr(
                msg_name: namePtr,
                msg_namelen: socklen_t(messageName?.count ?? 0),
                msg_iov: $0.baseAddress,
                msg_iovlen: Int32($0.count),
                msg_control: ctrlPtr,
                msg_controllen: socklen_t(controlMessageData.count),
                msg_flags: flags.rawValue
            )
            
            return try withUnsafePointer(to: hdr) { return try block($0) }
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

        var controlMessageData = dataFromControlMessages()
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
            
            dataToControlMessages(controlMessageData)
            
            // if pointers in hdr have changed, we need to copy the new data
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
