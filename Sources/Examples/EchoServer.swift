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

import NIX
import HostOS
import Foundation

func echoServerExample()
{
    let listenSocket = setUpListenerSocket(onPort: 2020)
    defer { _ = NIX.close(listenSocket) }

    print("Echo server started...")

    let dispatchQueue = DispatchQueue(label: "\(UUID())", attributes: .concurrent)

    while let peerSocket = acceptAConnection(for: listenSocket)
    {
        dispatchQueue.async {
            clientSession(for: peerSocket)
        }
    }
}

func setUpListenerSocket(onPort port: Int) -> SocketIODescriptor
{
    let listenSocket: SocketIODescriptor
    switch NIX.socket(.inet6, .stream, .ip)
    {
        case .success(let sock): listenSocket = sock
        case .failure(let error):
            fatalError("Could not create listener socket: \(error)")
    }

    let socketAddress = SocketAddress(ip6Address: .any, port: port)

    if let error = NIX.bind(listenSocket, socketAddress) {
        fatalError("Could not bind listener socket: \(error)")
    }

    if let error = NIX.listen(listenSocket, 100) {
        fatalError("Could not listen on listener socket: \(error)")
    }
    
    return listenSocket
}

func acceptAConnection(for listener: SocketIODescriptor) -> SocketIODescriptor?
{
    var peerSocket: SocketIODescriptor
    switch NIX.accept(listener)
    {
        case .success(let sock): peerSocket = sock
        case .failure(let error):
            fatalError("Accept failed on listener socket: \(error)")
    }
    
    /*
     Some code could be put here to allow terminating the listener loop by
     returning nil.  For this simple example, we don't do that.
     */
    
    return peerSocket
}

func clientSession(for peerSocket: SocketIODescriptor)
{
    defer { _ = NIX.close(peerSocket) }
    
    var readBuffer = Data(repeating: 0, count: 1024)

    while let peerMessage =
            getPeerMessage(from: peerSocket, using: &readBuffer)
    {
        if peerMessage.isEmpty { continue }
        
        guard let response = makeResponse(for: peerMessage),
              sendResponse(response: response, to: peerSocket)
        else { break }
    }
}

func getPeerMessage(
    from peerSocket: SocketIODescriptor,
    using readBuffer: inout Data) -> Data?
{
    switch NIX.read(peerSocket, &readBuffer)
    {
        case .success(let bytesRead):
            if bytesRead == 0 {
                print("Peer closed connection")
                return nil
            }
            
            return Data(readBuffer[..<bytesRead])
            
        case .failure(let error):
            if error.errno == HostOS.EAGAIN { return Data() }
            print("Error reading from peer socket: \(error)")
            return nil
    }
}

func makeResponse(for message: Data) -> String?
{
    guard var peerStr = String(data: message, encoding: .utf8) else
    {
        print("Peer message is invalid string: \(message)")
        return  "Huh?"
    }
    
    if peerStr.last == "\n" { peerStr.removeLast() }
    
    if peerStr.lowercased() == "quit"
    {
        print("Client requested quit")
        return nil
    }
    
    print("Peer message received: \"\(peerStr)\"")
    return "You said, \"\(peerStr)\"\n"
}

func sendResponse(response: String, to peerSocket: SocketIODescriptor) -> Bool
{
    switch NIX.write(peerSocket, response.data(using: .utf8)!)
    {
        case .success(let bytesWritten):
            if bytesWritten != response.count {
                print("Not all bytes were written to peer socket")
            }
        case .failure(let error):
            print("Error writing to peer socket: \(error)")
            return false
    }
    return true
}
