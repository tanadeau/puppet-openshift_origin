class openshift_origin::role::msgserver inherits openshift_origin::role {
  include openshift_origin::msgserver

  openshift_origin::register_dns{ 'register msgserver dns':
    fqdn    => $::openshift_origin::msgserver_hostname,
    require => Class['openshift_origin::msgserver'],
  }
}
