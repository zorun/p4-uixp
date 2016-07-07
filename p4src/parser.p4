/* Adapted from "p4factory/targets/switch/p4src/includes/parser.p4" */

#define ETHERTYPE_IPV4         0x0800
#define ETHERTYPE_IPV6         0x86dd
#define ETHERTYPE_ARP          0x0806
#define ETHERTYPE_RARP         0x8035

#define IP_PROTOCOLS_ICMPV6    58

#define ICMPV6_TYPE_RS         133
#define ICMPV6_TYPE_RA         134
#define ICMPV6_TYPE_NS         135
#define ICMPV6_TYPE_NA         136
#define ICMPV6_TYPE_REDIRECT   137

#define ICMPV6_ND_OPTION_SOURCE_LL_ADDR    1
#define ICMPV6_ND_OPTION_TARGET_LL_ADDR    2
#define ICMPV6_ND_OPTION_PREFIX_INFO       3
#define ICMPV6_ND_OPTION_REDIRECTED_HEADER 4
#define ICMPV6_ND_OPTION_MTU               5

header ethernet_t ethernet;
header ipv6_t ipv6;
header icmpv6_t icmpv6;
header icmpv6_ns_t icmpv6_ns;
header icmpv6_na_t icmpv6_na;
header nd_option_ether_addr_t nd_option_src_ll_addr;
header nd_option_ether_addr_t nd_option_tgt_ll_addr;
/* Don't use a stack because we don't care about unknown options. */
header nd_option_unknown_t nd_option_unknown;

@pragma header_ordering ethernet ipv6 icmpv6 icmpv6_ns icmpv6_na nd_option_src_ll_addr nd_option_tgt_ll_addr nd_option_unknown
parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV6: parse_ipv6;
        //ETHERTYPE_ARP: parse_arp_rarp;
        default: ingress;
    }
}

/* TODO: we should probably parse unknown nextHdr to cope for IPv6
   routing headers and stuff that can come before the real next
   protocol. */
parser parse_ipv6 {
    extract(ipv6);
    return select(latest.nextHdr) {
        IP_PROTOCOLS_ICMPV6: parse_icmpv6;
        default: ingress;
    }
}

field_list icmpv6_checksum_list {
    ipv6.srcAddr;
    ipv6.dstAddr;
    ipv6.payloadLen;
    // zero??
    ipv6.nextHdr;
    icmpv6.type_;
    icmpv6.code;
    icmpv6.checksum;
    payload;
}

field_list_calculation icmpv6_checksum {
    input {
        icmpv6_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field icmpv6.checksum  {
    verify icmpv6_checksum;
    update icmpv6_checksum;
}


/* Count how much bytes are left to parse (necessary because of options). */
header_type my_metadata_t {
    fields {
        parse_icmpv6_counter: 8;
    }
}

metadata my_metadata_t my_metadata;

parser parse_icmpv6 {
    extract(icmpv6);
    /* Count the number of bytes after the ICMPv6 header. */
    /* TODO: the offset does not take into account IPv6 options. */
    set_metadata(my_metadata.parse_icmpv6_counter, ipv6.payloadLen - 4);
    return select(icmpv6.type_) {
        ICMPV6_TYPE_NS: parse_icmpv6_ns;
        ICMPV6_TYPE_NA: parse_icmpv6_na;
        default: ingress;
    }
}

parser parse_icmpv6_ns {
    extract(icmpv6_ns);
    set_metadata(my_metadata.parse_icmpv6_counter,
                 my_metadata.parse_icmpv6_counter - 20);
    return parse_nd_options;
}

parser parse_icmpv6_na {
    extract(icmpv6_na);
    set_metadata(my_metadata.parse_icmpv6_counter,
                 my_metadata.parse_icmpv6_counter - 20);
    return parse_nd_options;
}

parser parse_source_ll_addr {
    extract(nd_option_src_ll_addr);
    set_metadata(my_metadata.parse_icmpv6_counter,
                 my_metadata.parse_icmpv6_counter - 8);
    return parse_nd_options;
}

parser parse_target_ll_addr {
    extract(nd_option_tgt_ll_addr);
    set_metadata(my_metadata.parse_icmpv6_counter,
                 my_metadata.parse_icmpv6_counter - 8);
    return parse_nd_options;
}

parser parse_unknown_nd_option {
    extract(nd_option_unknown);
    set_metadata(my_metadata.parse_icmpv6_counter,
                 my_metadata.parse_icmpv6_counter - nd_option_unknown.length_);
    return parse_nd_options;
}

parser parse_nd_options {
    // match on byte counter and option value
    return select(my_metadata.parse_icmpv6_counter, current(0, 8)) {
        0x0000 mask 0xff00: ingress;
        // ICMPV6_ND_OPTION_SOURCE_LL_ADDR    1
        0x0001 mask 0x00ff: parse_source_ll_addr;
        // ICMPV6_ND_OPTION_TARGET_LL_ADDR    2
        0x0002 mask 0x00ff: parse_target_ll_addr;
        default: parse_unknown_nd_option;
    }
}

/*
Local variables:
eval:   (c-mode)
eval:   (setq c-basic-offset 4)
eval:   (c-set-offset 'label 4)
End:
*/
