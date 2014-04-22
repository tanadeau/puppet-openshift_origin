class openshift_origin::firewall::mdns {
  lokkit::custom { 'openshift_mdns_rules':
    type   => 'ipv4',
    table  => 'filter',
    source => 'puppet:///openshift_origin/firewall/mdns_iptables.txt',
  }
}
