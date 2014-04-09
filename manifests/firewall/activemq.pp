class openshift_origin::firewall::activemq {
  lokkit::ports { 'ActiveMQ':
    tcpPorts => [ '61613' ],
  }
}
