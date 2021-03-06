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

// MARK:-
// -------------------------------------
class DatagramServer
{
    let uuid = UUID()
    
    let serverQueue: DispatchQueue
    private(set) var messageReceiptHandler: ((Data) -> Data?)? = nil
    
    let termMutex = DispatchSemaphore(value: 1)
    private var _shouldTerminate = false
    private var shouldTerminate: Bool
    {
        get { return termMutex.withLock { _shouldTerminate } }
        set { termMutex.withLock { _shouldTerminate = newValue } }
    }
    
    var useSendMessage = false
    
    // -------------------------------------
    init()
    {
        self.serverQueue = DispatchQueue(
            label: "server-\(uuid)",
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
    private func connectAndClose()
    {
        let socket: SocketIODescriptor
        switch makeSocket()
        {
            case .success(let s): socket = s
            case .failure(let error): fatalError("\(error)")
        }
        
        let socketAddress = makeServerSocketAddressForClient()
        switch NIX.sendto(socket, Data(), .none, socketAddress)
        {
            case .success(_): break
            case .failure(let error):
                fatalError("Failed to wake server to terminate: \(error)")
        }
        
        _ = NIX.close(socket)
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
    func start()
    {
        let serverSocket: SocketIODescriptor
        switch makeSocket()
        {
            case .success(let sock): serverSocket = sock
            case .failure(let error):
                fatalError("Could not create server socket: \(error)")
        }

        let socketAddress = makeServerSocketAddressForServer()

        if let error = NIX.bind(serverSocket, socketAddress)
        {
            _ = close(serverSocket)
            fatalError("Could not bind server socket: \(error)")
        }

        // Datagram servers don't need to "listen" instead they use recvfrom
        
        let waitSem = DispatchSemaphore(value: 0)

        serverQueue.async
        {
            defer { _ = NIX.close(serverSocket) }
            
            waitSem.signal()
            
            print("Server started on \(socketAddress)...")
            
            var readBuffer = Data(repeating: 0, count: 1024 * 4)

            while true
            {
                // No need to connect - just recvfrom
                var peerAddress: SocketAddress? = nil
                var peerMessage: Data
                switch NIX.recvfrom(
                    serverSocket,
                    &readBuffer,
                    .none,
                    &peerAddress)
                {
                    case .success(let bytesRead):
                        print("Server received \(bytesRead) bytes")
                        peerMessage = readBuffer.withUnsafeMutableBytes
                        {
                            Data(
                                bytesNoCopy: $0.baseAddress!,
                                count: bytesRead,
                                deallocator: .none
                            )
                        }
                        if peerAddress == nil
                        {
                            print(
                                "Server received no peer address from recvfrom"
                            )
                        }

                    case .failure(let error):
                        fatalError(
                            "recvfrom failed on server socket: \(error)"
                        )
                }
                
                if self.shouldTerminate
                {
                    print("Server terminating")
                    break
                }
                
                guard let pAddress = peerAddress else { continue }
                
                guard let response = self.responseFor(peerMessage) else {
                    continue
                }
                
                switch self.doSend(response, to: serverSocket, at: pAddress)
                {
                    case .success(let bytesWritten):
                        if bytesWritten != response.count {
                            print("Not all bytes were written to peer socket")
                        }
                    case .failure(let error):
                        print(
                            "Error writing to peer socket (\(pAddress)): "
                            + "\(error)"
                        )
                }
            }
        }
        
        waitSem.wait() // Wait until server loop has started before returning
        waitSem.signal()
    }
    
    // -------------------------------------
    func responseFor(_ clientData: Data) -> Data?
    {
        guard let handler = messageReceiptHandler else { return nil }
        
        return handler(clientData)
    }
    
    // -------------------------------------
    func doSend(
        _ data: Data,
        to socket: SocketIODescriptor,
        at address: SocketAddress) -> Result<Int, NIX.Error>
    {
        if useSendMessage
        {
            let fd = dup(socket.descriptor)
            let controlMessage = ControlMessage(
                level: HostOS.SOL_SOCKET,
                type: HostOS.SCM_RIGHTS,
                messageData: withUnsafeBytes(of: fd) { Data($0) }
            )
            
            let message = MessageToSend(
                name: address,
                messages: [data],
                controlMessage: controlMessage
            )
            
            return NIX.sendmsg(socket, message, .none)
        }
        else {
            return NIX.sendto(socket, data, .none, address)
        }
    }
}

// MARK:-
// -------------------------------------
class IP4TestDatagramServer: DatagramServer
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
        return NIX.socket(.inet4, .datagram, .udp)
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
class IP6TestDatagramServer: DatagramServer
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
        return NIX.socket(.inet6, .datagram, .udp)
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
class UnixDomainTestDatagramServer: DatagramServer
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
        return NIX.socket(.local, .datagram, .unspecified)
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
