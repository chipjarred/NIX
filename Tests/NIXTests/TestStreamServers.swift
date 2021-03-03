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

import Foundation
import Dispatch
import XCTest
import NIX

// -------------------------------------
extension DispatchSemaphore
{
    func withLock<R>(_ block: () throws -> R) rethrows -> R
    {
        wait()
        defer { signal() }
        return try block()
    }
}

// MARK:-
// -------------------------------------
class StreamServer
{
    let uuid = UUID()
    
    let serverQueue: DispatchQueue
    let clientQueue: DispatchQueue
    private(set) var messageReceiptHandler: ((Data) -> Data?)? = nil
    
    let termMutex = DispatchSemaphore(value: 1)
    private var _shouldTerminate = false
    private var shouldTerminate: Bool
    {
        get { return termMutex.withLock { _shouldTerminate } }
        set { termMutex.withLock { _shouldTerminate = newValue } }
    }
    
    // -------------------------------------
    init()
    {
        self.serverQueue = DispatchQueue(
            label: "server-\(uuid)",
            attributes: .concurrent
        )
        self.clientQueue = DispatchQueue(
            label: "client-\(uuid)",
            attributes: .concurrent
        )
    }
    
    // -------------------------------------
    func onMessageReceipt(do handler: @escaping (Data) -> Data?) -> Self
    {
        self.messageReceiptHandler = handler
        return self
    }
    
    // -------------------------------------
    func terminate()
    {
        shouldTerminate = true
        connectAndClose()
    }
    
    // -------------------------------------
    func makeSocket() -> Result<SocketIODescriptor, NIX.Error> {
        fatalError("Override me!: \(#function)")
    }
    
    // -------------------------------------
    func makeServerSocketAddressForClient() -> SocketAddress {
        fatalError("Override me!: \(#function)")
    }
    
    // -------------------------------------
    func makeServerSocketAddressForServer() -> SocketAddress {
        fatalError("Override me!: \(#function)")
    }
    
    // -------------------------------------
    private func connectAndClose()
    {
        let socket: SocketIODescriptor
        switch makeSocket()
        {
            case .success(let s): socket = s
            case .failure(let error): fatalError("\(error)")
        }
        
        let socketAddress = makeServerSocketAddressForClient()
        if let error = NIX.connect(socket, socketAddress) {
            fatalError("\(error)")
        }
        
        _ = NIX.close(socket)
    }

    // -------------------------------------
    func start()
    {
        let listenSocket: SocketIODescriptor
        switch makeSocket()
        {
            case .success(let sock): listenSocket = sock
            case .failure(let error):
                fatalError("Could not create listener socket: \(error)")
        }

        let socketAddress = makeServerSocketAddressForServer()

        if let error = NIX.bind(listenSocket, socketAddress)
        {
            _ = close(listenSocket)
            fatalError("Could not bind listener socket: \(error)")
        }

        if let error = NIX.listen(listenSocket, 100)
        {
            _ = close(listenSocket)
            fatalError("Could not listen on listener socket: \(error)")
        }
        
        let waitSem = DispatchSemaphore(value: 0)

        serverQueue.async
        {
            defer { _ = NIX.close(listenSocket) }
            
            waitSem.signal()
            
            print("Server started...")

            while true
            {
                var peerAddress = SocketAddress()
                var peerSocket: SocketIODescriptor
                switch NIX.accept(listenSocket, &peerAddress)
                {
                    case .success(let sock): peerSocket = sock
                    case .failure(let error):
                        fatalError("Accept failed on listener socket: \(error)")
                }
                
                if self.shouldTerminate
                {
                    print("Server terminating")
                    _ = NIX.close(peerSocket)
                    break
                }
                
                self.clientQueue.async
                {
                    self.handlePeerSession(
                        with: peerSocket,
                        peerAddress: peerAddress
                    )
                }
            }
        }
        
        waitSem.wait() // Wait until server loop has started before returning
        waitSem.signal()
    }

    // -------------------------------------
    private func handlePeerSession(
        with peerSocket: SocketIODescriptor,
        peerAddress: SocketAddress)
    {
        defer { _ = NIX.close(peerSocket) }
        
        var readBuffer = Data(repeating: 0, count: 1024 * 4)

        clientLoop: while true
        {
            // Read data from client
            var peerMessage: Data
            switch NIX.read(peerSocket, &readBuffer)
            {
                case .success(let bytesRead):
                    if bytesRead == 0 {
                        print("Peer closed connection")
                        break clientLoop
                    }
                    
                    peerMessage = readBuffer.withUnsafeMutableBytes
                    {
                        Data(
                            bytesNoCopy: $0.baseAddress!,
                            count: bytesRead,
                            deallocator: .none
                        )
                    }
                    break
                    
                case .failure(let error):
                    if error.errno == HostOS.EAGAIN { continue }
                    print("Error reading from peer socket: \(error)")
                    break clientLoop
            }
            
            guard let response = responseFor(peerMessage) else { continue }
            
            
            // Write response to client
            switch NIX.write(peerSocket, response)
            {
                case .success(let bytesWritten):
                    if bytesWritten != response.count {
                        print("Not all bytes were written to peer socket")
                    }
                case .failure(let error):
                    print("Error writing to peer socket: \(error)")
                    break clientLoop
            }
        }
    }
    
    // -------------------------------------
    func responseFor(_ clientData: Data) -> Data?
    {
        guard let handler = messageReceiptHandler else { return nil }
        
        return handler(clientData)
    }
}

// MARK:-
// -------------------------------------
class IP4TestStreamServer: StreamServer
{
    let address: HostOS.in_addr
    let port: Int
    
    // -------------------------------------
    init(address: HostOS.in_addr = .any, port: Int)
    {
        self.address = address
        self.port = port
    }
    
    // -------------------------------------
    override func makeSocket() -> Result<SocketIODescriptor, NIX.Error> {
        return NIX.socket(.inet4, .stream, .tcp)
    }
    
    // -------------------------------------
    override func makeServerSocketAddressForClient() -> SocketAddress {
        return SocketAddress(ip4Address: in_addr.loopback, port: port)
    }
    
    // -------------------------------------
    override func makeServerSocketAddressForServer() -> SocketAddress {
        return SocketAddress(ip4Address: in_addr.any, port: port)
    }
}

// MARK:-
// -------------------------------------
class IP6TestStreamServer: StreamServer
{
    let address: HostOS.in6_addr
    let port: Int
    
    // -------------------------------------
    init(address: HostOS.in6_addr = .any, port: Int)
    {
        self.address = address
        self.port = port
    }
    
    // -------------------------------------
    override func makeSocket() -> Result<SocketIODescriptor, NIX.Error> {
        return NIX.socket(.inet6, .stream, .ip)
    }
    
    // -------------------------------------
    override func makeServerSocketAddressForClient() -> SocketAddress {
        return SocketAddress(ip6Address: in6_addr.loopback, port: port)
    }
    
    // -------------------------------------
    override func makeServerSocketAddressForServer() -> SocketAddress {
        return SocketAddress(ip6Address: in6_addr.any, port: port)
    }
}

// MARK:-
// -------------------------------------
class UnixDomainTestStreamServer: StreamServer
{
    let path: NIX.UnixSocketPath
    
    // -------------------------------------
    init?(path: String = "\(ProcessInfo.processInfo.processIdentifier).socket")
    {
        guard let unixPath = UnixSocketPath(path) else { return nil }
        self.path = unixPath
    }
    
    // -------------------------------------
    override func makeSocket() -> Result<SocketIODescriptor, NIX.Error> {
        return NIX.socket(.local, .stream, .ip)
    }
    
    // -------------------------------------
    override func makeServerSocketAddressForClient() -> SocketAddress {
        return SocketAddress(unixPath: path)
    }
    
    // -------------------------------------
    override func makeServerSocketAddressForServer() -> SocketAddress {
        return SocketAddress(unixPath: path)
    }
}
