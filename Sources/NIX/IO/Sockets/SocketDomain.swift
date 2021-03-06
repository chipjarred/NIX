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

// -------------------------------------
public enum SocketDomain: Int32
{
    /// Host-internal protocols, formerly called `.unix`
    case local
    
    /// Host-internal protocols, deprecated, use `.local`
    @available(*, deprecated, renamed: "local")
    case unix
    
    /// Internet version 4 protocols
    case inet4
    
    /// Internet version 6 protocols
    case inet6
    
    /* Unsupported by NIX
     These are defined in Darwin, but NIX doesn't currently support them
    /// Internal Routing protocol
    case route
    
    /// Internal key-management function
    case key
    
    /// System domain
    case system
    
    /// Raw access to network device
    case rawNetworkDevice
    */
    
    // -------------------------------------
    public init?(rawValue: Int32)
    {
        switch rawValue
        {
            case PF_LOCAL  : self = .local
            case PF_INET   : self = .inet4
            case PF_INET6  : self = .inet6
                
            /* Unsupported
            case PF_ROUTE  : self = .route
            case PF_KEY    : self = .key
            case PF_SYSTEM : self = .system
            case PF_NDRV   : self = .rawNetworkDevice
            */
                
            default: return nil
        }
    }
    
    // -------------------------------------
    public var rawValue: Int32
    {
        switch self
        {
            case .local           : return PF_LOCAL
            case .unix            : return PF_LOCAL
            case .inet4           : return PF_INET
            case .inet6           : return PF_INET6
                
            /* Unsupported
            case .route           : return PF_ROUTE
            case .key             : return PF_KEY
            case .system          : return PF_SYSTEM
            case .rawNetworkDevice: return PF_NDRV
            */
        }
    }
}
