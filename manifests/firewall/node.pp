class openshift_origin::firewall::node {
  lokkit::ports { 'Node Port Range':
    tcpPorts => ['35531-65535'],
  }
}
