class openshift_origin::role::datastore inherits openshift_origin::role {
  include openshift_origin::datastore

  openshift_origin::register_dns{ 'register datastore dns':
    fqdn    => $::openshift_origin::datastore_hostname,
    require => Class['openshift_origin::datastore'],
  }
}
