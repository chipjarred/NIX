# NIX

Not to be confused with the Nix package manager, `NIX` (as in "UNIX" without the "U") is a thin Swift wrapper around the POSIX system call API provided by Darwin and Linux to make working with that API easier and safer in Swift while preserving the basic feel of the POSIX API.

It provides improved type safety (for example flags are specific `OptionSet`s rather than `Int32` to prevent illegal values from being passed), attempts to remove the need for the caller to explicitly use `UnsafePointer`s, and separates normal return values from error indicators by returning either `NIX.Error?` or a `Result<T, NIX.Error>`.  I've specifically chosen not to use exceptions for error handling, because it deviates too much from the way the POSIX API is designed.

I'm making it available for others to use, but I've created it for my own use, and am improving and updating it when I have the need, so it's a work-in-progress, and is likely to be for a long time, given how large the POSIX API is.  

If the functionality you're looking for is missing, but is provided for by POSIX, or normally provided on Unix-like operating systems, please let me know,  or even better contribute.

At the moment `NIX` mostly centers around socket functionality, but the intention is to include more and more of the POSIX API over time.

## Design

One of the core principles of NIX is to maintain, as much as possible, the POSIX.1 interface, while improving type-safety and error handling to prevent common mistakes.  Those improvements require altering the interface somewhat, so NIX is not just a drop-in overlay over POSIX.1, but it should feel familiar to Swift programmers familiar with POSIX.1 in C, making it easy to adopt.

NIX adopts some consistent standards to accomplish this.

### Error Handling

POSIX.1, intended for use in the C programming language, handles errors by overloading the meaning of a function's return value, and setting a global `errno` for that exact error.  Functions that return pointers indicate failure by returning `NULL`, which numerically is `0` in C.  On the other hand, functions that return integers, indicate failure by returning `-1`, which is `~0` in C... exactly the inverse of the pointer return.  Furthermore, functions whose integer return value is just a boolean success or fail return `0` to indicate success and `-1` to indicate failure.  While this makes sense given the constraints of using integers for the return value, it is counter-intuitive.  Normally `0` is `FALSE` which one would naturally associate with failure, and non-zero is normally `TRUE` which one would naturally assocate with success. 

In addition it's easy for the naive programmer, or even an experienced one who isn't having a good day, to forget to check for errors, both because C doesn't require using returned values, and because the error indicator is of the same type as the normal, successful return value.  The compiler can't tell the difference, and so can't give the programmer any feedback that something is amiss.

And if an error occurs, one has to check the global `errno` value to get the actual error.

You can see why this is error-prone.

NIX uses Swift's features to overcome these deficienciy and divides these into two categories:
    - Functions that simply return success or failure
    - Functions that return a value that use a special value to indicate an failure, otherwise it's a success, and the value has some other use.
    
In both cases, NIX explicitly returns a `NIX.Error`, which already contains the value from `errno`, but the particular method of returning it depends on which category the underlying POSIX function falls into, as described below.  Further NIX never defines any functions as `@discardableResult`, so the caller has to either check it or explicitly discard the result with Swift's anonymous assignment (ie. `_ = foo()`). 

`NIX.Error` conforms both to Swift's `Error` protocol, so you can `throw` it from your code, if you wish, and to `CustomStringConvertible` which obtains the error description internally by calling the POSIX `strerror()` function.
    
#### Success or Fail Functions
For functions whose return value serves no purpose other than to indicate success or failure, NIX returns a `NIX.Error?`.  This makes it obvious that `nil` indicates "no error" (ie. success) and immediately provides the actual error on failure.  For example:

```swift
if let error = NIX.close(file) {
    fatalError("Failed to close file: \(error)")
}
```

#### Value or Error functions
Functions that, on success,  return a value that means something other than merely success return a Swift `Result<Value, NIX.Error>`, where `Value` is the type of the value being returned on success.  For example:

```swift
let file: FileDescriptor
switch NIX.open(filename, .readWrite)
{
    case .success(let fd): file = fd
    case .failure(let error): fatalError("Failed to open file: \(error)")
}
```

### Distinct Parameter and Return Value Types

Another source of errors in the POSIX API is the many overloaded uses of C's `int` even when it doesn't possibly indicate an error.  It is used for file descriptors, option flags, sizes of data, etc...  From the C compiler's point of view, they are all interchangeable.  In Swift those `int`s become `Int32` but their uses are as equally indistinguishable as they are in C.  That means it's easy to use a value obtained from one context, where it has a particular meaning, in another context, where the original meaning is completely invalid.  For example in POSIX, both file descriptors and sockets are `int`s, but one should not use a file descriptor for `bind()`, nor should one use a socket for `lseek()`. The compiler can't do anything to help you out, because from its perspective, one `int` is as good as another.  If you're lucky, the bug is found early at runtime when the system can check the value you passed to `bind()`, for example, and detects that it's not a valid socket, and so `bind()` would fail. 

And yet sometimes the `ints` that represent different things are interchangeable.  For example one can call `close()`, `read()` or `write()` with either a file descriptor or a socket.

We'd like the compiler to help us sort this stuff out at compile-time, and that comes down to creating distinct types for the different meanings, so that is exactly what NIX does.  

For example, NIX defines distinct `FileDescriptor` and `SocketDescriptor` types. Since `NIX.bind()` only accepts a `SocketDescriptor`, and `NIX.open()` only returns a `FileDescriptor`, the compiler won't let you use the value returned by `NIX.open()` in a call to `NIX.bind()`.  But `NIX.close()` accepts any `IODescriptor`, a protocol to which both `SocketDescriptor` and `FileDescriptor` conform, so it can accept either.

Additionally NIX uses distinct `enum` types for mutually exclusive options (for example setting a socket domain).  Each function uses a specific type for its options.  That helps you in two ways.  The first is that you can't use an invalid option for the function.  The second is that IDE autocompletion helps you discover what the valid options are.  Additionally, NIX deviates from the POSIX naming for options to give them more meaningful names.  For example POSIX's `O_RDWR` is `.readWrite`.   

Another overloaded use of `int` in POSIX is for option flags that can be combined with bitwise-OR. Normally only a subset of the bits are meaningful.  Swift handles this by providing specific types that conform to `OptionSet`.  You can bitwise-OR them together just as you would with the POSIX flags, but invalid bits are automatically filtered out.  Alternatively you can use the typical `OptionSet` array syntax to combine them.  Often only a subset of the bits are valid for use in a particular function.  For example while `chmod()` allows a set of flags that includes `S_ISVTX`, which becomes `.saveSwappedText` in NIX, that particular bit is *not* valid for `open()` when creating a file.  NIX defines separate types for these, so `NIX.chmod()` (*not currently implemented*) uses `FileAccessMode`, while `open` uses `OpenFileAccessMode`  which does not incude the `.saveSwappedText` option, so you can't use it thinking it will work, and then have to dig to `man` pages to find out why it doesn't.

The `NIX.open()` example demonstrates another type of safety NIX introduces.  The POSIX definition for that function allows an `O_CREAT` flag to be set in order to create a file, and the `mode` parameter is only required if that bit is set.  So opening a file with the same POSIX function requires only three parameters when not creating the file, and requires four parameters when creating the file.  NIX avoids that confusion by excluding creation bit from `NIX.open(_:_:_:)`'s flags, and instead provides an alternate version, `NIX.open(_:_:_:create:)` to use for file creation.  The same approach is taken for `NIX.openat(_:_:_:_:)`.  Both also separate the read/write access options from the other flags by using a different type for them in a separate parameter.

### Eliminating Pointer Parameters

Obviously one expects a C-based interface, as POSIX.1 is, to use pointers.  Unfortunately, pointers open up tons of opportunities for errors.  NIX has to use pointers to interact with the underlying POSIX API, but it tries to avoid exposing those pointers to the caller, so you can write your Swift code without worrying about those details.  Besides, while Swift does provide pointers in the `Unsafe...Pointer` family of types, those are especially awkward to use, and that's by design.  The language is attempting to discourage their use, while acknowledging that sometimes they are necessary.  Also POSIX.1 provides for some functions, like `readv()` that use pointers in a way that would be exceedingly tricky to get right consistently in Swift.  NIX handles that detail for you.  For example, `NIX.readv()` takes an `inout` array of `Data` instances, and internally steals pointers to their data to build the `iovec` array that POSIX's `readv` expects.  In doing so, it has to use some normally unsafe techniques to defeat Swift's pointer type invalidation, and is only safe because it ensures that the pointers don't escape a scope in which they are known to be valid.  This achieves nearly the same performance as directly using `readv()` in C would have.  The same logical effect could have been achieved without the pointer stealing by emulating `readv` instead of using it directly, but that would require multiple calls to `read`, which would dramatically alter its performance.  NIX tries to do its job while maintaining a 1:1 ratio of NIX-to-POSIX calls.

Where POSIX uses pointers to represent some arbitrary block of bytes, such as a read buffer, NIX uses Foundation's `Data` for the block of bytes, unless the block of bytes is supposed to be C string, in which case it uses a Swift `String`.  When the pointer is to a single `const` instance of a type, NIX uses a Swift value.  For pointers to single non-`const` values, NIX uses `inout` parameters.   When the pointers are used for an array of instances some type, NIX uses a Swift `Array` with elements of that type.   

# Example Code
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
