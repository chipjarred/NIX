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
public struct OpenFlags: NIXFlags
{
    public typealias RawValue = Int32
    
    @usableFromInline internal var _rawValue: RawValue
    @inlinable public var rawValue: RawValue { _rawValue }
    
    /// Do not block on `open` or for data to become available
    public static let nonblocking = Self(rawValue: HostOS.O_NONBLOCK)
    
    /// Append on each write
    public static let append = Self(rawValue: HostOS.O_APPEND)
    
    /// Truncate size to 0
    public static let truncate = Self(rawValue: HostOS.O_TRUNC)
    
    /// Error if `.create` and the file exists
    public static let errorOnCreationIfFileExists =
        Self(rawValue: HostOS.O_EXCL)
    
    /// Atomically obtain a shared lock
    public static let sharedLock = Self(rawValue: HostOS.O_SHLOCK)
    
    /// Atomically obtain an exclusive lock
    public static let exclusiveLock = Self(rawValue: HostOS.O_EXLOCK)
    
    /// Do not follow symlinks
    public static let dontFollowSymLinks = Self(rawValue: HostOS.O_NOFOLLOW)
    
    /// Allow open of symlinks
    public static let allowOpeningSymlinks = Self(rawValue: HostOS.O_SYMLINK)
    
    /// Descriptor requested for event notifications only
    public static let eventNotificationsOnly = Self(rawValue: HostOS.O_EVTONLY)
    
    /// Mark as close-on-exec
    public static let closeOnExec = Self(rawValue: HostOS.O_CLOEXEC)
    
    public static let all = Self(
        [
            .nonblocking,
            .append,
            .truncate,
            .errorOnCreationIfFileExists,
            .sharedLock,
            .exclusiveLock,
            .dontFollowSymLinks,
            .allowOpeningSymlinks,
            .eventNotificationsOnly,
            .closeOnExec
        ]
    )
    
    // -------------------------------------
    @inlinable public init(rawValue: RawValue) {
        self._rawValue = rawValue
    }
}
