class openshift_origin::role::node inherits openshift_origin::role {
  include openshift_origin::node

  openshift_origin::register_dns{ 'register node dns':
    fqdn    => $::openshift_origin::node_hostname,
    require => Class['openshift_origin::node'],
  }
}
