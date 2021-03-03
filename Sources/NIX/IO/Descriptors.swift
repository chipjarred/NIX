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

// -------------------------------------
public protocol IODescriptor {
    var descriptor: Int32 { get }
}
public protocol FileIODescriptor: IODescriptor {}

// MARK:- FileDescriptor
// -------------------------------------
public struct FileDescriptor: FileIODescriptor
{
    public let descriptor: Int32
    
    @usableFromInline
    internal init(_ fd: Int32)
    {
        assert(fd > 0)
        self.descriptor = fd
    }
}


// MARK:- General BSDescriptor I/O
// -------------------------------------
@inlinable
public func close(_ socket: IODescriptor) -> Error?
{
    let result = close(socket.descriptor)
    return result == -1
        ? Error()
        : nil
}

// -------------------------------------
/**
 Read data from an object (ie file, socket, pipe, etc...) referenced by a
 descriptor into a pre-allocated buffer.
 
 The maximum number of bytes that will be read is determined by `buffer.count`,
 so `buffer` should be initialized to the desired number elements prior to
 calling this function. Use `Data(repeating: 0, count: n)` *not*
 `Data(capacity: n)`)
 
 The system guarantees to read the number of bytes requested if the descriptor
 references a normal file that has that many bytes left before the end-of-file,
 but in no other case.
 
 - Parameters:
    - descriptor: The descriptor representing the object from which to read.
    - buffer: a *pre-allocated* `Data` instance into which place the data.
        - On entry, it's current `count` property will determine the maximum
            number of bytes that will be read.
        - On exit, it will contain the read data, *but it's `count` will not
            have been modified.*  Use the returned number of bytes read to
            determine how many of the bytes of `buffer` correspond to the data
            read.
 
 - Returns: On success, the returned `Result` will contain the number of bytes
    read.  `0` indicates an attempt to read at the end-of-file.  On failure, the
    returned `Result` will contain the error describing the reason for the
    failure.
 */
@inlinable
public func read(
    _ descriptor: IODescriptor,
    _ buffer: inout Data) -> Result<Int, Error>
{
    assert(buffer.count > 0)
    
    return buffer.withUnsafeMutableBytes
    {
        let bytesRead = HostOS.read(
            descriptor.descriptor,
            $0.baseAddress!,
            $0.count
        )
        return bytesRead == -1
            ? .failure(Error())
            : .success(bytesRead)
    }
}


// -------------------------------------
/**
 Read data from an object (ie file, socket, pipe, etc...) referenced by a
 descriptor into an array of pre-allocated buffers.
 
 The array of buffers is sometimes referred to as a "scatter/gather" array.
 Its elements are *pre-allocated* `Data` instances, which is to say that each
 one must be initialized containing the desired number of bytes.  Use
 `Data(repeating: 0, count: n)` *not* `Data(capacity: n)`)
 
 The maximum number of bytes that will be read is determined by sum of all of
 the sizes of the buffers in `buffers`.  Each buffer in the array will be
 entirely filled before starting to fill the next one.
 
 The system guarantees to read the number of bytes requested if the descriptor
 references a normal file that has that many bytes left before the end-of-file,
 but in no other case.
 
 - Parameters:
    - descriptor: The descriptor representing the object from which to read.
    - buffers: an array of *pre-allocated* `Data` instances into which place
        the data.
        - On entry, the `count` property for each `Data` element of
            `buffers` will determine the maximum number of bytes that will be
            read into it before moving on to the next one.
        - On exit, the buffers' `count` properties will not have been changed.
            Use the returned number of bytes read, along with the sizes of each
            buffer, to determine which buffers and how much of them contain the
            read data.
 
 - Returns: On success, the returned `Result` will contain the number of bytes
    read.  `0` indicates an attempt to read at the end-of-file.  On failure, the
    returned `Result` will contain the error describing the reason for the
    failure.
 */
@inlinable
public func readv(
    _ descriptor: IODescriptor,
    _ buffers: inout [Data]) -> Result<Int, Error>
{
    assert(buffers.count > 0)
    
    let iovecs = buffers.mutableIOVecs()
    return iovecs.withUnsafeBufferPointer
    {
        let bytesRead:Int = HostOS.readv(
            descriptor.descriptor,
            $0.baseAddress!,
            Int32($0.count)
        )
        return bytesRead == -1
            ? .failure(Error())
            : .success(bytesRead)
    }
}

// -------------------------------------
/**
 Write the bytes in `buffer` to the object (ie. file, socket, pipe, etc...)
 referenced by `descriptor`.
 
 - Parameters:
    - descriptor: The descriptor for the object to be written to.
    - buffer: `Data` instance containing the data to be written.
 
 - Returns: On success, the returned `Result` contains the number of bytes
    written.  On failure, it contains the `Error` describing the reason for
    the failure.
 */
@inlinable
public func write(
    _ descriptor: IODescriptor,
    _ buffer: Data) -> Result<Int, Error>
{
    return buffer.withUnsafeBytes
    {
        let bytesWritten = write(
            descriptor.descriptor,
            $0.baseAddress!,
            $0.count
        )
        return bytesWritten == -1
            ? .failure(Error())
            : .success(bytesWritten)
    }
}

// -------------------------------------
/**
 Write the bytes from an array of buffers to the object (ie. file, socket,
 pipe, etc...)  referenced by `descriptor`.
 
 Each buffer in `buffers` is written in its entirety before starting to write
 the next one.  The effect is the same as concatenating their contents, and
 writing the resulting concatenation.
 
 - Parameters:
    - descriptor: The descriptor for the object to be written to.
    - buffers: An array of `Data` instances containing the data to be written.
 
 - Returns: On success, the returned `Result` contains the number of bytes
    written.  On failure, it contains the `Error` describing the reason for
    the failure.
 */
@inlinable
public func writev(
    _ descriptor: IODescriptor,
    _ buffers: [Data]) -> Result<Int, Error>
{
    let iovecs = buffers.iovecs()
    return iovecs.withUnsafeBufferPointer
    {
        let bytesWritten = writev(
            descriptor.descriptor,
            $0.baseAddress!,
            Int32($0.count)
        )
        return bytesWritten == -1
            ? .failure(Error())
            : .success(bytesWritten)
    }
}
