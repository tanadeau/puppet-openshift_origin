class openshift_origin::firewall::mdns {
  lokkit::custom { 'Multicast DNS':
    type    => 'ipv4',
    table   => 'filter'
    content => "-A INPUT -d 224.0.0.251/32 -p udp -m udp --dport 5353 -j ACCEPT 
-A OUTPUT -d 224.0.0.251/32 -p udp -m udp --dport 5353 -j ACCEPT ",
  }
}
