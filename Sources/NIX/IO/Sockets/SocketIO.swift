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
import Foundation

public protocol SocketIODescriptor: IODescriptor { }

// -------------------------------------
public struct SocketDescriptor: SocketIODescriptor
{
    public let descriptor: Int32
    
    @usableFromInline
    internal init(_ sd: Int32)
    {
        assert(sd > 0)
        self.descriptor = sd
    }
}

// MARK:- Socket I/O
// -------------------------------------
/**
 Create an endpoint for communication and returns a descriptor.

 - Parameters:
    - domain: specifies a communications domain within which communication will
        take place; this selects the protocol family which should be used.
        These families are defined in the include file <sys/socket.h>. The
        currently understood formats are
         - `.local`: Host-internal protocols, formerly called `.unix`
         - `.unix`: Host-internal protocols, deprecated, use `.local`
         - `.inet4`: Internet version 4 protocols
         - `.route`: Internal Routing protocol
         - `.key`: Internal key-management function
         - `.inet6`: Internet version 6 protocols
         - `.system`: System domain
         - `.rawNetworkDevice`: Raw access to network device
 
    - socketType: specifies the semantics of communication.  Currently defined
            types are:
         - `.stream`: provides sequenced, reliable, two-way connection based
                byte streams.  An out-of-band data transmission mechanism may
                be supported.
         - `.datagram`: supports datagrams (connectionless, unreliable messages
                of a fixed, typically small, maximum length).
         - `.raw`: provide access to internal network protocols and interfaces.
                The type `.raw`, which is available only to the super-user.
 
    - protocol: specifies a particular protocol to be used with the socket.
        Normally only a single protocol exists to support a particular socket
        type within a given protocol family.  However, it is possible that many
        protocols may exist, in which case a particular protocol must be
        specified in this manner.  The protocol number to use is particular to
        the communication domain in which communication is to take place.
 
 Sockets of type `.stream` are full-duplex byte streams, similar to
 pipes.  A stream socket must be in a connected state before any data may
 be sent or received on it.  A connection to another socket is created
 with a `connect` or `connectx` call.  Once connected, data may be
 transferred using `read` and `write` calls or some variant of the
 `send` and `recv` calls.  When a session has been completed a `close`
 may be performed.  Out-of-band data may also be transmitted as described
 in `send` and received as described in `recv`.
 
 The communications protocols used to implement a `.stream` insure that
 data is not lost or duplicated.  If a piece of data for which the peer
 protocol has buffer space cannot be successfully transmitted within a
 reasonable length of time, then the connection is considered broken and
 calls will return an `Error` containing `ETIMEDOUT` as the specific error code.
 The protocols optionally keep sockets "warm" by forcing transmissions roughly
 every minute in the absence of other activity.  An error is then indicated if
 no response can be elicited on an otherwise idle connection for a extended
 period (e.g. 5 minutes).
 
 `.datagram` and `.raw` sockets allow sending of datagrams to correspondents
 named in `send` calls.  Datagrams are generally received with `recvfrom`,
 which returns the next datagram with its return address.
 
 An `fcntl` call can be used to specify a process group to receive a
 `SIGURG` signal when the out-of-band data arrives.  It may also enable non-
 blocking I/O and asynchronous notification of I/O events via `SIGIO`.
 
 The operation of sockets is controlled by socket level options.  `setsockopt`
 and `getsockopt` are used to set and get options, respectively.

 - Note: A `SIGPIPE` signal is raised if a process sends on a broken stream;
    this causes naive processes, which do not handle the signal, to exit.
 
 - Returns: On success, the returned `Result` contains the created socket.  On
    failure, it contains the `Error` describing the reason for the failure.
 */
@inlinable
public func socket(
    _ domain: SocketDomain,
    _ socketType: SocketType,
    _ protocol: ProtocolFamily) -> Result<SocketIODescriptor, Error>
{
    let result = HostOS.socket(
        domain.rawValue,
        socketType.rawValue,
        `protocol`.rawValue
    )
    
    return result == -1
        ? .failure(Error())
        : .success(SocketDescriptor(result))
}

// -------------------------------------
/**
 Create an unnamed pair of connected sockets in the specified domain domain, of
 the specified type, and using the optionally specified protocol. The two
 sockets are indistinguishable.

 - Parameters:
    - domain: specifies a communications domain within which communication will
        take place; this selects the protocol family which should be used.
        These families are defined in the include file <sys/socket.h>. The
        currently understood formats are
         - `.local`: Host-internal protocols, formerly called `.unix`
         - `.unix`: Host-internal protocols, deprecated, use `.local`
         - `.inet4`: Internet version 4 protocols
         - `.route`: Internal Routing protocol
         - `.key`: Internal key-management function
         - `.inet6`: Internet version 6 protocols
         - `.system`: System domain
         - `.rawNetworkDevice`: Raw access to network device
 
    - socketType: specifies the semantics of communication.  Currently defined
            types are:
         - `.stream`: provides sequenced, reliable, two-way connection based
                byte streams.  An out-of-band data transmission mechanism may
                be supported.
         - `.datagram`: supports datagrams (connectionless, unreliable messages
                of a fixed, typically small, maximum length).
         - `.raw`: provide access to internal network protocols and interfaces.
                The type `.raw`, which is available only to the super-user.
 
    - protocol: specifies a particular protocol to be used with the socket.
        Normally only a single protocol exists to support a particular socket
        type within a given protocol family.  However, it is possible that many
        protocols may exist, in which case a particular protocol must be
        specified in this manner.  The protocol number to use is particular to
        the communication domain in which communication is to take place.
 
 Sockets of type `.stream` are full-duplex byte streams, similar to
 pipes.  A stream socket must be in a connected state before any data may
 be sent or received on it.  A connection to another socket is created
 with a `connect` or `connectx` call.  Once connected, data may be
 transferred using `read` and `write` calls or some variant of the
 `send` and `recv` calls.  When a session has been completed a `close`
 may be performed.  Out-of-band data may also be transmitted as described
 in `send` and received as described in `recv`.
 
 The communications protocols used to implement a `.stream` insure that
 data is not lost or duplicated.  If a piece of data for which the peer
 protocol has buffer space cannot be successfully transmitted within a
 reasonable length of time, then the connection is considered broken and
 calls will return an `Error` containing `ETIMEDOUT` as the specific error code.
 The protocols optionally keep sockets "warm" by forcing transmissions roughly
 every minute in the absence of other activity.  An error is then indicated if
 no response can be elicited on an otherwise idle connection for a extended
 period (e.g. 5 minutes).
 
 `.datagram` and `.raw` sockets allow sending of datagrams to correspondents
 named in `send` calls.  Datagrams are generally received with `recvfrom`,
 which returns the next datagram with its return address.
 
 An `fcntl` call can be used to specify a process group to receive a
 `SIGURG` signal when the out-of-band data arrives.  It may also enable non-
 blocking I/O and asynchronous notification of I/O events via `SIGIO`.
 
 The operation of sockets is controlled by socket level options.  `setsockopt`
 and `getsockopt` are used to set and get options, respectively.

 - Note: A `SIGPIPE` signal is raised if a process sends on a broken stream;
    this causes naive processes, which do not handle the signal, to exit.
 
 - Returns: On success, the returned `Result` contains the a tuple of the two
    newly created sockets.  On failure, it contains the `Error` describing the
    reason for the failure.
 */
@inlinable
public func socketpair(
    _ domain: SocketDomain,
    _ socketType: SocketType,
    _ protocol: ProtocolFamily)
    -> Result<(SocketIODescriptor, SocketIODescriptor), Error>
{
    var pair = (CInt(), CInt())
    let result = withUnsafeMutableBytes(of: &pair)
    { pairPtr in
        return HostOS.socketpair(
            domain.rawValue,
            socketType.rawValue,
            `protocol`.rawValue,
            pairPtr.baseAddress!.bindMemory(to: CInt.self, capacity: 2)
        )
    }
    
    return result == -1
        ? .failure(Error())
        : .success((SocketDescriptor(pair.0), SocketDescriptor(pair.1)))
}

// -------------------------------------
public enum SetSocketOptions
{
    case reuseAddress(_ value: Bool)
    case reusePort(_ value: Bool)
    case ipV6Only(_ value: Bool)
}

// -------------------------------------
public enum GetSocketOptions
{
    case reuseAddress
    case reusePort
    case ipV6Only
}

// -------------------------------------
@usableFromInline
internal func setsockopt(
    _ socket: SocketIODescriptor,
    _ level: CInt,
    _ option: CInt,
    _ value: Bool) -> Error?
{
    var value: CInt = value ? 1 : 0
    let result = HostOS.setsockopt(
        socket.descriptor,
        SOL_SOCKET,
        option,
        &value,
        socklen_t(MemoryLayout<CInt>.size)
    )
    return result == 0 ? nil : Error()
}

// -------------------------------------
public func setsockopt(
    _ socket: SocketIODescriptor,
    _ optionValue: SetSocketOptions) -> Error?
{
    switch optionValue
    {
        case .reuseAddress(let value):
            return NIX.setsockopt(socket, SOL_SOCKET, SO_REUSEADDR, value)
        case .reusePort(let value):
            return NIX.setsockopt(socket, SOL_SOCKET, SO_REUSEPORT, value)
        case .ipV6Only(let value):
            return NIX.setsockopt(socket, IPPROTO_IPV6, IPV6_V6ONLY, value)
    }
}

// -------------------------------------
internal func getsockoptBool(
    _ socket: SocketIODescriptor,
    _ level: CInt,
    _ option: CInt) -> Result<Bool, Error>
{
    var value: CInt = 0
    var valueLen = socklen_t(MemoryLayout<CInt>.size)
    let r = HostOS.getsockopt(
        socket.descriptor,
        level,
        option,
        &value,
        &valueLen
    )
    return r == 0 ? .success(value != 0) : .failure(Error())
}

// -------------------------------------
public func getsockopt(
    _ socket: SocketIODescriptor,
    _ option: GetSocketOptions) -> Result<SetSocketOptions, Error>
{
    switch option
    {
        case .reuseAddress:
            switch NIX.getsockoptBool(socket, SOL_SOCKET, SO_REUSEADDR)
            {
                case .success(let b): return .success(.reuseAddress(b))
                case .failure(let e): return .failure(e)
            }
        case .reusePort:
            switch NIX.getsockoptBool(socket, SOL_SOCKET, SO_REUSEPORT)
            {
                case .success(let b): return .success(.reusePort(b))
                case .failure(let e): return .failure(e)
            }
        case .ipV6Only:
            switch NIX.getsockoptBool(socket, IPPROTO_IPV6, IPV6_V6ONLY)
            {
                case .success(let b): return .success(.reusePort(b))
                case .failure(let e): return .failure(e)
            }
    }
}

// -------------------------------------
/**
 Assign a name to an unnamed socket.
 
 When a socket is created with `socket` it exists in a name space (address
 family) but has no name assigned.  `bind()` requests that address be assigned
 to the socket.
 
 The rules used in name binding vary between communication domains.  Consult
 the manual entries in section 4 for detailed information.

 - Note: Binding a name in the `.unix` domain creates a socket in the file
    system that must be deleted by the caller when it is no longer needed
    (using `unlink`).
 - Note: "Assign a name" is POSIX-speak for associating the socket with an
    address.
 
 - Parameters:
    - socket: The socket to be bound
    - address: The address to bind to `socket`
 
 - Returns: On success, `nil` is returned.  On failure, an `Error`

 */
@inlinable
public func bind(
    _ socket: SocketIODescriptor,
    _ address: SocketAddress) -> Error?
{
    return address.withGenericPointer
    {
        let result = HostOS.bind(
            socket.descriptor,
            $0,
            address.len
        )
        return result == -1 ? Error() : nil
    }
}

// -------------------------------------
/**
 Make a socket ready for incoming connections.
 
 Creation of socket-based connections requires several operations.  First, a
 socket is created with `socket`.  Next, a willingness to accept incoming
 connections and a queue limit for incoming connections are specified with
 `listen()`.  Finally, the connections are accepted with `accept`.
 
 - Note:  The `listen` call applies only to sockets of type `.stream`.

 - Parameters:
    - socket: The socket to be made ready for incoming connections.
    - backlog:The maximum length for the queue of pending connections.  If a
        connection request arrives with the queue full, the client may receive
        an error with an indication of `ECONNREFUSED`.  Alterna tively, if the
        underlying protocol supports retransmission, the request may be ignored
        so that retries may succeed.
 
 - Returns: On success, `nil` is returned.  On failure, the `Error` describing
    the reason for the failure.
 */
@inlinable
public func listen(
    _ socket: SocketIODescriptor,
    _ backlog: Int) -> Error?
{
    let result = HostOS.listen(socket.descriptor, Int32(backlog))

    return result == -1 ? Error() : nil
}

// -------------------------------------
/**
 Accept an incoming socket connection.
 
 `accept()` extracts the first connection request on the queue of pending
 connections, creates a new socket with the same properties of socket, and
 *allocates a new file descriptor* for the socket.
 
 If no pending connections are present on the queue, and the socket is not
 marked as non-blocking, `accept()` blocks the caller until a connection is
 present. If the socket is marked non-blocking and no pending connections are
 present on the queue, `accept()` returns an error as described below.  The
 accepted socket may not be used to accept more connections.  The original
 socket socket, remains open.

 This call is used with connection-based socket types, currently with `.stream`.

 It is possible to `select` a socket for the purposes of doing an `accept` by
 selecting it for read.

 For certain protocols which require an explicit confirmation, such as `.iso`
 or `.datakit`, `accept()` can be thought of as merely dequeuing the next
 connection request and not implying confirmation.  Confirmation can be implied
 by a normal `read` or `write` on the new file descriptor, and rejection can be
 implied by closing the new socket.

 One can obtain user connection request data without confirming the connection
 by issuing a `recvmsg` call with an `msg_iovlen` of `0` and a nonzero
 `msg_controllen`, or by issuing a `getsockopt` request.  Similarly, one can
 provide user connection rejection information by issuing a `sendmsg` call
 providing only the control information, or by calling `setsockopt`.

 - Parameters:
    - socket: a socket that has been created with the `socket` function, bound
        to an address via the `bind` function and is set for listening via the
        `listen` function.
    - address: an `inout` parameter that is filled in with the address of the
        peer (client) connecting to `socket`, as known to the communications
        layer.  The exact format of the address parameter is determined by the
        domain in which the communication is occurring.
 
 - Returns: On success, the returned `Result` will contain the accepted peer
    socket that can be used for sending and receiving.  On failure, it will
    contain the `Error` describing the reason for the failure.
 */
@inlinable
public func accept(
    _ socket: SocketIODescriptor,
    _ remoteAddress: inout SocketAddress)
        -> Result<SocketDescriptor, Error>
{
    return remoteAddress.withMutableGenericPointer
    {
        var outSize = UInt32(MemoryLayout<SocketAddress>.size)
        let result = HostOS.accept(
            socket.descriptor,
            $0,
            &outSize
        )
        
        if result == -1 { return .failure(Error()) }
        
        $0.pointee.sa_len = __uint8_t(outSize)
        return .success(SocketDescriptor(result))
    }
}

// -------------------------------------
/**
 Accept an incoming socket connection.
 
 `accept()` extracts the first connection request on the queue of pending
 connections, creates a new socket with the same properties of socket, and
 *allocates a new file descriptor* for the socket.
 
 If no pending connections are present on the queue, and the socket is not
 marked as non-blocking, `accept()` blocks the caller until a connection is
 present. If the socket is marked non-blocking and no pending connections are
 present on the queue, `accept()` returns an error as described below.  The
 accepted socket may not be used to accept more connections.  The original
 socket socket, remains open.

 This call is used with connection-based socket types, currently with `.stream`.

 It is possible to `select` a socket for the purposes of doing an `accept` by
 selecting it for read.

 For certain protocols which require an explicit confirmation, such as `.iso`
 or `.datakit`, `accept()` can be thought of as merely dequeuing the next
 connection request and not implying confirmation.  Confirmation can be implied
 by a normal `read` or `write` on the new file descriptor, and rejection can be
 implied by closing the new socket.

 One can obtain user connection request data without confirming the connection
 by issuing a `recvmsg` call with an `msg_iovlen` of `0` and a nonzero
 `msg_controllen`, or by issuing a `getsockopt` request.  Similarly, one can
 provide user connection rejection information by issuing a `sendmsg` call
 providing only the control information, or by calling `setsockopt`.

 - Parameters:
    - socket: a socket that has been created with the `socket` function, bound
        to an address via the `bind` function and is set for listening via the
        `listen` function.
 
 - Returns: On success, the returned `Result` will contain the accepted peer
    socket that can be used for sending and receiving.  On failure, it will
    contain the `Error` describing the reason for the failure.
 */
@inlinable
public func accept(_ socket: SocketIODescriptor)
        -> Result<SocketDescriptor, Error>
{
    var dummyAddress = SocketAddress()
    return accept(socket, &dummyAddress)
}

// -------------------------------------
/**
 Connect to a listening/waiting socket.
 
 If `socket` type `.datagram`, this call specifies the peer with which the
 socket is to be associated; this address is that to which datagrams are to be
 sent, and the only address from which datagrams are to be received.
 
 If the socket is of type `.stream`, this call attempts to make a connection to
 another socket. The remote socket is specified by address, which is an address
 in the communications space of the socket.
 
 Each communications space interprets the address parameter in its own
 way.  Generally, `.stream` sockets may successfully `connect` only once;
 `.datagram` sockets may use `connect` multiple times to change their
 association.  Datagram sockets may dissolve the association by calling
 `disconnectx`, or by connecting to an invalid address, such as a null
 address or an address with the address family set to .unspecified (the error
 `EAFNOSUPPORT` will be harmlessly returned).

 - Parameters:
    - socket: The socket to connect to a remote listening socket.
    - remoteAddress: the address of the remote peer with which the socket is
        to be associated
 
 - Returns: On success, `nil` is returned.  On failure, it contains the `Error`
    describing the reason for the failure.
 */
@inlinable
public func connect(
    _ socket: SocketIODescriptor,
    _ remoteAddress: SocketAddress) -> Error?
{
    remoteAddress.withGenericPointer
    {
        let result = connect(
            socket.descriptor,
            $0,
            remoteAddress.len
        )
        return result == -1
            ? Error()
            : nil
    }
}

// -------------------------------------
/**
 Receive data from a connected or accepted socket.
 
 Stores the data in `buffer` over-writing any data in it.  The intention
 is to allow re-using an existing buffer for multiple I/O calls rather than
 repeatedly allocating them.  It is the caller's responsibilty to copy the
 data elsewhere if needed.
 
 - Parameters:
    - socket: A previously connected or accepted `SocketIODescriptor` to
        receive data from.
    - buffer: A `Data` buffer into which to receive the data.  On entry,
        `buffer.count` will determine the maximum number of bytes that can
        be read.  The buffer's `.count` is not modified.  The caller should
        use the returned number of bytes read to determine how many bytes of
        `buffer` contain the received data.
    - flags: `RecvFlags` specifying non-default reception behavior. Valid
         `flags` are
         - `.outOfBand`: Process out-of-band data
         - `.peek`: Peek at incoming message
         - `.waitAll`: Wait for full request or error
 
 - Returns: a `Result` which on success contains the number of bytes
    received, and on failure contains the error.
 */
@inlinable
public func recv(
    _ socket: SocketIODescriptor,
    _ buffer: inout Data,
    _ flags: RecvFlags = .none) -> Result<Int, Error>
{
    assert(buffer.count > 0)
    
    return buffer.withUnsafeMutableBytes
    {
        let bytesRead = recv(
            socket.descriptor,
            $0.baseAddress!,
            $0.count,
            flags.rawValue
        )
        return bytesRead == -1
            ? .failure(Error())
            : .success(bytesRead)
    }
}

// -------------------------------------
/**
 Receive data from a connected or accepted socket, obtaining the address of the
 sending socket.
 
 Stores the data in `buffer` over-writing any data in it.  The intention
 is to allow re-using an existing buffer for multiple I/O calls rather than
 repeatedly allocating them.  It is the caller's responsibilty to copy the
 data elsewhere if needed.
 
 - Important: For Unix domain *datagram* communication, if the sender did not
    `bind` to its own Unix domain socket address, when the receiver calls
    `recvfrom`, the `remoteAddress` will not be valid for a later `sendto`.
    This is because the sender was implicitly using a transiently bound address
    that was invalidated immediately after the send.  In such situations, if
    the sender expects a reply, it must `bind` before sending, and not `unlink`
    the associated path until the communication is finished.
 
    This is not a problem for Unix domain *stream* sockets nor for network
    sockets.
 
 - Parameters:
    - socket: A previously connected or accepted `SocketIODescriptor` to
        receive data from.
     - buffer: A `Data` buffer into which to receive the data.  On entry,
         `buffer.count` will determine the maximum number of bytes that can
         be read.  The buffer's `.count` is not modified.  The caller should
         use the returned number of bytes read to determine how many bytes of
         `buffer` contain the received data.
    - flags: `RecvFlags` specifying non-default reception behavior.  Valid
        `flags` are
        - `.outOfBand`: Process out-of-band data
        - `.peek`: Peek at incoming message
        - `.waitAll`: Wait for full request or error
    - remoteAddress: socket address to hold the remote sender's socket address
        on exit.
 
 - Returns: a `Result` which on success contains the number of bytes
    received, and on failure contains the error.
 */
@inlinable
public func recvfrom(
    _ socket: SocketIODescriptor,
    _ buffer: inout Data,
    _ flags: RecvFlags,
    _ remoteAddress: inout SocketAddress?) -> Result<Int, Error>
{
    assert(buffer.count > 0)
    
    var rAddress = SocketAddress()
    
    let result: Result<Int, Error> = buffer.withUnsafeMutableBytes
    { buffer in
        return rAddress.withMutableGenericPointer
        { remoteAddrPtr in
            var outSize = UInt32(MemoryLayout<SocketAddress>.size)
            let bytesRead = recvfrom(
                socket.descriptor,
                buffer.baseAddress!,
                buffer.count,
                flags.rawValue,
                remoteAddrPtr,
                &outSize
            )
            if bytesRead == -1 { return .failure(Error()) }
            
            remoteAddrPtr.pointee.sa_len = __uint8_t(outSize)
            return .success(bytesRead)
        }
    }
    
    /*
     For datagram Unix domain sockets, for the sender to receive a reply, the
     sender has to first bind to their own Unix domain socket address just like
     the server; otherwise, the system makes a transient connection which is
     immediately deleted, so there is no path for recvfrom to fill in, and thus
     a later sendto using that address will fail with ENOENT (file not found,
     basically).

     The message is still received, but no identifying info can be attached to
     the remoteAddress.
     
     We denote this case by setting remoteUnixAddress to nil
     */
    if case .success(_) = result,
       let remoteUnixAddress = rAddress.asUnix,
       remoteUnixAddress.path.isEmpty
    {
        remoteAddress =  nil
    }
    else { remoteAddress = rAddress }
    
    return result
}

// -------------------------------------
/**
 Receive data from a socket using a `MessageToReceive` structure (which is a
 proxy for POSIX.1's `msghdr` structure).
 
 This is the most flexible receive call.  It allows specifying flags, a sender
 address (in `message.name`, scatter input (similar to `readv`) into
 `message.messages`, and ancilialry data in `message.controlMessages`.
 
 The caller must provide pre-allocated `Data` buffers to receive message data.
 The `controlMessages` array is populated automatically, however.
 `.controlMessages` contain auxilliary data specific to the protocol and domain
 being used.
 
 On return, `message.flags` may contain one or more of the following
 `MessageFlags`:
    - `.endOfRecord`: Data completes record
    - `.messageTruncated`: Indicates that the trailing portion of a datagram
        was discarded because the datagram was larger than the buffer supplied.
    - `.controlDataTruncated`: Indicates that some control data were discarded
        due to lack of space in the buffer for ancillary data.
    - `.outOfBand`: Indicates that expedited or out-of-band data were received.
 
 - Parameters:
    - socket: The `SocketIODescriptor` to use for receiving data.
    - message: A `MessageToReceive` struct providing an array of pre-allocated
        `Data` instances to receive data (see `readv` for more information on
        how they are filled.)
    - flags: `RecvFlags` allowign modification of data receipt behavior.
 
 - Returns: On success, the returned value is a `Result` containing the total
    number of bytes received.  On failure, the returned `Result` contains the
    `Error` describing the reason for the failure.
*/
@inlinable
public func recvmsg(
    _ socket: SocketIODescriptor,
    _ message: inout MessageToReceive,
    _ flags: RecvFlags) -> Result<Int, Error>
{
    return message.withMutableMsgHdr
    {
        let bytesRead = HostOS.recvmsg(socket.descriptor, $0, flags.rawValue)
        return bytesRead == -1
            ? .failure(Error())
            : .success(bytesRead)
    }
}

// -------------------------------------
/**
 Send data to a coonnected or accepted socket.
 
 - Parameters:
    - socket: A previously connected or accepted `SocketIODescriptor` to
        send data to.
    - buffer: `Data` instance containing the bytes to send.
    - flags: `SendFlags` specifying non-default send behavior
 
 - Returns: a `Result` which on success contains the number of bytes
    sent, and on failure contains the error.
 */
@inlinable
public func send(
    _ socket: SocketIODescriptor,
    _ buffer: Data,
    _ flags: SendFlags = .none) -> Result<Int, Error>
{
    return buffer.withUnsafeBytes
    {
        let bytesWritten = send(
            socket.descriptor,
            $0.baseAddress!,
            $0.count,
            flags.rawValue
        )
        return bytesWritten == -1
            ? .failure(Error())
            : .success(bytesWritten)
    }
}

// -------------------------------------
/**
 Send data to a specified remote address
 
 - Parameters:
    - socket: socket descriptor to use to send the contents of `buffer`.
    - buffer: `Data` instance containing the bytes to send.
    - flags: `SendFlags` specifying non-default send behavior,
    - remoteAddress: The address to which to send the contents of `buffer`.
 
 - Returns: a `Result` which on success contains the number of bytes
    sent, and on failure contains the error.
 */
@inlinable
public func sendto(
    _ socket: SocketIODescriptor,
    _ buffer: Data,
    _ flags: SendFlags = .none,
    _ remoteAddress: SocketAddress) -> Result<Int, Error>
{
    return buffer.withUnsafeBytes
    { bufferPtr in
        remoteAddress.withGenericPointer
        {
            let bytesWritten = sendto(
                socket.descriptor,
                bufferPtr.baseAddress!,
                bufferPtr.count,
                flags.rawValue,
                $0,
                remoteAddress.len
            )
            return bytesWritten == -1
                ? .failure(Error())
                : .success(bytesWritten)
        }
    }
}

// -------------------------------------
/**
 Send data to a socket using a `MessageToSend` structure (which is a proxy for
 POSIX.1's `msghdr`).
 
 This is the most flexible send call.  It allows specifiing flags, a receiver
 address (in `message.name`), an array of `Data` instances  whose bytes are
 gathered and sent in a similar fashion as `writev`, and the ability to specify
 a `ControlMessage` (which is proxy for POSIX.1's `cmsghdr`).
 
 - Parameters:
    - socket: socket to use for sending the data
    - message: A `MessageToSend` instance whose `messages` array property
        contain `Data` instances whose bytes are the be gathered to send, and
        an optional `ControlMessage`.
    - flags: `SendFlags` to be used to alter the behavior of `sendmsg`.
 
 - Returns: On success, a `Result` is returned containing the total number of
    bytes sent.  On failure, the returned `Result` contains an `Error`
    describing the reason for the failure.
 */
@inlinable
public func sendmsg(
    _ socket: SocketIODescriptor,
    _ message: MessageToSend,
    _ flags: SendFlags) -> Result<Int, Error>
{
    return message.withMsgHdr
    {
        let bytesWritten = HostOS.sendmsg(socket.descriptor, $0, flags.rawValue)
        return bytesWritten == -1
            ? .failure(Error())
            : .success(bytesWritten)
    }
}
