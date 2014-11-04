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
class openshift_origin::nameserver {
  include openshift_origin::params

  anchor { 'openshift_origin::nameserver_begin': } ->
  class { 'openshift_origin::firewall::dns': } ->
  anchor {'openshift_origin::nameserver_end': }

  package { 'bind':
    ensure  => present,
    require => Class['openshift_origin::install_method'],
  }

  # TODO: Replace with Bind puppet module

  file { 'dynamic zone':
    path    => "/var/named/dynamic/${openshift_origin::domain}.db",
    content => template('openshift_origin/named/dynamic-zone.db.erb'),
    owner   => 'named',
    group   => 'named',
    mode    => '0644',
    replace => false,
    require => File['/var/named/dynamic'],
  }

  exec { 'create rndc.key':
    command => '/usr/sbin/rndc-confgen -a -r /dev/urandom',
    unless  => '/usr/bin/[ -f /etc/rndc.key ]',
    require => Package['bind'],
  }

  file { '/etc/rndc.key':
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    require => Exec['create rndc.key'],
  }

  file { '/var/named/forwarders.conf':
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    content => template('openshift_origin/named/forwarders.conf.erb'),
    require => File['/var/named'],
  }

  file { '/var/named':
    ensure  => directory,
    owner   => 'root',
    group   => 'named',
    mode    => '0750',
    require => Package['bind'],
  }

  file { '/var/named/dynamic':
    ensure  => directory,
    owner   => 'named',
    group   => 'named',
    mode    => '0750',
    require => File['/var/named'],
  }

  file { 'named key':
    path    => "/var/named/${openshift_origin::domain}.key",
    content => template('openshift_origin/named/named.key.erb'),
    owner   => 'named',
    group   => 'named',
    mode    => '0444',
    require => File['/var/named'],
  }

  file { 'named configs':
    path    => '/etc/named.conf',
    owner   => 'root',
    group   => 'named',
    mode    => '0644',
    content => template('openshift_origin/named/named.conf.erb'),
    require => Package['bind'],
  }

  $named_base_files = [
    File['/etc/rndc.key'],
    File['/var/named/forwarders.conf'],
    File['/var/named'],
    File['/var/named/dynamic'],
    File['dynamic zone'],
    File['named key'],
    File['named configs'],
  ]

  # create named/adddress mappings for infrastructure hosts
  if $openshift_origin::dns_infrastructure_zone != '' {
    file { 'infrastructure host configuration':
      path    => '/var/named/oo_infrastructure.conf',
      owner   => 'root',
      group   => 'named',
      mode    => '0644',
      content => template('openshift_origin/named/oo_infrastructure.conf.erb'),
      replace => false,
      require => File['/var/named']
    }

    file { 'named infrastructure key':
      path    => "/var/named/${openshift_origin::dns_infrastructure_zone}.key",
      content => template('openshift_origin/named/oo_infrastructure_key.erb'),
      owner   => 'named',
      group   => 'named',
      mode    => '0444',
      require => File['/var/named'],
    }

    file { 'infrastructure zone contents':
      path    => "/var/named/dynamic/${openshift_origin::dns_infrastructure_zone}.db",
      owner   => 'named',
      group   => 'named',
      mode    => '0664',
      content => template('openshift_origin/named/oo_infrastructure.db.erb'),
      replace => false,
      require => File['infrastructure host configuration']
    }

    $named_infra_files = [
      File['infrastructure host configuration'],
      File['named infrastructure key'],
      File['infrastructure zone contents'],
    ]

  } else {
    file { 'empty infrastructure host configuration':
      ensure  => present,
      replace => false,
      path    => '/var/named/oo_infrastructure.conf',
      owner   => 'root',
      group   => 'named',
      mode    => '0644',
      content => '// no openshift infrastructure zone',
      require => File['/var/named']
    }

    $named_infra_files = [
      File['empty infrastructure host configuration'],
    ]
  }

  $restorecon_paths = '/etc/rndc.* /etc/named.* /var/named /var/named/forwarders.conf'
  $named_files = unique(flatten([$named_base_files, $named_infra_files]))

  exec { 'named restorecon':
    command     => '/sbin/restorecon -rv ${restorecon_paths}',
    require     => Exec['create rndc.key'],
    notify      => Service['named'],
    refreshonly => true,
    subscribe   => $named_files,
  }

  service { 'named':
    ensure    => running,
    enable    => true,
    subscribe => $named_files,
  }
}
