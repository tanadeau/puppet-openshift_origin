class openshift_origin::firewall::dns {
  lokkit::services{ 'DNS':
    services => [ 'dns' ],
  }
}
