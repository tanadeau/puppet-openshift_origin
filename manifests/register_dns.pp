define openshift_origin::register_dns($fqdn) {
  if $::openshift_origin::register_host_with_nameserver {
    if $fqdn != 'localhost' {
      ensure_resource( 'exec', "Register ${fqdn}", {
          command  => template('openshift_origin/register_dns.erb'),
          provider => 'shell'
        }
      )
    }
  }
}
