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

import Foundation

/**
 OS-independent spin lock suitable for fast, low-contention resource locking.
 
 Access to guarded resources should be enclosed inside a `withLock` closure.  For example
 
     private var lock = SharedLock()
     private var _sharedInt: Int = 0
     public var sharedInt: Int
     {
        get { return lock.withLock { _sharedInt } }
        set { lock.withLock { _sharedInt = newValue } }
     }
 
 The lock is obtained and relased automatically by `withLock`.  `withLock` will
 block until the lock is obtained, and then execute the provided closure.
 
 `withAttemptedLock` is also provided to allow the possibility of not blocking
 (and therefore not executing the provided closure) if the lock cannot be
 obtained immediately.  For example:
 
     func enqueue<T>(_ value: T, whileWaitingDo block: () -> Void)
     {
         while true
         {
             switch lock.withAttemptedLock( { sharedQueue.enqueue(value) } )
             {
                 case .success(_): return
                 case .failure(let error):
                     if error == SpinLock.Error.tryLockFailed
                     {
                         block()
                         continue
                     }
                     else {
                         fatalError("Unexpected error: \(error.localizedDescription)")
                     }
             }
         }
     }
 */
public struct SpinLock
{
    #if canImport(Darwin)
    @usableFromInline var osLock = os_unfair_lock()
    
    @usableFromInline @inline(__always)
    internal mutating func lock() { os_unfair_lock_lock(&osLock) }
    
    @usableFromInline @inline(__always)
    internal mutating func unlock() { os_unfair_lock_unlock(&osLock) }
    
    @usableFromInline @inline(__always)
    internal mutating func tryLock() -> Bool { os_unfair_lock_trylock(&osLock) }
    
    #elseif canImport(Glibc)
    #warning("This definition of SpinLock needs checking on Linux")
    /*
     What follows is my guess at an implementation for Linux.  I don't have Linux
     installed to try to compiler or test it, so someone who is using Swift on
     Linux should flesh this out.
     
     It would be better to define it as a struct instead of a class, but
     documentation shows there is spin_uninit().  It doesn't discuss what the
     implications are if a Linux spinLock is not uninitialized, so to be on the
     safe side, I've made it a class so that it will have a deinit to call
     spin_uninit().  However, making it class means locking must go through an
     extra level of indirection, which is less than ideal.
     
     Another problem with this is that it has different semantics from the
     Darwin version.  If the lock is used correctly, it should never be copied,
     so so the reference semantics aren't a problem.
     
     -- Chip Jarred 3/5/2021
     */
    internal final class LinuxLock
    {
        @usableFromInline var osLock: spinlock
        
        @inlinable public init() { spin_init(&osLock) }
        deinit { spin_uninit(&osLock) }
        
        @usableFromInline @inline(__always)
        internal mutating func lock() { spin_lock(&osLock) }
        
        /*
         Online man page says that in C spin_trylock() returns boolean_t.  How does
         Swift on Linux import this?  If it's not as Bool, then this tryLock
         implementation needs to translate boolean_t into Bool.  For now I'm
         assuming does import it as Bool.
         */
        @usableFromInline @inline(__always)
        internal mutating func tryLock() -> Bool { spin_trylock(&osLock) }

        @usableFromInline @inline(__always)
        internal mutating func unlock() { spin_unlock(&osLock) }
    }
    
    @usableFromInline var osLock = LinuxLock()
    
    @usableFromInline @inline(__always)
    internal mutating func lock() { osLock.lock() }
    
    @usableFromInline @inline(__always)
    internal mutating func tryLock() -> Bool { osLock.tryLock() }

    @usableFromInline @inline(__always)
    internal mutating func unlock() { osLock.unlock() }
    #else
    #error("Define SpinLock with same interface as for Darwin - see above")
    #endif
}

// -------------------------------------
public extension SpinLock
{
    enum Error: Swift.Error
    {
        /// `SpinLock.withAttemptedLock()` failed to obtain the requested lock.
        /// The provided closure was *not* executed.
        case tryLockFailed
    }
    
    // -------------------------------------
    /**
     Perform the specified closure with a lock obtained on this `SpinLock`.
     
     The lock first obtained, then `block` is called, then the lock is
     released, even if an exception is thrown.
     
     - Parameter block: closure to be run after lock is obtained.
     */
    @inlinable
    mutating func withLock<R>(_ block: () throws -> R) rethrows -> R
    {
        lock(); defer { unlock() }
        return try block()
    }
    
    // -------------------------------------
    /**
     Attempt to perform the specified closure with a lock obtained on this
     `SpinLock`.
     
     If the lock can be obtained without blocking, it is obtained, and `block`
     is called, then the lock is released, even if an exception is thrown.
     
     If obtaining the lock would block, it is not obtained, and `block` is not
     called.
     
     - Parameter block: closure to be run after lock is obtained.
     
     - Returns: On successfully obtaining the lock, a `Result` is returned
        containing the value returned by `block`.  On failure to obtain the
        lock, the returned Result is `.failure(Error.tryLockFailed)`.
     */
    @inlinable
    mutating func withAttemptedLock<R>(
        _ block: () throws -> R) rethrows -> Result<R, Error>
    {
        guard tryLock() else { return .failure(.tryLockFailed) }
        defer { unlock() }
        return .success(try block())
    }
}
