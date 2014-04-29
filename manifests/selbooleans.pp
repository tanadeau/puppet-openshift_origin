# Copyright 2014 Red Hat, Inc., All rights reserved.
#
# == Class openshift_origin::selbooleans
# These SELinux booleans must be set on any OpenShift Broker, console or Node host.
#
class openshift_origin::selbooleans {
  selboolean {
    [
      'httpd_unified',
      'httpd_can_network_connect',
      'httpd_can_network_relay',
      'httpd_run_stickshift',
      'httpd_read_user_content',
      'httpd_enable_homedirs',
    ]:
    value      => 'on',
    persistent => true,
  }
}
