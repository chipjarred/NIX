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

// -------------------------------------
/**
 Protocol to which all type-safe option flags for NIX functions should conform.

 Provides basic boiler plate code
 */
public protocol NIXFlags: OptionSet where RawValue: FixedWidthInteger
{
    /// All flags combined.
    static var all: Self { get }
}

// -------------------------------------
public extension NIXFlags
{
    /// No options.  Use default behavior
    @inlinable static var none: Self { Self([]) }
    
    // -------------------------------------
    @inlinable mutating func formUnion(_ other: Self) {
        self = self | other
    }
    
    // -------------------------------------
    @inlinable mutating func formIntersection(_ other: Self) {
        self = self & other
    }
    
    // -------------------------------------
    @inlinable mutating func formSymmetricDifference(_ other: Self) {
        self = self ^ other
    }
    
    // -------------------------------------
    @inlinable static prefix func ~(flags: Self) -> Self
    {
        // The bitwise compliment by itself might set illegal bits,
        // so bitwise-and with `all` to filter them out.
        return Self(rawValue: ~flags.rawValue & all.rawValue)
    }

    // -------------------------------------
    @inlinable static func | (left: Self, right: Self) -> Self {
        return Self(rawValue: left.rawValue | right.rawValue)
    }
    
    // -------------------------------------
    @inlinable static func & (left: Self, right: Self) -> Self {
        return Self(rawValue: left.rawValue & right.rawValue)
    }
    
    // -------------------------------------
    @inlinable static func ^ (left: Self, right: Self) -> Self {
        return (left | right) & ~(left & right)
    }
}
