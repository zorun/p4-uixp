header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type ipv6_t {
    fields {
        version : 4;
        trafficClass : 8;
        flowLabel : 20;
        payloadLen : 16;
        nextHdr : 8;
        hopLimit : 8;
        srcAddr : 128;
        dstAddr : 128;
    }
}

header_type icmpv6_t {
    fields {
        /* "type" is a reserved token */
        type_: 8;
        code: 8;
        hdrChecksum: 16;
    }
}

/* Neighbour Solicitation/Advertisement (RFC4861) */
header_type icmpv6_ns_t {
    fields {
        reserved: 32;
        targetAddr: 128;
        /* For simplicity, we don't implement the "Source link-layer address" option */
    }
}

header_type icmpv6_na_t {
    fields {
        router: 1;
        solicited: 1;
        override: 1;
        reserved: 29;
        targetAddr: 128;
        /* We hardcode one possible option, the "Target link-layer address" for Ethernet */
        LLoptType: 8;
        LLoptLength: 8;
        LLoptValue: 48;
    }
}

header_type arp_rarp_t {
    fields {
        hwType : 16;
        protoType : 16;
        hwAddrLen : 8;
        protoAddrLen : 8;
        opcode : 16;
    }
}

header_type arp_rarp_ipv4_t {
    fields {
        srcHwAddr : 48;
        srcProtoAddr : 32;
        dstHwAddr : 48;
        dstProtoAddr : 32;
    }
}



header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header_type icmp_t {
    fields {
        typeCode : 16;
        hdrChecksum : 16;
    }
}

/*
Local variables:
eval:   (c-mode)
eval:   (setq c-basic-offset 4)
eval:   (c-set-offset 'label 4)
End:
*/
