class openshift_origin::role::nameserver inherits openshift_origin::role {
  include openshift_origin::nameserver

  openshift_origin::register_dns{ 'register nameserver dns':
    fqdn    => $::openshift_origin::nameserver_hostname,
    require => Class['openshift_origin::nameserver']
  }
}
