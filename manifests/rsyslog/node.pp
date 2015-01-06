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
class openshift_origin::rsyslog::node {

  if $::openshift_origin::syslog_enabled == true{
    file { '/etc/rsyslog.conf':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      content => template('openshift_origin/rsyslog/rsyslog_node_conf.erb'),
      require => Exec['install_rsyslog7'],
      notify  => Service['rsyslog']
    }

    file { '/etc/rsyslog.d/openshift.conf':
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      content => template('openshift_origin/rsyslog/rsyslog_node_openshift_conf.erb'),
      require => Exec['install_rsyslog7'],
      notify  => Service['rsyslog']
    }
  }

  file { '/etc/sysconfig/httpd':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    content => template('openshift_origin/node/httpd.erb'),
    notify  => Service['httpd']
  }

  file { '/etc/openshift/logshifter.conf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    content => template('openshift_origin/node/logshifter.conf.erb'),
    notify  => [Service['openshift-watchman'], Service["${::openshift_origin::params::ruby_scl_prefix}mcollective"]]
  }
}
