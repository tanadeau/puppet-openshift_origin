class openshift_origin::update_conf_files {
  augeas { 'network-scripts':
    context => "/files/etc/sysconfig/network-scripts/ifcfg-${::openshift_origin::conf_node_external_eth_dev}",
    lens    => 'Shellvars.lns',
    incl    => "/etc/sysconfig/network-scripts/ifcfg-${::openshift_origin::conf_node_external_eth_dev}",
    changes => [
      'set PEERDNS no',
      "set DNS1 ${::openshift_origin::nameserver_ip_addr}",
    ],
  }

  file { 'dhcpclient':
    ensure  => present,
    path    => "/etc/dhcp/dhclient-${::openshift_origin::conf_node_external_eth_dev}.conf",
    content => template('openshift_origin/dhclient_conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  file { '/etc/resolv.conf':
    content => "search ${::openshift_origin::domain}\nnameserver ${::openshift_origin::nameserver_ip_addr}"
  }
}
