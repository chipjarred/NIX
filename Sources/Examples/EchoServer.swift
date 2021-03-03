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
import Foundation

func echoServerExample()
{
    let listenSocket: SocketIODescriptor
    switch NIX.socket(.inet6, .stream, .ip)
    {
        case .success(let sock): listenSocket = sock
        case .failure(let error):
            fatalError("Could not create listener socket: \(error)")
    }

    defer { _ = close(listenSocket) }

    let socketAddress = SocketAddress(ip6Address: .any, port: 2020)

    if let error = NIX.bind(listenSocket, socketAddress) {
        fatalError("Could not bind listener socket: \(error)")
    }

    if let error = NIX.listen(listenSocket, 100) {
        fatalError("Could not listen on listener socket: \(error)")
    }

    print("Echo server started...")

    let dispatchQueue = DispatchQueue(label: "\(UUID())", attributes: .concurrent)

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
        
        dispatchQueue.async
        {
            defer { _ = NIX.close(peerSocket) }
            
            var readBuffer = Data(repeating: 0, count: 1024)

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
                
                // Process client data
                let response: String
                if var peerStr = String(data: peerMessage, encoding: .utf8)
                {
                    if peerStr.last == "\n" { peerStr.removeLast() }
                    
                    if peerStr.lowercased() == "quit"
                    {
                        print("Client requested quit")
                        break clientLoop
                    }
                    
                    print("Peer message received: \"\(peerStr)\"")
                    response = "You said, \"\(peerStr)\"\n"
                }
                else
                {
                    print("Peer message is invalid string: \(readBuffer)")
                    response = "Huh?"
                }
                
                // Write response to client
                switch NIX.write(peerSocket, response.data(using: .utf8)!)
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
    }
}
