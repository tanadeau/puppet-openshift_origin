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

  ensure_resource('package', 'avahi-cname-manager', {
      ensure  => present,
      require => Class['openshift_origin::install_method'],
    }
  )

  ensure_resource('package', 'avahi', {
      ensure  => present,
      require => Class['openshift_origin::install_method'],
    }
  )

  exec { "Open mdns port":
    command => "${::openshift_origin::params::iptables} -A INPUT -p udp --dport 5353 -d 224.0.0.251 -j ACCEPT;
                ${::openshift_origin::params::iptables} -A OUTPUT -p udp --dport 5353 -d 224.0.0.251 -j ACCEPT;
                ${::openshift_origin::params::iptables_save_command};",
    require =>  [
                  Package[$::openshift_origin::params::iptables_requires],
                  Exec['initial iptables setup'],
                  Package['avahi'],
                ],
    before  => Exec['final iptables setup'],
  }

  service { ['avahi-daemon', 'avahi-cname-manager']:
    enable  => true,
    require => [
      Package['avahi'],
      Package['avahi-cname-manager'],
    ]
  }
}
