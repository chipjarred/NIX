# NIX

Not to be confused with the Nix package manager, `NIX` (as in "UNIX" without the "U") is a thin Swift wrapper around the POSIX system call API provided by Darwin and Linux to make working with that API easier and safer in Swift while preserving the basic feel of the POSIX API.

It provides improved type safety (for example flags are specific `OptionSet`s rather than `Int32` to prevent illegal values from being passed), attempts to remove the need for the caller to explicitly use `UnsafePointer`s, and separates normal return values from error indicators by returning either `NIX.Error?` or a `Result<T, NIX.Error>`.  I've specifically chosen not to use exceptions for error handling, because it deviates too much from the way the POSIX API is designed.

I'm making it available for others to use, but I've created it for my own use, and am improving and updating it when I have the need, so it's a work-in-progress, and is likely to be for a long time, given how large the POSIX API is.  

If the functionality you're looking for is missing, but is provided for by POSIX, or normally provided on Unix-like operating systems, please let me know,  or even better contribute.

At the moment `NIX` mostly centers around socket functionality, but the intention is to include more and more of the POSIX API over time.

As an example, here's a simple echo server (IPv6) in all its POSIX-level glory, written using `NIX`:

```swift
import NIX
import Foundation

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
```
Obviously, one could write it much more succinctly using a higher level library, but that misses the point, which is that if directly using Darwin's (or Linux's) POSIX calls, much of the code would have to be wrapped in `withUnsafePointer` closures, and it's easy to forget to check return values.   With `NIX` functions, if an error occurs, it can't be mistaken for a good return value, because it's a completely different type.
