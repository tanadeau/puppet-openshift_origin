class openshift_origin::firewall::activemq {
  lokkit::ports { 'ActiveMQ':
    tcpPorts => [ '61613' ],
  }

  if $::openshift_origin::msgserver_cluster {
    lokkit::ports { 'ActiveMQ-Openwire':
      tcpPorts => [ '61616' ],
    }
  }
}
