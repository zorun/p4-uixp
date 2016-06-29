/*
Implement uIXP, which stands for "micro IXP" or "unicast IXP".

The idea is to provide a layer-2 ethernet segment without needing any
broadcast or multicast packets (which are a big problem for large
layer-2 fabrics at IXP).

To do that, we replace reactive discovery (ARP/ND, switch learning) by
fixed mappings (port to MAC, MAC to IP) provided at runtime.  This is
realistic on an IXP, where members have to provide this information in
order to connect to the fabric.

To ensure compatibility, the P4 switch answers ARP and ND requests
itself, based on the runtime mappings.

TODO: more torough validation (TTL=255 for ND packets, consistent
types, etc).

*/

#include "headers.p4"
#include "parser.p4"

action _drop() {
    drop();
}

action allowed_mac() {
}

/* Table associating MAC addresses and port, dropping packets with
   unknown source MAC address for a given port. */
table validate_src_mac {
    reads {
        ethernet.srcAddr: exact;
        standard_metadata.ingress_port: exact;
    }
    actions {
        allowed_mac;
        _drop;
    }
    size: 1024;
}

/* Table listing allowed MAC addresses on egress.  The main usage is
   to drop all multicast/broadcast frames. */
table validate_dest_mac {
    reads {
        ethernet.dstAddr: ternary;
    }
    actions {
        allowed_mac;
        _drop;
    }
    size: 1024;
}

action nd_reply(target_mac) {
    /* Hard part: take a NS packet and reply with a suitable NA
       packet.  To do that, we just modify the NS packet in place and
       send it back to where it came from. */
    // TODO: handle multicast/unicast cases
    modify_field(ipv6.srcAddr, ipv6.dstAddr);
    modify_field(ipv6.dstAddr, ipv6.srcAddr);
    // TODO: change MAC addresses
    add_header(icmpv6_na);
    modify_field(icmpv6_na.router, 1);
    modify_field(icmpv6_na.solicited, 1);
    modify_field(icmpv6_na.override, 1);
    modify_field(icmpv6_na.targetAddr, icmpv6_ns.targetAddr);
    modify_field(icmpv6_na.LLoptType, 2);
    modify_field(icmpv6_na.LLoptLength, 1);
    modify_field(icmpv6_na.LLoptValue, target_mac);
    remove_header(icmpv6_ns);
    /* Send back the packet to where it came from. */
    modify_field(standard_metadata.egress_spec, standard_metadata.ingress_port);
}

/* Table mapping IPv6 address to MAC address */
table ipv6_neighbours {
    reads {
        icmpv6_ns.targetAddr: exact;
    }
    actions {
        nd_reply;
        _drop;
    }
    size: 1024;
}

action send_to_port(port) {
    modify_field(standard_metadata.egress_spec, port);
}

/* Table mapping MAC address to port.  This is redundant with the data
   in validate_src_mac. */
table switch_frame {
    reads {
        ethernet.dstAddr: exact;
    }
    actions {
        send_to_port;
        _drop;
    }
    size: 1024;
}

control ingress {
    apply(validate_src_mac) {
        allowed_mac {
            if (valid(icmpv6_ns)) {
                apply(ipv6_neighbours);
            }
            else {
                apply(switch_frame);
	    }
        }
    }
}

control egress {
    apply(validate_dest_mac);
}

/*
Local variables:
eval:   (c-mode)
eval:   (setq c-basic-offset 4)
eval:   (c-set-offset 'label 4)
End:
*/
