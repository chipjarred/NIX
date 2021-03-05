import XCTest
@testable import NIX

// -------------------------------------
final class DatagramSocket_UnitTests: XCTestCase
{
    static var allTests =
    [
        ("test_ip4_client_can_connect_to_server", test_ip4_client_can_connect_to_server),
        ("test_ip6_client_can_connect_to_server", test_ip6_client_can_connect_to_server),
        ("test_unix_domain_client_can_connect_to_server", test_unix_domain_client_can_connect_to_server),
    ]
    
    // -------------------------------------
    func test_ip4_client_can_connect_to_server()
    {
        let serverPort = 2020
        
        let clientToServerMessage =
            "This is a test of the Emergency Broadcast System"
        let serverToClientMessage =
            "Had this been a real emergency, this message would not help at all"
        
        var messageServerReceived = ""
        let server = IP4TestDatagramServer(port: serverPort).onMessageReceipt
        { clientMessage in
            messageServerReceived =
                String(data: clientMessage, encoding: .utf8)!
            return serverToClientMessage.data(using: .utf8)!
        }
        
        server.start()
        
        defer { server.terminate() }
        
        let socket: SocketIODescriptor
        switch NIX.socket(.inet4, .datagram, .udp)
        {
            case .success(let s): socket = s
            case .failure(let e):
                XCTFail("Failed to create socket \(e)")
                return
        }
        
        defer
        {
            if let error = NIX.close(socket) {
                XCTFail("Failed to close client socket: \(error)")
            }
        }
        
        let serverAddress = SocketAddress(ip4Address: .loopback, port: serverPort)
        
        // No need to connect - just sendto()
        switch NIX.sendto(
            socket,
            clientToServerMessage.data(using: .utf8)!,
            .none,
            serverAddress)
        {
            case .success(let bytesSent):
                let messageSize = clientToServerMessage.count
                if bytesSent < messageSize
                {
                    XCTFail(
                        "Client only sent \(bytesSent) of \(messageSize) bytes"
                    )
                    return
                }
            case .failure(let error):
                XCTFail("Client failed to send message: \(error)")
                return
        }
                
        var readBuffer = Data(repeating: 0, count: 1024)
        var remoteAddress: SocketAddress? = nil
        switch NIX.recvfrom(socket, &readBuffer, .none, &remoteAddress)
        {
            case .success(let bytesRead):
                XCTAssertEqual(bytesRead, serverToClientMessage.count)
                readBuffer.removeLast(readBuffer.count - bytesRead)
            
            case .failure(let e):
                XCTFail("Client write failed: \(e)")
                return
        }
        
        XCTAssertEqual(clientToServerMessage, messageServerReceived)
        
        let messageClientReceived = String(data: readBuffer, encoding: .utf8)!
        XCTAssertEqual(serverToClientMessage, messageClientReceived)
    }
    
    // -------------------------------------
    func test_ip6_client_can_connect_to_server()
    {
        let serverPort = 2020
        
        let clientToServerMessage =
            "This is a test of the Emergency Broadcast System"
        let serverToClientMessage =
            "Had this been a real emergency, this message would not help at all"
        
        var messageServerReceived = ""
        let server = IP6TestDatagramServer(port: serverPort).onMessageReceipt
        { clientMessage in
            messageServerReceived =
                String(data: clientMessage, encoding: .utf8)!
            return serverToClientMessage.data(using: .utf8)!
        }
        
        server.start()
        
        defer { server.terminate() }
        
        let socket: SocketIODescriptor
        switch NIX.socket(.inet6, .datagram, .udp)
        {
            case .success(let s): socket = s
            case .failure(let e):
                XCTFail("Failed to create socket \(e)")
                return
        }
        
        defer
        {
            if let error = NIX.close(socket) {
                XCTFail("Failed to close client socket: \(error)")
            }
        }
        
        let serverAddress = SocketAddress(ip6Address: .loopback, port: serverPort)
        
        // No need to connect - just sendto()
        switch NIX.sendto(
            socket,
            clientToServerMessage.data(using: .utf8)!,
            .none,
            serverAddress)
        {
            case .success(let bytesSent):
                let messageSize = clientToServerMessage.count
                if bytesSent < messageSize
                {
                    XCTFail(
                        "Client only sent \(bytesSent) of \(messageSize) bytes"
                    )
                    return
                }
            case .failure(let error):
                XCTFail("Client failed to send message: \(error)")
                return
        }
                
        var readBuffer = Data(repeating: 0, count: 1024)
        var remoteAddress: SocketAddress? = nil
        switch NIX.recvfrom(socket, &readBuffer, .none, &remoteAddress)
        {
            case .success(let bytesRead):
                XCTAssertEqual(bytesRead, serverToClientMessage.count)
                readBuffer.removeLast(readBuffer.count - bytesRead)
            
            case .failure(let e):
                XCTFail("Client write failed: \(e)")
                return
        }
        
        XCTAssertEqual(clientToServerMessage, messageServerReceived)
        
        let messageClientReceived = String(data: readBuffer, encoding: .utf8)!
        XCTAssertEqual(serverToClientMessage, messageClientReceived)
    }
    
    // -------------------------------------
    func test_unix_domain_client_can_connect_to_server()
    {
        let serverPath = "\(#function).serverSocket"
        let clientPath = "\(#function).clientSocket"
        
        if let error = NIX.unlink(serverPath), error.errno != HostOS.ENOENT
        {
            XCTFail("Failed to remove previous socket file")
            return
        }
        defer { _ = NIX.unlink(clientPath) }

        let clientToServerMessage =
            "This is a test of the Emergency Broadcast System"
        let serverToClientMessage =
            "Had this been a real emergency, this message would not help at all"
        
        var messageServerReceived = ""
        let maybeServer = UnixDomainTestDatagramServer(path: serverPath)?
            .onMessageReceipt
            { clientMessage in
                messageServerReceived =
                    String(data: clientMessage, encoding: .utf8)!
                return serverToClientMessage.data(using: .utf8)!
            }
        
        guard let server = maybeServer else
        {
            XCTFail("Failed to create UnixDomainTestStreamServer")
            return
        }

        server.start()
        
        defer { server.terminate() }
        
        let socket: SocketIODescriptor
        switch NIX.socket(.local, .datagram, .unspecified)
        {
            case .success(let s): socket = s
            case .failure(let e):
                XCTFail("Failed to create socket \(e)")
                return
        }
        
        defer
        {
            if let error = NIX.close(socket) {
                XCTFail("Failed to close client socket: \(error)")
            }
        }
        
        guard let serverUnixPath = NIX.UnixSocketPath(serverPath) else
        {
            XCTFail(
                "Failed to create UnixSocketPath for path = \"\(serverPath)\""
            )
            return
        }
        guard let clientUnixPath =  UnixSocketPath(clientPath) else {
            XCTFail(
                "Failed to create UnixSocketPath for path = \"\(clientPath)\""
            )
            return
        }
        
        let serverAddress = SocketAddress(unixPath: serverUnixPath)
        let clientAddress = SocketAddress(unixPath: clientUnixPath)
        defer { _ = NIX.unlink(clientPath) }

        // No need to connect; however we do need to bind for Unix domain
        // datagram sockets, even for client.
        if let error = NIX.bind(socket, clientAddress)
        {
            XCTFail("Client failed to bind to Unix socket address: \(error)")
            return
        }
        
        switch NIX.sendto(
            socket,
            clientToServerMessage.data(using: .utf8)!,
            .none,
            serverAddress)
        {
            case .success(let bytesSent):
                let messageSize = clientToServerMessage.count
                if bytesSent < messageSize
                {
                    XCTFail(
                        "Client only sent \(bytesSent) of \(messageSize) bytes"
                    )
                    return
                }
            case .failure(let error):
                XCTFail("Client failed to send message: \(error)")
                return
        }
                
        var readBuffer = Data(repeating: 0, count: 1024)
        var remoteAddress: SocketAddress? = nil
        switch NIX.recvfrom(socket, &readBuffer, .none, &remoteAddress)
        {
            case .success(let bytesRead):
                XCTAssertEqual(bytesRead, serverToClientMessage.count)
                readBuffer.removeLast(readBuffer.count - bytesRead)
            
            case .failure(let e):
                XCTFail("Client write failed: \(e)")
                return
        }
        
        XCTAssertEqual(clientToServerMessage, messageServerReceived)
        
        let messageClientReceived = String(data: readBuffer, encoding: .utf8)!
        XCTAssertEqual(serverToClientMessage, messageClientReceived)
    }
    
    // -------------------------------------
    func test_unix_domain_recvmsg_sets_cmsg_level_and_cmsg_type()
    {
        let serverPath = "\(#function).serverSocket"
        let clientPath = "\(#function).clientSocket"
        
        if let error = NIX.unlink(serverPath), error.errno != HostOS.ENOENT
        {
            XCTFail("Failed to remove previous socket file")
            return
        }
        defer { _ = NIX.unlink(clientPath) }

        let clientToServerMessage =
            "This is a test of the Emergency Broadcast System"
        let serverToClientMessage =
            "Had this been a real emergency, this message would not help at all"
        
        var messageServerReceived = ""
        let maybeServer = UnixDomainTestDatagramServer(path: serverPath)?
            .onMessageReceipt
            { clientMessage in
                messageServerReceived =
                    String(data: clientMessage, encoding: .utf8)!
                return serverToClientMessage.data(using: .utf8)!
            }
        
        guard let server = maybeServer else
        {
            XCTFail("Failed to create UnixDomainTestStreamServer")
            return
        }
        
        server.useSendMessage = true

        server.start()
        
        defer { server.terminate() }
        
        let socket: SocketIODescriptor
        switch NIX.socket(.local, .datagram, .unspecified)
        {
            case .success(let s): socket = s
            case .failure(let e):
                XCTFail("Failed to create socket \(e)")
                return
        }
        
        defer
        {
            if let error = NIX.close(socket) {
                XCTFail("Failed to close client socket: \(error)")
            }
        }
        
        guard let serverUnixPath = NIX.UnixSocketPath(serverPath) else
        {
            XCTFail(
                "Failed to create UnixSocketPath for path = \"\(serverPath)\""
            )
            return
        }
        guard let clientUnixPath =  UnixSocketPath(clientPath) else {
            XCTFail(
                "Failed to create UnixSocketPath for path = \"\(clientPath)\""
            )
            return
        }
        
        let serverAddress = SocketAddress(unixPath: serverUnixPath)
        let clientAddress = SocketAddress(unixPath: clientUnixPath)
        defer { _ = NIX.unlink(clientPath) }

        // No need to connect; however we do need to bind for Unix domain
        // datagram sockets, even for client.
        if let error = NIX.bind(socket, clientAddress)
        {
            XCTFail("Client failed to bind to Unix socket address: \(error)")
            return
        }
        
        switch NIX.sendto(
            socket,
            clientToServerMessage.data(using: .utf8)!,
            .none,
            serverAddress)
        {
            case .success(let bytesSent):
                let messageSize = clientToServerMessage.count
                if bytesSent < messageSize
                {
                    XCTFail(
                        "Client only sent \(bytesSent) of \(messageSize) bytes"
                    )
                    return
                }
            case .failure(let error):
                XCTFail("Client failed to send message: \(error)")
                return
        }
         
        var msg = MessageToReceive(
            messageName: Data(repeating: 0, count: MemoryLayout<HostOS.sockaddr_un>.size),
            messages: [Data(repeating: 0, count: 1024)],
            flags: .none
        )
        switch NIX.recvmsg(socket, &msg, .none)
        {
            case .success(let bytesRead):
                XCTAssertEqual(bytesRead, serverToClientMessage.count)
                msg.messages[0].removeLast(msg.messages[0].count - bytesRead)
            
            case .failure(let e):
                XCTFail("Client write failed: \(e)")
                return
        }
        
        XCTAssertEqual(clientToServerMessage, messageServerReceived)
        
        let messageClientReceived =
            String(data: msg.messages[0], encoding: .utf8)!
        XCTAssertEqual(serverToClientMessage, messageClientReceived)
        
        XCTAssertEqual(msg.controlMessages[0].level, HostOS.SOL_SOCKET)
        XCTAssertEqual(msg.controlMessages[0].type, HostOS.SCM_RIGHTS)
    }
}
