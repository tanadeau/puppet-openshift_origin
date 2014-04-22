class openshift_origin::cartridges::jenkins {
  package { 'jenkins':
    ensure  => '1.510-1.1',
    require => Class['openshift_origin::install_method'],
  }
  exec { '/usr/bin/yum versionlock jenkins':
    require => Package['jenkins', 'yum-plugin-versionlock'],
  }
}
