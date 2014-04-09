class openshift_origin::firewall::mongodb {
  lokkit::ports { 'mongodb':
    tcpPorts => [ '27017' ],
  }
}
