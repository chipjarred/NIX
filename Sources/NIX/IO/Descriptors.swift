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
@inlinable
public func read(
    _ socket: IODescriptor,
    _ buffer: inout Data) -> Result<Int, Error>
{
    assert(buffer.count > 0)
    
    return buffer.withUnsafeMutableBytes
    {
        let bytesRead = read(
            socket.descriptor,
            $0.baseAddress!,
            $0.count
        )
        return bytesRead == -1
            ? .failure(Error())
            : .success(bytesRead)
    }
}

// -------------------------------------
@inlinable
public func write(
    _ socket: IODescriptor,
    _ buffer: Data) -> Result<Int, Error>
{
    return buffer.withUnsafeBytes
    {
        let bytesWritten = write(
            socket.descriptor,
            $0.baseAddress!,
            $0.count
        )
        return bytesWritten == -1
            ? .failure(Error())
            : .success(bytesWritten)
    }
}
