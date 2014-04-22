# Copyright 2014 Red Hat, Inc., All rights reserved.
#
# == Class openshift_origin::selbooleans::node
# These SELinux restorecon commands must be run on every OpenShift Node host.
#
class openshift_origin::selbooleans::node {
  exec { 'node restorecon commands':
    command => 'restorecon -rv /var/run; restorecon -rv /var/lib/openshift /etc/openshift/node.conf',
    require  => [
      Package['rubygem-openshift-origin-node'],
      File['openshift node config'],
    ]
  }
}
