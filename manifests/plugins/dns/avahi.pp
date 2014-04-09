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
class openshift_origin::plugins::dns::avahi {
  if $::openshift_origin::manage_firewall {
    include openshift_origin::firewall::mdns
  }

  file { 'plugin openshift-origin-dns-avahi.conf':
    path    => '/etc/openshift/plugins.d/openshift-origin-dns-avahi.conf',
    content => template('openshift_origin/broker/plugins/dns/avahi/avahi.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['rubygem-openshift-origin-dns-avahi'],
  }

  file { 'avahi-cname-manager config':
    path    => '/etc/avahi/cname-manager.conf',
    content => template('openshift_origin/broker/plugins/dns/avahi/cname-manager.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => [
      Package['rubygem-openshift-origin-dns-avahi'],
      Package['avahi-cname-manager'],
    ]
  }

  package { 'avahi-cname-manager':
    ensure  => present,
    require => Class['openshift_origin::install_method'],
  }

  package { 'avahi':
    ensure  => present,
    require => Class['openshift_origin::install_method'],
  }

  service { ['avahi-daemon', 'avahi-cname-manager']:
    enable  => true,
    require => [
      Package['avahi'],
      Package['avahi-cname-manager'],
    ]
  }
}
