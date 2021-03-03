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
public enum ProtocolFamily: Int32
{
    // MARK:- Supported Protocol Families
    // -------------------------------------
    /// dummy for IP
    case ip
    
    /// IPv4 encapsulation
    case ip4
    
    /// tcp
    case tcp
    
    /// user datagram protocol
    case udp

    /// IP6 header
    case ipv6

    // MARK:- Unsupported Protocol Families
    // -------------------------------------
    /* Rename to an appropriately descriptive, Swifty name when adding support
     
    /// IP6 hop-by-hop options
    case IPPROTO_HOPOPTS
    
    /// control message protocol
    case IPPROTO_ICMP
    
    /// group mgmt protocol
    case IPPROTO_IGMP
    
    /// gateway^2 (deprecated)
    case IPPROTO_GGP
    
    /// for compatibility
    case IPPROTO_IPIP
    
    /// Stream protocol II
    case IPPROTO_ST
    
    /// exterior gateway protocol
    case IPPROTO_EGP
    
    /// private interior gateway
    case IPPROTO_PIGP
    
    /// BBN RCC Monitoring
    case IPPROTO_RCCMON
    
    /// network voice protocol
    case IPPROTO_NVPII
    
    /// pup
    case IPPROTO_PUP
    
    /// Argus
    case IPPROTO_ARGUS
    
    /// EMCON
    case IPPROTO_EMCON
    
    /// Cross Net Debugger
    case IPPROTO_XNET
    
    /// Chaos
    case IPPROTO_CHAOS
    
    /// Multiplexing
    case IPPROTO_MUX
    
    /// DCN Measurement Subsystems
    case IPPROTO_MEAS
    
    /// Host Monitoring
    case IPPROTO_HMP
    
    /// Packet Radio Measurement
    case IPPROTO_PRM
    
    /// xns idp
    case IPPROTO_IDP
    
    /// Trunk-1
    case IPPROTO_TRUNK1
    
    /// Trunk-2
    case IPPROTO_TRUNK2
    
    /// Leaf-1
    case IPPROTO_LEAF1
    
    /// Leaf-2
    case IPPROTO_LEAF2
    
    /// Reliable Data
    case IPPROTO_RDP
    
    /// Reliable Transaction
    case IPPROTO_IRTP
    
    /// tp-4 w/ class negotiation
    case IPPROTO_TP
    
    /// Bulk Data Transfer
    case IPPROTO_BLT
    
    /// Network Services
    case IPPROTO_NSP
    
    /// Merit Internodal
    case IPPROTO_INP
    
    /// Sequential Exchange
    case IPPROTO_SEP
    
    /// Third Party Connect
    case IPPROTO_3PC
    
    /// InterDomain Policy Routing
    case IPPROTO_IDPR
    
    /// XTP
    case IPPROTO_XTP
    
    /// Datagram Delivery
    case IPPROTO_DDP
    
    /// Control Message Transport
    case IPPROTO_CMTP
    
    /// TP++ Transport
    case IPPROTO_TPXX
    
    /// IL transport protocol
    case IPPROTO_IL
    
    /// Source Demand Routing
    case IPPROTO_SDRP
    
    /// IP6 routing header
    case IPPROTO_ROUTING
    
    /// IP6 fragmentation header
    case IPPROTO_FRAGMENT
    
    /// InterDomain Routing
    case IPPROTO_IDRP
    
    /// resource reservation
    case IPPROTO_RSVP
    
    /// General Routing Encap.
    case IPPROTO_GRE
    
    /// Mobile Host Routing
    case IPPROTO_MHRP
    
    /// BHA
    case IPPROTO_BHA
    
    /// IP6 Encap Sec. Payload
    case IPPROTO_ESP
    
    /// IP6 Auth Header
    case IPPROTO_AH
    
    /// Integ. Net Layer Security
    case IPPROTO_INLSP
    
    /// IP with encryption
    case IPPROTO_SWIPE
    
    /// Next Hop Resolution
    case IPPROTO_NHRP
    
    /// ICMP6
    case IPPROTO_ICMPV6
    
    /// IP6 no next header
    case IPPROTO_NONE
    
    /// IP6 destination option
    case IPPROTO_DSTOPTS
    
    /// any host internal protocol
    case IPPROTO_AHIP
    
    /// CFTP
    case IPPROTO_CFTP
    
    /// "hello" routing protocol
    case IPPROTO_HELLO
    
    /// SATNET/Backroom EXPAK
    case IPPROTO_SATEXPAK
    
    /// Kryptolan
    case IPPROTO_KRYPTOLAN
    
    /// Remote Virtual Disk
    case IPPROTO_RVD
    
    /// Pluribus Packet Core
    case IPPROTO_IPPC
    
    /// Any distributed FS
    case IPPROTO_ADFS
    
    /// Satnet Monitoring
    case IPPROTO_SATMON
    
    /// VISA Protocol
    case IPPROTO_VISA
    
    /// Packet Core Utility
    case IPPROTO_IPCV
    
    /// Comp. Prot. Net. Executive
    case IPPROTO_CPNX
    
    /// Comp. Prot. HeartBeat
    case IPPROTO_CPHB
    
    /// Wang Span Network
    case IPPROTO_WSN
    
    /// Packet Video Protocol
    case IPPROTO_PVP
    
    /// BackRoom SATNET Monitoring
    case IPPROTO_BRSATMON
    
    /// Sun net disk proto (temp.)
    case IPPROTO_ND
    
    /// WIDEBAND Monitoring
    case IPPROTO_WBMON
    
    /// WIDEBAND EXPAK
    case IPPROTO_WBEXPAK
    
    /// ISO cnlp
    case IPPROTO_EON
    
    /// VMTP
    case IPPROTO_VMTP
    
    /// Secure VMTP
    case IPPROTO_SVMTP
    
    /// Banyon VINES
    case IPPROTO_VINES
    
    /// TTP
    case IPPROTO_TTP
    
    /// NSFNET-IGP
    case IPPROTO_IGP
    
    /// dissimilar gateway prot.
    case IPPROTO_DGP
    
    /// TCF
    case IPPROTO_TCF
    
    /// Cisco/GXS IGRP
    case IPPROTO_IGRP
    
    /// OSPFIGP
    case IPPROTO_OSPFIGP
    
    /// Strite RPC protocol
    case IPPROTO_SRPC
    
    /// Locus Address Resoloution
    case IPPROTO_LARP
    
    /// Multicast Transport
    case IPPROTO_MTP
    
    /// AX.25 Frames
    case IPPROTO_AX25
    
    /// IP encapsulated in IP
    case IPPROTO_IPEIP
    
    /// Mobile Int.ing control
    case IPPROTO_MICP
    
    /// Semaphore Comm. security
    case IPPROTO_SCCSP
    
    /// Ethernet IP encapsulation
    case IPPROTO_ETHERIP
    
    /// encapsulation header
    case IPPROTO_ENCAP
    
    /// any private encr. scheme
    case IPPROTO_APES
    
    /// GMTP
    case IPPROTO_GMTP
    
    /// Protocol Independent Mcast
    case IPPROTO_PIM
    
    /// payload compression (IPComp)
    case IPPROTO_IPCOMP
    
    /// PGM
    case IPPROTO_PGM
    
    /// SCTP
    case IPPROTO_SCTP
    
    /// divert pseudo-protocol
    case IPPROTO_DIVERT
    
    /// raw IP packet
    case raw
    */

    // -------------------------------------
    public init?(rawValue: Int32)
    {
        switch rawValue
        {
            case HostOS.IPPROTO_IP        : self = .ip
            case HostOS.IPPROTO_IPV4      : self = .ip4
            case HostOS.IPPROTO_TCP       : self = .tcp
            case HostOS.IPPROTO_UDP       : self = .udp
            case HostOS.IPPROTO_IPV6      : self = .ipv6

            /* Unsupported currently in NIX
            case HostOS.IPPROTO_HOPOPTS   : self = .IPPROTO_HOPOPTS
            case HostOS.IPPROTO_ICMP      : self = .IPPROTO_ICMP
            case HostOS.IPPROTO_IGMP      : self = .IPPROTO_IGMP
            case HostOS.IPPROTO_GGP       : self = .IPPROTO_GGP
            case HostOS.IPPROTO_IPIP      : self = .IPPROTO_IPIP
            case HostOS.IPPROTO_ST        : self = .IPPROTO_ST
            case HostOS.IPPROTO_EGP       : self = .IPPROTO_EGP
            case HostOS.IPPROTO_PIGP      : self = .IPPROTO_PIGP
            case HostOS.IPPROTO_RCCMON    : self = .IPPROTO_RCCMON
            case HostOS.IPPROTO_NVPII     : self = .IPPROTO_NVPII
            case HostOS.IPPROTO_PUP       : self = .IPPROTO_PUP
            case HostOS.IPPROTO_ARGUS     : self = .IPPROTO_ARGUS
            case HostOS.IPPROTO_EMCON     : self = .IPPROTO_EMCON
            case HostOS.IPPROTO_XNET      : self = .IPPROTO_XNET
            case HostOS.IPPROTO_CHAOS     : self = .IPPROTO_CHAOS
            case HostOS.IPPROTO_MUX       : self = .IPPROTO_MUX
            case HostOS.IPPROTO_MEAS      : self = .IPPROTO_MEAS
            case HostOS.IPPROTO_HMP       : self = .IPPROTO_HMP
            case HostOS.IPPROTO_PRM       : self = .IPPROTO_PRM
            case HostOS.IPPROTO_IDP       : self = .IPPROTO_IDP
            case HostOS.IPPROTO_TRUNK1    : self = .IPPROTO_TRUNK1
            case HostOS.IPPROTO_TRUNK2    : self = .IPPROTO_TRUNK2
            case HostOS.IPPROTO_LEAF1     : self = .IPPROTO_LEAF1
            case HostOS.IPPROTO_LEAF2     : self = .IPPROTO_LEAF2
            case HostOS.IPPROTO_RDP       : self = .IPPROTO_RDP
            case HostOS.IPPROTO_IRTP      : self = .IPPROTO_IRTP
            case HostOS.IPPROTO_TP        : self = .IPPROTO_TP
            case HostOS.IPPROTO_BLT       : self = .IPPROTO_BLT
            case HostOS.IPPROTO_NSP       : self = .IPPROTO_NSP
            case HostOS.IPPROTO_INP       : self = .IPPROTO_INP
            case HostOS.IPPROTO_SEP       : self = .IPPROTO_SEP
            case HostOS.IPPROTO_3PC       : self = .IPPROTO_3PC
            case HostOS.IPPROTO_IDPR      : self = .IPPROTO_IDPR
            case HostOS.IPPROTO_XTP       : self = .IPPROTO_XTP
            case HostOS.IPPROTO_DDP       : self = .IPPROTO_DDP
            case HostOS.IPPROTO_CMTP      : self = .IPPROTO_CMTP
            case HostOS.IPPROTO_TPXX      : self = .IPPROTO_TPXX
            case HostOS.IPPROTO_IL        : self = .IPPROTO_IL
            case HostOS.IPPROTO_SDRP      : self = .IPPROTO_SDRP
            case HostOS.IPPROTO_ROUTING   : self = .IPPROTO_ROUTING
            case HostOS.IPPROTO_FRAGMENT  : self = .IPPROTO_FRAGMENT
            case HostOS.IPPROTO_IDRP      : self = .IPPROTO_IDRP
            case HostOS.IPPROTO_RSVP      : self = .IPPROTO_RSVP
            case HostOS.IPPROTO_GRE       : self = .IPPROTO_GRE
            case HostOS.IPPROTO_MHRP      : self = .IPPROTO_MHRP
            case HostOS.IPPROTO_BHA       : self = .IPPROTO_BHA
            case HostOS.IPPROTO_ESP       : self = .IPPROTO_ESP
            case HostOS.IPPROTO_AH        : self = .IPPROTO_AH
            case HostOS.IPPROTO_INLSP     : self = .IPPROTO_INLSP
            case HostOS.IPPROTO_SWIPE     : self = .IPPROTO_SWIPE
            case HostOS.IPPROTO_NHRP      : self = .IPPROTO_NHRP
            case HostOS.IPPROTO_ICMPV6    : self = .IPPROTO_ICMPV6
            case HostOS.IPPROTO_NONE      : self = .IPPROTO_NONE
            case HostOS.IPPROTO_DSTOPTS   : self = .IPPROTO_DSTOPTS
            case HostOS.IPPROTO_AHIP      : self = .IPPROTO_AHIP
            case HostOS.IPPROTO_CFTP      : self = .IPPROTO_CFTP
            case HostOS.IPPROTO_HELLO     : self = .IPPROTO_HELLO
            case HostOS.IPPROTO_SATEXPAK  : self = .IPPROTO_SATEXPAK
            case HostOS.IPPROTO_KRYPTOLAN : self = .IPPROTO_KRYPTOLAN
            case HostOS.IPPROTO_RVD       : self = .IPPROTO_RVD
            case HostOS.IPPROTO_IPPC      : self = .IPPROTO_IPPC
            case HostOS.IPPROTO_ADFS      : self = .IPPROTO_ADFS
            case HostOS.IPPROTO_SATMON    : self = .IPPROTO_SATMON
            case HostOS.IPPROTO_VISA      : self = .IPPROTO_VISA
            case HostOS.IPPROTO_IPCV      : self = .IPPROTO_IPCV
            case HostOS.IPPROTO_CPNX      : self = .IPPROTO_CPNX
            case HostOS.IPPROTO_CPHB      : self = .IPPROTO_CPHB
            case HostOS.IPPROTO_WSN       : self = .IPPROTO_WSN
            case HostOS.IPPROTO_PVP       : self = .IPPROTO_PVP
            case HostOS.IPPROTO_BRSATMON  : self = .IPPROTO_BRSATMON
            case HostOS.IPPROTO_ND        : self = .IPPROTO_ND
            case HostOS.IPPROTO_WBMON     : self = .IPPROTO_WBMON
            case HostOS.IPPROTO_WBEXPAK   : self = .IPPROTO_WBEXPAK
            case HostOS.IPPROTO_EON       : self = .IPPROTO_EON
            case HostOS.IPPROTO_VMTP      : self = .IPPROTO_VMTP
            case HostOS.IPPROTO_SVMTP     : self = .IPPROTO_SVMTP
            case HostOS.IPPROTO_VINES     : self = .IPPROTO_VINES
            case HostOS.IPPROTO_TTP       : self = .IPPROTO_TTP
            case HostOS.IPPROTO_IGP       : self = .IPPROTO_IGP
            case HostOS.IPPROTO_DGP       : self = .IPPROTO_DGP
            case HostOS.IPPROTO_TCF       : self = .IPPROTO_TCF
            case HostOS.IPPROTO_IGRP      : self = .IPPROTO_IGRP
            case HostOS.IPPROTO_OSPFIGP   : self = .IPPROTO_OSPFIGP
            case HostOS.IPPROTO_SRPC      : self = .IPPROTO_SRPC
            case HostOS.IPPROTO_LARP      : self = .IPPROTO_LARP
            case HostOS.IPPROTO_MTP       : self = .IPPROTO_MTP
            case HostOS.IPPROTO_AX25      : self = .IPPROTO_AX25
            case HostOS.IPPROTO_IPEIP     : self = .IPPROTO_IPEIP
            case HostOS.IPPROTO_MICP      : self = .IPPROTO_MICP
            case HostOS.IPPROTO_SCCSP     : self = .IPPROTO_SCCSP
            case HostOS.IPPROTO_ETHERIP   : self = .IPPROTO_ETHERIP
            case HostOS.IPPROTO_ENCAP     : self = .IPPROTO_ENCAP
            case HostOS.IPPROTO_APES      : self = .IPPROTO_APES
            case HostOS.IPPROTO_GMTP      : self = .IPPROTO_GMTP
            case HostOS.IPPROTO_PIM       : self = .IPPROTO_PIM
            case HostOS.IPPROTO_IPCOMP    : self = .IPPROTO_IPCOMP
            case HostOS.IPPROTO_PGM       : self = .IPPROTO_PGM
            case HostOS.IPPROTO_SCTP      : self = .IPPROTO_SCTP
            case HostOS.IPPROTO_DIVERT    : self = .IPPROTO_DIVERT
            case HostOS.IPPROTO_RAW       : self = .raw
            */
                
            default: return nil
        }
    }
    
    // -------------------------------------
    public var rawValue: Int32
    {
        switch self
        {
            case .ip                : return HostOS.IPPROTO_IP
            case .ip4               : return HostOS.IPPROTO_IPV4
            case .tcp               : return HostOS.IPPROTO_TCP
            case .udp               : return HostOS.IPPROTO_UDP
            case .ipv6              : return HostOS.IPPROTO_IPV6

            /* Unsupported currently in NIX
            case .IPPROTO_HOPOPTS   : return HostOS.IPPROTO_HOPOPTS
            case .IPPROTO_ICMP      : return HostOS.IPPROTO_ICMP
            case .IPPROTO_IGMP      : return HostOS.IPPROTO_IGMP
            case .IPPROTO_GGP       : return HostOS.IPPROTO_GGP
            case .IPPROTO_IPIP      : return HostOS.IPPROTO_IPIP
            case .IPPROTO_ST        : return HostOS.IPPROTO_ST
            case .IPPROTO_EGP       : return HostOS.IPPROTO_EGP
            case .IPPROTO_PIGP      : return HostOS.IPPROTO_PIGP
            case .IPPROTO_RCCMON    : return HostOS.IPPROTO_RCCMON
            case .IPPROTO_NVPII     : return HostOS.IPPROTO_NVPII
            case .IPPROTO_PUP       : return HostOS.IPPROTO_PUP
            case .IPPROTO_ARGUS     : return HostOS.IPPROTO_ARGUS
            case .IPPROTO_EMCON     : return HostOS.IPPROTO_EMCON
            case .IPPROTO_XNET      : return HostOS.IPPROTO_XNET
            case .IPPROTO_CHAOS     : return HostOS.IPPROTO_CHAOS
            case .IPPROTO_MUX       : return HostOS.IPPROTO_MUX
            case .IPPROTO_MEAS      : return HostOS.IPPROTO_MEAS
            case .IPPROTO_HMP       : return HostOS.IPPROTO_HMP
            case .IPPROTO_PRM       : return HostOS.IPPROTO_PRM
            case .IPPROTO_IDP       : return HostOS.IPPROTO_IDP
            case .IPPROTO_TRUNK1    : return HostOS.IPPROTO_TRUNK1
            case .IPPROTO_TRUNK2    : return HostOS.IPPROTO_TRUNK2
            case .IPPROTO_LEAF1     : return HostOS.IPPROTO_LEAF1
            case .IPPROTO_LEAF2     : return HostOS.IPPROTO_LEAF2
            case .IPPROTO_RDP       : return HostOS.IPPROTO_RDP
            case .IPPROTO_IRTP      : return HostOS.IPPROTO_IRTP
            case .IPPROTO_TP        : return HostOS.IPPROTO_TP
            case .IPPROTO_BLT       : return HostOS.IPPROTO_BLT
            case .IPPROTO_NSP       : return HostOS.IPPROTO_NSP
            case .IPPROTO_INP       : return HostOS.IPPROTO_INP
            case .IPPROTO_SEP       : return HostOS.IPPROTO_SEP
            case .IPPROTO_3PC       : return HostOS.IPPROTO_3PC
            case .IPPROTO_IDPR      : return HostOS.IPPROTO_IDPR
            case .IPPROTO_XTP       : return HostOS.IPPROTO_XTP
            case .IPPROTO_DDP       : return HostOS.IPPROTO_DDP
            case .IPPROTO_CMTP      : return HostOS.IPPROTO_CMTP
            case .IPPROTO_TPXX      : return HostOS.IPPROTO_TPXX
            case .IPPROTO_IL        : return HostOS.IPPROTO_IL
            case .IPPROTO_SDRP      : return HostOS.IPPROTO_SDRP
            case .IPPROTO_ROUTING   : return HostOS.IPPROTO_ROUTING
            case .IPPROTO_FRAGMENT  : return HostOS.IPPROTO_FRAGMENT
            case .IPPROTO_IDRP      : return HostOS.IPPROTO_IDRP
            case .IPPROTO_RSVP      : return HostOS.IPPROTO_RSVP
            case .IPPROTO_GRE       : return HostOS.IPPROTO_GRE
            case .IPPROTO_MHRP      : return HostOS.IPPROTO_MHRP
            case .IPPROTO_BHA       : return HostOS.IPPROTO_BHA
            case .IPPROTO_ESP       : return HostOS.IPPROTO_ESP
            case .IPPROTO_AH        : return HostOS.IPPROTO_AH
            case .IPPROTO_INLSP     : return HostOS.IPPROTO_INLSP
            case .IPPROTO_SWIPE     : return HostOS.IPPROTO_SWIPE
            case .IPPROTO_NHRP      : return HostOS.IPPROTO_NHRP
            case .IPPROTO_ICMPV6    : return HostOS.IPPROTO_ICMPV6
            case .IPPROTO_NONE      : return HostOS.IPPROTO_NONE
            case .IPPROTO_DSTOPTS   : return HostOS.IPPROTO_DSTOPTS
            case .IPPROTO_AHIP      : return HostOS.IPPROTO_AHIP
            case .IPPROTO_CFTP      : return HostOS.IPPROTO_CFTP
            case .IPPROTO_HELLO     : return HostOS.IPPROTO_HELLO
            case .IPPROTO_SATEXPAK  : return HostOS.IPPROTO_SATEXPAK
            case .IPPROTO_KRYPTOLAN : return HostOS.IPPROTO_KRYPTOLAN
            case .IPPROTO_RVD       : return HostOS.IPPROTO_RVD
            case .IPPROTO_IPPC      : return HostOS.IPPROTO_IPPC
            case .IPPROTO_ADFS      : return HostOS.IPPROTO_ADFS
            case .IPPROTO_SATMON    : return HostOS.IPPROTO_SATMON
            case .IPPROTO_VISA      : return HostOS.IPPROTO_VISA
            case .IPPROTO_IPCV      : return HostOS.IPPROTO_IPCV
            case .IPPROTO_CPNX      : return HostOS.IPPROTO_CPNX
            case .IPPROTO_CPHB      : return HostOS.IPPROTO_CPHB
            case .IPPROTO_WSN       : return HostOS.IPPROTO_WSN
            case .IPPROTO_PVP       : return HostOS.IPPROTO_PVP
            case .IPPROTO_BRSATMON  : return HostOS.IPPROTO_BRSATMON
            case .IPPROTO_ND        : return HostOS.IPPROTO_ND
            case .IPPROTO_WBMON     : return HostOS.IPPROTO_WBMON
            case .IPPROTO_WBEXPAK   : return HostOS.IPPROTO_WBEXPAK
            case .IPPROTO_EON       : return HostOS.IPPROTO_EON
            case .IPPROTO_VMTP      : return HostOS.IPPROTO_VMTP
            case .IPPROTO_SVMTP     : return HostOS.IPPROTO_SVMTP
            case .IPPROTO_VINES     : return HostOS.IPPROTO_VINES
            case .IPPROTO_TTP       : return HostOS.IPPROTO_TTP
            case .IPPROTO_IGP       : return HostOS.IPPROTO_IGP
            case .IPPROTO_DGP       : return HostOS.IPPROTO_DGP
            case .IPPROTO_TCF       : return HostOS.IPPROTO_TCF
            case .IPPROTO_IGRP      : return HostOS.IPPROTO_IGRP
            case .IPPROTO_OSPFIGP   : return HostOS.IPPROTO_OSPFIGP
            case .IPPROTO_SRPC      : return HostOS.IPPROTO_SRPC
            case .IPPROTO_LARP      : return HostOS.IPPROTO_LARP
            case .IPPROTO_MTP       : return HostOS.IPPROTO_MTP
            case .IPPROTO_AX25      : return HostOS.IPPROTO_AX25
            case .IPPROTO_IPEIP     : return HostOS.IPPROTO_IPEIP
            case .IPPROTO_MICP      : return HostOS.IPPROTO_MICP
            case .IPPROTO_SCCSP     : return HostOS.IPPROTO_SCCSP
            case .IPPROTO_ETHERIP   : return HostOS.IPPROTO_ETHERIP
            case .IPPROTO_ENCAP     : return HostOS.IPPROTO_ENCAP
            case .IPPROTO_APES      : return HostOS.IPPROTO_APES
            case .IPPROTO_GMTP      : return HostOS.IPPROTO_GMTP
            case .IPPROTO_PIM       : return HostOS.IPPROTO_PIM
            case .IPPROTO_IPCOMP    : return HostOS.IPPROTO_IPCOMP
            case .IPPROTO_PGM       : return HostOS.IPPROTO_PGM
            case .IPPROTO_SCTP      : return HostOS.IPPROTO_SCTP
            case .IPPROTO_DIVERT    : return HostOS.IPPROTO_DIVERT
            case .raw               : return HostOS.IPPROTO_RAW
            */
        }
    }
}
