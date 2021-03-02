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

// MARK:- Types
// -------------------------------------
/// Legal flags to be used with `unlinkat`
public struct UnlinkAtFlags: NIXFlags
{
    public typealias RawValue = Int32
    
    @usableFromInline internal var _rawValue: RawValue
    @inlinable public var rawValue: RawValue { _rawValue }
    
    /// Remove the directory entry specified by `fd` and `path` as a directory, not a normal file
    public static let removeDir = Self(rawValue: HostOS.AT_REMOVEDIR)
    
    public static let all = Self([removeDir])
    
    // -------------------------------------
    @inlinable public init(rawValue: RawValue) {
        self._rawValue = rawValue
    }
}

// MARK:- Functions
// -------------------------------------
/**
 Removes a  file whose name is given by path.
 
 - Parameter path: path to the directory to be removed.  If `path`
    specifies a relative path, it is relative to the current working
    directory.
 
 - Returns: On success, `nil` is returned.  On failure the `Error` is
    returned.
 */
@inlinable public func remove(_ path: String) -> Error?
{
    return path.withCString {
        return remove($0) == 0 ? nil : Error()
    }
}

// -------------------------------------
/**
 Removes a directory file whose name is given by path.
 
 The directory must not have any entries other than `.` and `..`.
 
 - Parameter path: path to the directory to be removed.  If `path`
    specifies a relative path, it is relative to the current working
    directory.
 
 - Returns: On success, `nil` is returned.  On failure the `Error` is
    returned.
 */
@inlinable public func rmdir(_ path: String) -> Error?
{
    return path.withCString {
        return rmdir($0) == 0 ? nil : Error()
    }
}

// -------------------------------------
/**
 Removes the link named by `path` from its directory and decrements the link
 count of the file which was referenced by the link.
 
 If that decrement reduces the link count of the file to zero, and no
 process has the file open, then all resources associated with the file are
 reclaimed.
 
 If one or more processes have the file open when the last link is removed,
 the link is removed, but the removal of the file is delayed until all
 references to it have been closed.
 
 - Note: if `path` is a relative path, it is relative to the current working directory
 
 - Parameter path: path to the link to be removed.
 
 - Returns: On success, `nil` is returned.  On failure the `Error` is
    returned.
 */
@inlinable public func unlink(_ path: String) -> Error?
{
    return path.withCString {
        return unlink($0) == 0 ? nil : Error()
    }
}

// -------------------------------------
/**
 Removes the link named by `path` from its directory and decrements the link
 count of the file which was referenced by the link.
 
 If that decrement reduces the link count of the file to zero, and no
 process has the file open, then all resources associated with the file are
 reclaimed.
 
 If one or more processes have the file open when the last link is removed,
 the link is removed, but the removal of the file is delayed until all
 references to it have been closed.
 
 - Note: if `path` is a relative path, it is relative to the directory
    specified `fd`

 - Parameters:
    - fd: Optional file descriptor for a directory.  If set and `path` is a
        relative path, it is relative to `fd`.  If `fd` is `nil`, the
        current working directory is used.
    - path: path to the link to be removed
    - flags: if set to `.removeDir`, `fd` and `path` are taken to be a
        directory entry not a normal file.  The default is `.none`
 
 - Returns: On success, `nil` is returned.  On failure the `Error` is
    returned.
 */
@inlinable
public func unlinkat(
    _ fd: FileIODescriptor? = nil,
    _ path: String,
    flags: UnlinkAtFlags = .none) -> Error?
{
    return path.withCString
    {
        let result = unlinkat(
            fd?.descriptor ?? AT_FDCWD,
            $0,
            flags.rawValue
        )
        return result == 0  ? nil : Error()
    }
}
