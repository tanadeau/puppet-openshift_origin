class openshift_origin::role::load_balancer inherits openshift_origin::role {
  include openshift_origin::load_balancer
  include openshift_origin::register_dns
}
