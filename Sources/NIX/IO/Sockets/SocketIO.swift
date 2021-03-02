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
public func bind<SockAddr: SocketAddress>(
    _ socket: SocketIODescriptor,
    _ address: SockAddr) -> Error?
{
    return withPointer(to: address, recastTo: sockaddr.self)
    {
        let result = HostOS.bind(
            socket.descriptor,
            $0,
            SockAddr.byteSize
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
public func accept<SockAddr: SocketAddress>(
    _ socket: SocketIODescriptor,
    _ remoteAddress: inout SockAddr) -> Result<SocketDescriptor, Error>
{
    return withMutablePointer(to: &remoteAddress, recastTo: sockaddr.self)
    {
        var outSize = UInt32(SockAddr.byteSize)
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
public func connect<SockAddr: SocketAddress>(
    _ socket: SocketIODescriptor,
    _ remoteAddress: SockAddr) -> Error?
{
    return withPointer(to: remoteAddress, recastTo: sockaddr.self)
    {
        let result = connect(
            socket.descriptor,
            $0,
            SockAddr.byteSize
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
 repeatedly allocating them.  It is the caller's responsibilty copy the
 data elsewhere if needed.
 
 - Parameters:
    - socket: A previously connected or accepted `SocketIODescriptor` to
        receive data from.
    - buffer: A `Data` buffer into which to receive the data.  On entry,
        `buffer.count` will determine the maximum number of bytes that can
        be read.
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
 repeatedly allocating them.  It is the caller's responsibilty copy the
 data elsewhere if needed.
 
 - Parameters:
    - socket: A previously connected or accepted `SocketIODescriptor` to
        receive data from.
    - buffer: A `Data` buffer into which to receive the data.  On entry,
        `buffer.count` will determine the maximum number of bytes that can
        be read.
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
    _ remoteAddress: inout SocketAddress) -> Result<Int, Error>.Publisher
{
    assert(buffer.count > 0)
    
    return buffer.withUnsafeMutableBytes
    { buffer in
        return withMutablePointer(to: &remoteAddress, recastTo: sockaddr.self)
        { remoteAddrPtr in
            var outSize: UInt32
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
