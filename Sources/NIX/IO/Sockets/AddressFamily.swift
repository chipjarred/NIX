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
public enum AddressFamily
{
    public typealias RawValue = Int32
    
    /// unspecified
    case unspecified
    
    /// local to host (pipes)
    case unix
    
    /// backward compatibility
    case local
    
    /// internetwork: UDP, TCP, etc.
    case inet4
    
    /// arpanet imp addresses
    case arpaIMP
    
    /// pup protocols: e.g. BSP
    case pup
    
    /// MIT CHAOS protocols
    case mitCHAOS
    
    /// XEROX NS protocols
    case xeroxNS
    
    /// ISO protocol
    case ios
    
    /// ISO protocol
    case osi
    
    /// European computer manufacturers
    case ECMA
    
    /// datakit protocols
    case dataKit
    
    /// CCITT protocols, X.25 etc
    case CCITT
    
    /// IBM SNA
    case ibmSNA
    
    /// DECnet
    case decNet
    
    /// DEC Direct data link interface
    case decDataLinkInterface
    
    /// LAT
    case LAT
    
    /// NSC Hyperchannel
    case nscHyperchannel
    
    /// Apple Talk
    case appleTalk
    
    /// Internal Routing Protocol
    case route
    
    /// Link layer interface
    case link
    
    /// eXpress Transfer Protocol (no AF)
    case eXpressTransferProtocol
    
    /// connection-oriented IP, aka ST II
    case connectionOrientedIP
    
    /// Computer Network Technology
    case computerNetworkTechnology
    
    /// Help Identify RTIP packets
    case helpIdentityRTIP
    
    /// Novell Internet Protocol
    case novellIPX
    
    /// Simple Internet Protocol
    case simpleInternetProtocol
    
    /// Help Identify PIP packets
    case helpIdentityPIP
    
    /// Network Driver 'raw' access
    case networkDriverRaw
    
    /// Integrated Services Digital Network
    case isdn
    
    /// CCITT E.164 recommendation
    case ccittE164
    
    /// Internal key-management function
    case internalKeyManagement
    
    /// IPv6
    case inet6
    
    /// native ATM access
    case nativeATMAccess
    
    /// Kernel event messages
    case system
    
    /// NetBIOS
    case netBIOS
    
    /// PPP communication protocol
    case ppp
    
    /// Used by BPF to not rewrite headers in interface output routine
    case pseudo_AF_HDRCMPLT
    
    /// IEEE 802.11 protocol
    case ieee802_11
    
    /// User tunnel acts as glue between kernel control sockets and network interfaces
    case userTunnel

    // -------------------------------------
    public init?(rawValue: Int32)
    {
        switch rawValue
        {
            case HostOS.AF_UNSPEC          : self = .unspecified
            case HostOS.AF_UNIX            : self = .unix
            case HostOS.AF_LOCAL           : self = .local
            case HostOS.AF_INET            : self = .inet4
            case HostOS.AF_IMPLINK         : self = .arpaIMP
            case HostOS.AF_PUP             : self = .pup
            case HostOS.AF_CHAOS           : self = .mitCHAOS
            case HostOS.AF_NS              : self = .xeroxNS
            case HostOS.AF_ISO             : self = .ios
            case HostOS.AF_OSI             : self = .osi
            case HostOS.AF_ECMA            : self = .ECMA
            case HostOS.AF_DATAKIT         : self = .dataKit
            case HostOS.AF_CCITT           : self = .CCITT
            case HostOS.AF_SNA             : self = .ibmSNA
            case HostOS.AF_DECnet          : self = .decNet
            case HostOS.AF_DLI             : self = .decDataLinkInterface
            case HostOS.AF_LAT             : self = .LAT
            case HostOS.AF_HYLINK          : self = .nscHyperchannel
            case HostOS.AF_APPLETALK       : self = .appleTalk
            case HostOS.AF_ROUTE           : self = .route
            case HostOS.AF_LINK            : self = .link
            case HostOS.pseudo_AF_XTP      : self = .eXpressTransferProtocol
            case HostOS.AF_COIP            : self = .connectionOrientedIP
            case HostOS.AF_CNT             : self = .computerNetworkTechnology
            case HostOS.pseudo_AF_RTIP     : self = .helpIdentityRTIP
            case HostOS.AF_IPX             : self = .novellIPX
            case HostOS.AF_SIP             : self = .simpleInternetProtocol
            case HostOS.pseudo_AF_PIP      : self = .helpIdentityPIP
            case HostOS.AF_NDRV            : self = .networkDriverRaw
            case HostOS.AF_ISDN            : self = .isdn
            case HostOS.AF_E164            : self = .ccittE164
            case HostOS.pseudo_AF_KEY      : self = .internalKeyManagement
            case HostOS.AF_INET6           : self = .inet6
            case HostOS.AF_NATM            : self = .nativeATMAccess
            case HostOS.AF_SYSTEM          : self = .system
            case HostOS.AF_NETBIOS         : self = .netBIOS
            case HostOS.AF_PPP             : self = .ppp
            case HostOS.pseudo_AF_HDRCMPLT : self = .pseudo_AF_HDRCMPLT
            case HostOS.AF_IEEE80211       : self = .ieee802_11
            case HostOS.AF_UTUN            : self = .userTunnel
                
            default: return nil
        }
    }
    
    // -------------------------------------
    public var rawValue: Int32
    {
        switch self
        {
            case .unspecified               : return HostOS.AF_UNSPEC
            case .unix                      : return HostOS.AF_UNIX
            case .local                     : return HostOS.AF_LOCAL
            case .inet4                     : return HostOS.AF_INET
            case .arpaIMP                   : return HostOS.AF_IMPLINK
            case .pup                       : return HostOS.AF_PUP
            case .mitCHAOS                  : return HostOS.AF_CHAOS
            case .xeroxNS                   : return HostOS.AF_NS
            case .ios                       : return HostOS.AF_ISO
            case .osi                       : return HostOS.AF_OSI
            case .ECMA                      : return HostOS.AF_ECMA
            case .dataKit                   : return HostOS.AF_DATAKIT
            case .CCITT                     : return HostOS.AF_CCITT
            case .ibmSNA                    : return HostOS.AF_SNA
            case .decNet                    : return HostOS.AF_DECnet
            case .decDataLinkInterface      : return HostOS.AF_DLI
            case .LAT                       : return HostOS.AF_LAT
            case .nscHyperchannel           : return HostOS.AF_HYLINK
            case .appleTalk                 : return HostOS.AF_APPLETALK
            case .route                     : return HostOS.AF_ROUTE
            case .link                      : return HostOS.AF_LINK
            case .eXpressTransferProtocol   : return HostOS.pseudo_AF_XTP
            case .connectionOrientedIP      : return HostOS.AF_COIP
            case .computerNetworkTechnology : return HostOS.AF_CNT
            case .helpIdentityRTIP          : return HostOS.pseudo_AF_RTIP
            case .novellIPX                 : return HostOS.AF_IPX
            case .simpleInternetProtocol    : return HostOS.AF_SIP
            case .helpIdentityPIP           : return HostOS.pseudo_AF_PIP
            case .networkDriverRaw          : return HostOS.AF_NDRV
            case .isdn                      : return HostOS.AF_ISDN
            case .ccittE164                 : return HostOS.AF_E164
            case .internalKeyManagement     : return HostOS.pseudo_AF_KEY
            case .inet6                     : return HostOS.AF_INET6
            case .nativeATMAccess           : return HostOS.AF_NATM
            case .system                    : return HostOS.AF_SYSTEM
            case .netBIOS                   : return HostOS.AF_NETBIOS
            case .ppp                       : return HostOS.AF_PPP
            case .pseudo_AF_HDRCMPLT        : return HostOS.pseudo_AF_HDRCMPLT
            case .ieee802_11                : return HostOS.AF_IEEE80211
            case .userTunnel                : return HostOS.AF_UTUN
        }
    }
}
