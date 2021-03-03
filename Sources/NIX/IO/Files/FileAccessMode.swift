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
public struct FileAccessMode: NIXFlags
{
    public typealias RawValue = UInt16
    
    @usableFromInline internal var _rawValue: RawValue
    @inlinable public var rawValue: RawValue { _rawValue }
    
    /// User may read from the file
    public static let ownerRead       = Self(rawValue: HostOS.S_IRUSR)
    
    /// User may write to the file
    public static let ownerWrite      = Self(rawValue: HostOS.S_IWUSR)
    
    /// User may execute the file
    public static let ownerExec       = Self(rawValue: HostOS.S_IXUSR)
    
    /// User may read, write, and execute the file
    /// (same as: `.ownerRead | .ownerWrite | .ownerExec`)
    public static let ownerAll        = Self(rawValue: HostOS.S_IRWXU)
         
    /// Users in the owner's group may read the file
    public static let groupRead       = Self(rawValue: HostOS.S_IRGRP)
    
    /// Users in the owner's group may write to the file
    public static let groupWrite      = Self(rawValue: HostOS.S_IWGRP)
    
    /// Users in the owner's group may execute the file
    public static let groupExec       = Self(rawValue: HostOS.S_IXGRP)
    
    /// Users in the owner's group may read, write, and excute the file
    /// (same as: `.groupRead | .groupWrite | .groupExec`)
    public static let groupAll        = Self(rawValue: HostOS.S_IRWXG)
         
    /// Other users may read the file
    public static let otherRead       = Self(rawValue: HostOS.S_IROTH)
    
    /// Other users may write the file
    public static let otherWrite      = Self(rawValue: HostOS.S_IWOTH)
    
    /// Other users may execute the file
    public static let otherExec       = Self(rawValue: HostOS.S_IXOTH)
    
    /// Other users may read, write, and execute the file
    /// (same as: `.otherRead | .otherWrite | .otherExec`)
    public static let otherAll        = Self(rawValue: HostOS.S_IRWXO)
         
    /**
     When executed, set the process's user id to the owner's user id.

     Writing or changing the owner of a file turns off the set-user-id and
     set-group-id bits unless the user is the super-user.  This makes the
     system somewhat more secure by protecting set-user-id (set-group-id) files
     from remaining set-user-id (set-group-id) if they are modified, at the
     expense of a degree of compatibility.
     */
    public static let setUserID       = Self(rawValue: HostOS.S_ISUID)
    
    /**
     When executed, set the process's group id to the owner's group id.
     
     Writing or changing the owner of a file turns off the set-user-id and
     set-group-id bits unless the user is the super-user.  This makes the
     system somewhat more secure by protecting set-user-id (set-group-id) files
     from remaining set-user-id (set-group-id) if they are modified, at the
     expense of a degree of compatibility.
     */
    public static let setGroupID      = Self(rawValue: HostOS.S_ISGID)
    
    /**
     Save swapped text, even after use
     
     Also known as the "sticky bit", this indicates to the system which
     executable files are shareable (the default) and the system maintains the
     program text of the files in the swap area. The sticky bit may only be set
     by the super user on shareable executable files.
     
     `.saveSwappedText` is set on a directory, an unprivileged user may not
     delete or rename files of other users in that directory. The sticky bit
     may be set by any user on a directory which the user owns or has
     appropriate permissions.  For more details of the properties of the sticky
     bit, see `man 7 sticky`
     */
    public static let saveSwappedText = Self(rawValue: HostOS.S_ISVTX)

    public static let all = Self(
        [
            .ownerRead,
            .ownerWrite,
            .ownerExec,
            .groupRead,
            .groupWrite,
            .groupExec,
            .otherRead,
            .otherWrite,
            .otherExec,
            .setUserID,
            .setGroupID,
            .saveSwappedText
        ]
    )
    
    // -------------------------------------
    @inlinable public init(rawValue: RawValue) {
        self._rawValue = rawValue
    }
}
