# Copyright 2014 Red Hat, Inc., All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
# == Class openshift_origin::ose_supported_config
#
# This class enforces or provides notices about unsupported configurations.
#
# TODO: write a custom function to avoid all the fail vs. notice logic
#
class openshift_origin::ose_supported_config {
  if ($::operatingsystem != 'RedHat') or ($::operatingsystemrelease >= 7.0 ) or
      ($::operatingsystemrelease < 6.5) {
    if $openshift_origin::ose_unsupported {
      notice('Openshift Enterprise requires Red Hat Enterprise Linux Server 6 version 6.5 or later')
    } else {
      fail('Openshift Enterprise requires Red Hat Enterprise Linux Server 6 version 6.5 or later')
    }
  }
  if member( $openshift_origin::node_frontend_plugins, 'apache-mod-rewrite' ) {
      notice('Openshift Enterprise 2.2 has deprecated the apache-mod-rewrite frontend.')
  }
  if $::architecture != 'x86_64' {
    if $openshift_origin::ose_unsupported {
      notice('Openshift Enterprise is only supported on x86_64.')
    } else {
      fail('Openshift Enterprise is only supported on x86_64.')
    }
  }
  if member( $openshift_origin::roles, 'node' ) and member( $openshift_origin::roles, 'broker' ) {
    if $openshift_origin::ose_unsupported {
      notice('Openshift Enterprise does not support co-location of node and broker')
    } else {
      fail('Openshift Enterprise does not support co-location of node and broker')
    }
  }
  if member( $openshift_origin::roles, 'load_balancer' ) {
    if $openshift_origin::ose_unsupported {
      notice('Broker load balancing must be handled by external facilities')
    } else {
      fail('Broker load balancing must be handled by external facilities')
    }
  }
  if $openshift_origin::broker_dns_plugin =~ /avahi|route53/  {
    if $openshift_origin::ose_unsupported {
      notice('Openshift Enterprise does not support avahi or route53 dns plugins')
    } else {
      fail('Openshift Enterprise does not support avahi or route53 dns plugins')
    }
  }
  if $openshift_origin::msgserver_cluster {
    if !(size($openshift_origin::msgserver_cluster_members) >= 2) {
        if $openshift_origin::ose_unsupported {
          notice('Openshift Enterprise requires at least 2 ActiveMQ nodes for clustered messaging')
        } else {
          fail('Openshift Enterprise requires at least 2 ActiveMQ nodes for clustered messaging')
        }
    }
  }
  if $openshift_origin::mongodb_replicasets {
    if (size($openshift_origin::mongodb_replicasets_members) < 3) {
      if $openshift_origin::ose_unsupported {
        notice('Openshift Enterprise requires replicasets have 3 or more members. It must also be an odd number of members.')
      } else {
        fail('Openshift Enterprise requires replicasets have 3 or more members. It must also be an odd number of members.')
      }
    }
  }
}

