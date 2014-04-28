class openshift_origin::install_method {
  include openshift_origin::params

  case $::openshift_origin::install_method {
    'none' : {}
    'yum'  : {
      include openshift_origin::yum_install_method
      # TODO: This is a major hack intended to ensure that all yum repos are defined before we try to do anything else.
      file { '/tmp':
        ensure  => directory,
        require => Class['openshift_origin::yum_install_method'],
      }
    }
    default: {}
  }
}
