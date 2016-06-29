/* Adapted from "p4factory/targets/switch/p4src/includes/parser.p4" */

#define ETHERTYPE_IPV4         0x0800
#define ETHERTYPE_IPV6         0x86dd
#define ETHERTYPE_ARP          0x0806
#define ETHERTYPE_RARP         0x8035

#define IP_PROTOCOLS_ICMPV6    58

#define ICMPV6_TYPE_NS         135
#define ICMPV6_TYPE_NA         136

parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV6: parse_ipv6;
        //ETHERTYPE_ARP: parse_arp_rarp;
        default: ingress;
    }
}

header ipv6_t ipv6;

parser parse_ipv6 {
    extract(ipv6);
    return select(latest.nextHdr) {
        IP_PROTOCOLS_ICMPV6: parse_icmpv6;
        default: ingress;
    }
}

header icmpv6_t icmpv6;

parser parse_icmpv6 {
    extract(icmpv6);
    return select(latest.type_) {
        ICMPV6_TYPE_NS: parse_icmpv6_ns;
        ICMPV6_TYPE_NA: parse_icmpv6_na;
        default: ingress;
    }
}

header icmpv6_ns_t icmpv6_ns;

parser parse_icmpv6_ns {
    extract(icmpv6_ns);
    return ingress;
}

header icmpv6_na_t icmpv6_na;

parser parse_icmpv6_na {
    extract(icmpv6_na);
    return ingress;
}

/*
Local variables:
eval:   (c-mode)
eval:   (setq c-basic-offset 4)
eval:   (c-set-offset 'label 4)
End:
*/
