class openshift_origin::firewall::ssh {
  lokkit::services{ 'SSH':
    services => [ 'ssh' ],
  }
}
