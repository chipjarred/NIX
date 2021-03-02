import XCTest
@testable import NIX

// -------------------------------------
final class NIXTests: XCTestCase
{
    static var allTests =
    [
        ("test_ip4_client_can_connect_to_server", test_ip4_client_can_connect_to_server),
        ("test_ip6_client_can_connect_to_server", test_ip6_client_can_connect_to_server),
        ("test_unix_domain_client_can_connect_to_server", test_unix_domain_client_can_connect_to_server),
    ]
    
    // -------------------------------------
    /*
     WARNING: This test fails due to entitlements issue with XCTest runner on
     macOS. I have it disabled in Xcode.  In order to successfully test it, you
     have to run it in an app with the appropriate entitlements.
     
     see: https://developer.apple.com/forums/thread/114907

     I *think* it will work on Linux where Apple entitlements isn't an issue,
     so long as the user running XCTest has permissions to bind to ports, but I
     don't have Linux installed anywhere to try it.
     
     The server socket fails on the call to NIX.bind.
     
     Strangely, the IPv6 test works, which seems like a bug in entitlements.
     Either it's a bug because IP4 should work too, or it's a bug because the
     entitlements don't protect against IPv6 network access.  Either way it's a
     bug.
     
     */
    func test_ip4_client_can_connect_to_server()
    {
        let serverPort = 2020
        
        let clientToServerMessage =
            "This is a test of the Emergency Broadcast System"
        let serverToClientMessage =
            "Had this been a real emergency, this message would not help at all"
        
        var messageServerReceived = ""
        let server = IP4TestStreamServer(port: serverPort).onMessageReceipt
        { clientMessage in
            messageServerReceived =
                String(data: clientMessage, encoding: .utf8)!
            return serverToClientMessage.data(using: .utf8)!
        }
        
        server.start()
        
        defer { server.terminate() }
        
        let socket: SocketIODescriptor
        switch NIX.socket(.inet4, .stream, .ip)
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
        
        let serverAddress = NIX.socketAddress(for: .loopback, port: serverPort)
        
        if let error = NIX.connect(socket, serverAddress)
        {
            XCTFail("Failed to connect to server: \(error)")
            return
        }
        
        switch NIX.write(socket, clientToServerMessage.data(using: .utf8)!)
        {
            case .success(let bytesWritten):
                XCTAssertEqual(bytesWritten, clientToServerMessage.count)
            case .failure(let e):
                XCTFail("Client write failed: \(e)")
                return
        }
        
        var readBuffer = Data(repeating: 0, count: 1024)
        switch NIX.read(socket, &readBuffer)
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
        let serverPort = 2021
        
        let clientToServerMessage =
            "This is a test of the Emergency Broadcast System"
        let serverToClientMessage =
            "Had this been a real emergency, this message would not help at all"
        
        var messageServerReceived = ""
        let server = IP6TestStreamServer(port: serverPort).onMessageReceipt
        { clientMessage in
            messageServerReceived =
                String(data: clientMessage, encoding: .utf8)!
            return serverToClientMessage.data(using: .utf8)!
        }
        
        server.start()
        
        defer { server.terminate() }
        
        let socket: SocketIODescriptor
        switch NIX.socket(.inet6, .stream, .ip)
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
        
        let serverAddress = NIX.socketAddress(for: .loopback, port: serverPort)
        
        if let error = NIX.connect(socket, serverAddress)
        {
            XCTFail("Failed to connect to server: \(error)")
            return
        }
        
        switch NIX.write(socket, clientToServerMessage.data(using: .utf8)!)
        {
            case .success(let bytesWritten):
                XCTAssertEqual(bytesWritten, clientToServerMessage.count)
            case .failure(let e):
                XCTFail("Client write failed: \(e)")
                return
        }
        
        var readBuffer = Data(repeating: 0, count: 1024)
        switch NIX.read(socket, &readBuffer)
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
        let serverPath =
            "\(ProcessInfo.processInfo.processIdentifier).serverSocket"
        
        if let error = NIX.unlink(serverPath), error.errno != HostOS.ENOENT
        {
            XCTFail("Failed to remove previous socket file")
            return
        }
        
        let clientToServerMessage =
            "This is a test of the Emergency Broadcast System"
        let serverToClientMessage =
            "Had this been a real emergency, this message would not help at all"
        
        var messageServerReceived = ""
        let maybeServer = UnixDomainTestStreamServer(path: serverPath)?
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
        switch NIX.socket(.local, .stream, .ip)
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
        
        guard let unixPath = NIX.UnixSocketPath(serverPath) else
        {
            XCTFail(
                "Failed to create UnixSocketPath for path = \"\(serverPath)\""
            )
            return
        }
        
        let serverAddress = NIX.socketAddress(for: unixPath)
        
        if let error = NIX.connect(socket, serverAddress)
        {
            XCTFail("Failed to connect to server: \(error)")
            return
        }
        
        switch NIX.write(socket, clientToServerMessage.data(using: .utf8)!)
        {
            case .success(let bytesWritten):
                XCTAssertEqual(bytesWritten, clientToServerMessage.count)
            case .failure(let e):
                XCTFail("Client write failed: \(e)")
                return
        }
        
        var readBuffer = Data(repeating: 0, count: 1024)
        switch NIX.read(socket, &readBuffer)
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
}
