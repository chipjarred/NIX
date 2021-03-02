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
 Subset of `SocketAddressFamily` valid for IPv4 sockets
 */
public enum IP4AddressFamily
{
    public typealias RawValue = AddressFamily
    
    case inet4
    case unix
    case xeroxNS
    case arpaIMP
    
    // -------------------------------------
    @inlinable public init?(rawValue: RawValue)
    {
        switch rawValue
        {
            case .inet4  : self = .inet4
            case .unix   : self = .unix
            case .xeroxNS: self = .xeroxNS
            case .arpaIMP: self = .arpaIMP
                
            default: return nil
        }
    }
    
    // -------------------------------------
    @inlinable public init?(rawValue: AddressFamily.RawValue)
    {
        guard let af = RawValue(rawValue: rawValue) else { return nil }
        
        self.init(rawValue: af)
    }

    // -------------------------------------
    @inlinable public var rawValue: RawValue
    {
        switch self
        {
            case .inet4  : return .inet4
            case .unix   : return .unix
            case .xeroxNS: return .xeroxNS
            case .arpaIMP: return .arpaIMP
        }
    }
}
