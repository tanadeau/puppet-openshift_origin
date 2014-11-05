class openshift_origin::role::load_balancer inherits openshift_origin::role {
  include openshift_origin::load_balancer
  include openshift_origin::register_dns

  anchor { 'openshift_origin::load_balancer_role_begin': } ->
  Class['openshift_origin::load_balancer'] ->
  anchor { 'openshift_origin::load_balancer_role_end': } ->
  Class['openshift_origin::register_dns']
}
