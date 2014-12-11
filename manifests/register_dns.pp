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
class openshift_origin::register_dns {
  if $::openshift_origin::register_host_with_nameserver and $::openshift_origin::bind_krb_principal == '' {
    if $::fqdn != 'localhost' {
      package { 'bind-utils' :
          ensure  => present,
          require => Class['openshift_origin::install_method'],
      }

      if $::openshift_origin::dns_infrastructure_zone == '' {
        $key_domain = $::openshift_origin::domain
        $key_algorithm = $::openshift_origin::bind_key_algorithm

        if $::openshift_origin::bind_key == '' {
          fail 'bind_key is required when setting register_host_with_nameserver to true.'
        }
        $key_secret = $::openshift_origin::bind_key
      }
      else {
        $key_domain = $::openshift_origin::dns_infrastructure_zone
        $key_algorithm = $::openshift_origin::dns_infrastructure_key_algorithm

        if $::openshift_origin::dns_infrastructure_key == '' {
          fail 'dns_infrastructure_key is required when setting register_host_with_nameserver to true when using the dns_infrastructure_zone parameter.'
        }
        $key_secret = $::openshift_origin::dns_infrastructure_key
      }

      $key_argument = "${key_algorithm}:${key_domain}:${key_secret}"

      exec { 'Attempting to register host dns' :
        command  => template('openshift_origin/register_dns.erb'),
        provider => 'shell',
        require  => Package['bind-utils'],
      }
    }
  } elsif $::openshift_origin::register_host_with_nameserver and $::openshift_origin::bind_krb_principal != '' {
    warning 'You cannot use register_host_with_nameserver when using GSS-TSIG DNS updates'
    fail 'You cannot use register_host_with_nameserver when using GSS-TSIG DNS updates'
  }

}
