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
@inlinable
public func socket(
    _ addressFamily: SocketDomain,
    _ socketType: SocketType,
    _ protocolFamily: ProtocolFamily) -> Result<SocketIODescriptor, Error>
{
    let result = socket(
        addressFamily.rawValue,
        socketType.rawValue,
        protocolFamily.rawValue
    )
    
    return result == -1
        ? .failure(Error())
        : .success(SocketDescriptor(result))
}

// -------------------------------------
@inlinable
public func bind<SockAddr: SocketAddress>(
    _ socket: SocketIODescriptor,
    _ address: SockAddr) -> Error?
{
    return withPointer(to: address, recastTo: sockaddr.self)
    {
        let result = bind(
            socket.descriptor,
            $0,
            SockAddr.byteSize
        )
        return result == -1 ? Error() : nil
    }
}

// -------------------------------------
@inlinable
public func listen(
    _ socket: SocketIODescriptor,
    _ backlog: Int) -> Error?
{
    let result = listen(socket.descriptor, Int32(backlog))

    return result == -1 ? Error() : nil
}

// -------------------------------------
@inlinable
public func accept<SockAddr: SocketAddress>(
    _ socket: SocketIODescriptor,
    _ remoteAddress: inout SockAddr) -> Result<SocketDescriptor, Error>
{
    return withMutablePointer(to: &remoteAddress, recastTo: sockaddr.self)
    {
        var outSize = UInt32(SockAddr.byteSize)
        let result = accept(
            socket.descriptor,
            $0,
            &outSize
        )
        return result == -1
            ? .failure(Error())
            : .success(SocketDescriptor(result))
    }
}

// -------------------------------------
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
    - flags: `RecvFlags` specifying non-default reception behavior.
 
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
