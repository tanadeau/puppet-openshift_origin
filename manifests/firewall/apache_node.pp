class openshift_origin::firewall::apache_node {
  lokkit::ports { 'Node Apache':
    tcpPorts => [ '8000','8443' ],
  }
}
