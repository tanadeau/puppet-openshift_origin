class openshift_origin::plugins::auth::remote_user {
  package { 'rubygem-openshift-origin-auth-remote-user':
    ensure  => present,
    require => Class['openshift_origin::install_method'],
  }
}
