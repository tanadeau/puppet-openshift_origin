class openshift_origin::broker_console_dirs {
  file {
    [
      '/etc/openshift',
      '/var/log/openshift',
      '/var/www/openshift',
    ]:
    ensure => directory
  }
}
