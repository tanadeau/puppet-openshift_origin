# Copyright 2013 Mojo Lingo LLC.
# Modifications by Red Hat, Inc.
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
class openshift_origin::mcollective_client {
  include openshift_origin::params

  package { "${::openshift_origin::params::ruby_scl_prefix}mcollective-client":
    alias   => 'mcollective-client',
    require => Class['openshift_origin::install_method'],
  }

  # TODO: Replace with MCollective puppet module call

  $cluster_members = $::openshift_origin::real_msgserver_cluster_members

  if $cluster_members {
    $pool_size = size($cluster_members)
  } else {
    $pool_size = '1'
  }

  if ($::openshift_origin::msgserver_tls_enabled == 'enabled' or $::openshift_origin::msgserver_tls_enabled == 'strict') {
    if ($::openshift_origin::msgserver_tls_ca != '') and ($::openshift_origin::msgserver_tls_key != '') and ($::openshift_origin::msgserver_tls_cert != '') {
      $tls_certs_provided = true
    } else { $tls_certs_provided = false }
  }

  if ($::openshift_origin::msgserver_tls_enabled == 'strict' and $tls_certs_provided == false) {
    fail 'Valid certificate file locations are required when msgserver_tls_enabled is in strict mode.'
  }
  
  file { 'mcollective client config':
    ensure  => present,
    path    => "${::openshift_origin::params::ruby_scl_path_prefix}/etc/mcollective/client.cfg",
    content => template('openshift_origin/mcollective/mcollective-client.cfg.erb'),
    owner   => 'apache',
    group   => 'apache',
    mode    => '0640',
    require => Package['mcollective-client','httpd'],
  }

  file { 'mcollective log file':
    ensure  => present,
    path    => "/var/log/openshift/broker/${::openshift_origin::params::ruby_scl_prefix}mcollective-client.log",
    owner   => 'apache',
    group   => 'root',
    mode    => '0644',
    require => Package['mcollective-client','httpd'],
  }
}
