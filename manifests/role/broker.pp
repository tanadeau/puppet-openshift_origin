class openshift_origin::role::broker inherits openshift_origin::role {
  include openshift_origin::client_tools
  include openshift_origin::broker
  include openshift_origin::console

  openshift_origin::register_dns{ 'register broker dns':
    fqdn    => $::openshift_origin::broker_hostname,
    require => Class['openshift_origin::client_tools','openshift_origin::broker','openshift_origin::console']
  }
}
