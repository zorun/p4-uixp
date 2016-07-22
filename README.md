This is an experimental P4 program, written mostly to learn about P4.

`uixp` implements a "zero-broadcast" ethernet switch.

The switch drops any multicast or broadcast packet, and has static
forwarding entries to avoid flooding.  Hosts connected to the switch still
need to use ND (IPv6) and ARP (IPv4) to be able to talk to each other.  To
implement this, the switch has a static MAC-IP mapping table, and answers
ARP and ND requests itself instead of flooding them on all ports.

The idea is that such a switch could be useful for an IXP (hence the name
of the project: uixp stands for "micro-ixp"), where broadcasts on very
large Ethernet networks can overload member routers.  In an IXP, all MAC
addresses, IP addresses and association with switch ports are known in
advance, so there is no need for flooding or for the discovery procedure
offered by ARP/ND.

## Status

This is an early prototype, so for now, only Neighbour Discovery for IPv6
is implemented.  ARP should not be very different.

The code currently uses 4 tables:

- `validate_src_mac`, used on ingress to only allow known MAC address to
  send traffic to the switch.  It contains entries of the form (MAC
  address, switch port).  For a basic usage, any MAC can be allowed.

- `validate_dest_mac`, used on egress to drop frames with specified MAC
  addresses.  This is what is used to drop broadcast and multicast frames,
  using for instance:

```
table_set_default validate_dest_mac _drop
table_add validate_dest_mac allowed_mac 0&&&01:00:00:00:00:00 => 99
```

- `ipv6_neighbours`, used to answer ND requests.  Entries map from an IPv6
  address to a MAC address.

- `switch_frame`, implementing the static forwarding table.  Entries map
  from MAC address to the switch port on which the frame should be sent.

## Usage

### Compiling the demo

The P4 toolchain is still a mess.  The simplest way to test the code is
probably to copy this repository in `targets/uixp` in the
[p4factory](https://github.com/p4lang/p4factory) repository.

Start by installing all the stuff required by P4 by following the
instructions at <https://github.com/p4lang/p4factory> (it's a long and
bumpy road...).  In particular, you need the veth interfaces.

Then, you should be able to compile the uixp P4 code against the behavioural model:

    cd p4factory/targets/uixp/bmv2
    make

It should produce a `uixp_bmv2` binary, and a `uixp_bmv2.json` file
resulting from the compilation of the P4 code.

### Configuration

See `commands.txt` for an example on how to fill the switch tables.

For the demo, you would use the MAC address of the veth interfaces
connected to the switch (`veth1` and `veth3`).

### Testing out

Run the switch:

    cd p4factory/targets/uixp/bmv2
    ./run_bm.sh

You need use the CLI to fill the tables.  You can use this script:

    p4factory/targets/uixp/bmv2/populate_switch_tables.sh

Then try to ping the IPv6 address of `veth3` from `veth1`, so that
everything will go through the P4 switch:

    ping6 -c 3 -I veth1 fe80::XX

Use tcpdump to see what's going on.  You should see the switch generate ND
answers, and then ICMPv6 echo packets flowing through!
