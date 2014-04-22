class openshift_origin::firewall::apache {
  lokkit::services { 'Apache':
    services => ['http','https'],
  }
}
