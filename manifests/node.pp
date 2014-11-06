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
class openshift_origin::node {
  include openshift_origin::params
  include openshift_origin::firewall::apache
  include openshift_origin::firewall::apache_node
  include openshift_origin::firewall::node
  include openshift_origin::selbooleans
  include openshift_origin::selbooleans::node
  include openshift_origin::httpd_certificate


  anchor { 'openshift_origin::node_begin': } ->
  Class['openshift_origin::selbooleans'] ->
  Class['openshift_origin::selbooleans::node'] ->
  Class['openshift_origin::firewall::apache'] ->
  Class['openshift_origin::firewall::apache_node'] ->
  Class['openshift_origin::firewall::node'] ->
  Class['openshift_origin::httpd_certificate'] ->
  class{ 'openshift_origin::mcollective_server': } ->
  anchor { 'openshift_origin::node_end': }

  anchor { 'openshift_origin::node_cart_begin': } ->
  class { 'openshift_origin::cartridges': } ->
  anchor { 'openshift_origin::node_cart_end': }

  package {
    ['rubygem-openshift-origin-node',
      "${::openshift_origin::params::ruby_scl_prefix}rubygem-passenger-native",
      'openshift-origin-node-util',
      'policycoreutils-python',
      'openshift-origin-msg-node-mcollective',
      'git',
      'make',
      'oddjob',
      'dbus',
      'vim-enhanced',
      'mlocate',
      'screen',
      'libcgroup',
    ]:
    ensure  => present,
    require => Class['openshift_origin::install_method'],
  }

  # If the node_frontend_has changed since our first run then we don't
  # want to make any changes, probably want to check for existence of gears
  # for the corner case where puppet is first run after another deployment
  exec { 'node_frontend_marker':
    command => "echo ${::openshift_origin::node_frontend_plugins} > /etc/openshift/.puppet_node_frontend_plugins",
    creates => '/etc/openshift/.puppet_node_frontend_plugins',
    require => Package['rubygem-openshift-origin-node'],
  }
  file { '/etc/openshift/.puppet_proposed_node_frontend_plugins':
    content => inline_template("${openshift_origin::node_frontend_plugins}\n"),
    require => Package['rubygem-openshift-origin-node'],
  }
  exec { 'prevent_node_frontend_changes':
    command => '/usr/bin/diff /etc/openshift/.puppet_node_frontend_plugins /etc/openshift/.puppet_proposed_node_frontend_plugins',
    require => [
        File['/etc/openshift/.puppet_proposed_node_frontend_plugins'],
        Exec['node_frontend_marker'],
      ]
  }

  file { 'openshift node config':
    ensure  => present,
    path    => '/etc/openshift/node.conf',
    content => template('openshift_origin/node/node.conf.erb'),
    require => [
        Package['rubygem-openshift-origin-node'],
        Exec['prevent_node_frontend_changes'],
      ],
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service["${::openshift_origin::params::ruby_scl_prefix}mcollective"],
  }
  file { 'openshift node resource limit config':
    ensure  => present,
    path    => '/etc/openshift/resource_limits.conf',
    content => template('openshift_origin/node/resource_limits.conf.erb'),
    require => Package['rubygem-openshift-origin-node'],
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Exec['restart resource limiting services'],
  }
  exec { 'restart resource limiting services':
    command     => 'oo-cgroup-enable --with-all-containers; oo-pam-enable --with-all-containers; oo-admin-ctl-tc restart',
    notify      => Service["${::openshift_origin::params::ruby_scl_prefix}mcollective"],
    require     => File['openshift node config'],
    refreshonly => true,
  }
  if $::openshift_origin::conf_node_custom_motd != undef {
    file { 'custom motd file':
      ensure  => present,
      path    => '/etc/openshift/welcome.rhcsh',
      content => $::openshift_origin::conf_node_custom_motd,
      require => Package['rubygem-openshift-origin-node'],
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  }
  exec { 'Initialize quota DB':
    command => '/usr/sbin/oo-init-quota',
    require => Package['openshift-origin-node-util'],
    path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    unless  => '/usr/bin/quota -f $(df /var/lib/openshift/ | tail -1 | tr -s \' \' | cut -d\' \' -f 6 | sort -u) -q 2>/dev/null',
  }
  sysctl::value { 'kernel.sem':
    value => "250\t32000\t32\t4096",
  }
  sysctl::value { 'net.ipv4.ip_local_port_range':
    value => "15000\t35530",
  }
  sysctl::value { 'net.netfilter.nf_conntrack_max':
    value => '1048576',
  }
  sysctl::value { 'net.ipv4.ip_forward':
    value => '1',
  }
  sysctl::value { 'net.ipv4.conf.all.route_localnet':
    value => '1',
  }
  sysctl::value { 'kernel.shmall':
    value => $::openshift_origin::params::_node_shmall,
  }
  sysctl::value { 'kernel.shmmax':
    value => $::openshift_origin::params::_node_shmmax,
  }
  sysctl::value { 'kernel.msgmnb':
    value => 65536,
  }
  sysctl::value { 'kernel.msgmax':
    value => '65536',
  }

  # Reuse closed connections quickly
  # As recommended elsewhere and investigated at length in https://bugzilla.redhat.com/show_bug.cgi?id=1085115
  # this is a safe, effective way to keep lots of short requests from exhausting the connection table.
  sysctl::value { 'net.ipv4.tcp_tw_reuse':
    value => '1',
  }

  case $::openshift_origin::node_container_plugin {
    'selinux': {
      anchor { 'openshift_origin::node_container_begin': } ->
      class { 'openshift_origin::plugins::container::selinux': } ->
      anchor { 'openshift_origin::node_container_end': }
     }
    'libvirt': {
      anchor { 'openshift_origin::node_container_begin': } ->
      class { 'openshift_origin::plugins::container::libvirt': } ->
      anchor { 'openshift_origin::node_container_end': }
     }
    default: {}
  }

  if member( $::openshift_origin::node_frontend_plugins, 'apache-mod-rewrite' ) {
    anchor { 'openshift_origin::node_frontend_begin': } ->
    class { 'openshift_origin::plugins::frontend::apache_mod_rewrite': } ->
    anchor { 'openshift_origin::node_frontend_end': }
  }
  elsif member( $::openshift_origin::node_frontend_plugins, 'apache-vhost' ) {
    anchor { 'openshift_origin::node_frontend_begin': } ->
    class { 'openshift_origin::plugins::frontend::apache_vhost': } ->
    anchor { 'openshift_origin::node_frontend_end': }
  }
  if member( $::openshift_origin::node_frontend_plugins, 'nodejs-websocket' ) {
    anchor { 'openshift_origin::node_ws_frontend_begin': } ->
    class { 'openshift_origin::plugins::frontend::nodejs_websocket': } ->
    anchor { 'openshift_origin::node_ws_frontend_end': }
  }
  if member( $::openshift_origin::node_frontend_plugins, 'haproxy-sni-proxy' ) and ($::operatingsystem != 'Fedora') {
    anchor { 'openshift_origin::node_sni_frontend_begin': } ->
    class { 'openshift_origin::plugins::frontend::haproxy_sni_proxy': } ->
    anchor { 'openshift_origin::node_sni_frontend_end': }
  }

  augeas { 'Tune sshd config':
    context => '/files/etc/ssh/sshd_config',
    lens    => 'Sshd.lns',
    incl    => '/etc/ssh/sshd_config',
    changes => [
      'set MaxSessions 40',
      'set MaxStartups 40',
      'set AcceptEnv[5]/01 GIT_SSH',
    ],
    onlyif  => 'match AcceptEnv[*]/*[. = \'GIT_SSH\'] size == 0',
    notify  => Service['sshd'],
  }

  service { [
      'openshift-iptables-port-proxy',
      'openshift-tc',
      'sshd',
      'oddjobd',
      'messagebus',
    ]:
    ensure  => running,
    enable  => true,
    require => [
      Package['rubygem-openshift-origin-node'],
      Package['openshift-origin-node-util'],
      Package['mcollective'],
      Package['oddjob'],
      Package['dbus'],
    ],
  }
  Service['messagebus'] -> Service['oddjobd']

  # Fedora already has cgroups as systemd uses  them.
  if $::operatingsystem != 'Fedora' {
    augeas { 'openshift cgconfig':
      context => '/files/etc/cgconfig.conf/mount',
      incl    => '/etc/cgconfig.conf',
      lens    => 'Cgconfig.lns',
      changes => [
        'set blkio /cgroup/blkio',
        'set cpu /cgroup/cpu',
        'set cpuacct /cgroup/cpuacct',
        'set cpuset /cgroup/cpuset',
        'set devices /cgroup/devices',
        'set freezer /cgroup/freezer',
        'set memory /cgroup/memory',
        'set net_cls /cgroup/net_cls',
        'rm #comment \'Managed by puppet:openshift_origin\'',
      ],
      notify  => Exec['prepare cgroups'],
    }

    # TODO: Investigate if restorecons are necessary
    exec { 'prepare cgroups':
      command     => '/sbin/restorecon -rv /etc/cgconfig.conf; mkdir -p /cgroup; restorecon -rv /cgroup',
      refreshonly => true
    }

    service { ['cgconfig', 'cgred']:
      ensure  => running,
      enable  => true,
      require => [Package['libcgroup'], Augeas['openshift cgconfig']],
    }
  }

  service { ['openshift-gears']:
    enable   => true,
    require  => [
      Package['rubygem-openshift-origin-node'],
      Package['openshift-origin-node-util'],
    ],
    provider => $::openshift_origin::params::os_init_provider,
  }

    if $openshift_origin::conf_node_watchman_service {
      service { ['openshift-watchman']:
        ensure   => running,
        enable   => true,
        require  => [
          Package['rubygem-openshift-origin-node'],
          Package['openshift-origin-node-util'],
          Service['openshift-gears'],
        ],
        provider => $::openshift_origin::params::os_init_provider,
      }

      file { '/etc/sysconfig/watchman':
        content => template('openshift_origin/node/watchman.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        notify  => Service['openshift-watchman']
        }
    }

  file { ['/var/lib/openshift/']:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0751',
  }

  file { ['/var/lib/openshift/.settings','/etc/openshift/env/']:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['rubygem-openshift-origin-node']
  }

  file { '/etc/openshift/env/OPENSHIFT_UMASK':
    ensure  => present,
    content => template('openshift_origin/node/ENV_OPENSHIFT_UMASK'),
    require => File['/etc/openshift/env/'],
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  file { '/etc/openshift/env/OPENSHIFT_CLOUD_DOMAIN':
    ensure  => present,
    content => $::openshift_origin::domain,
    require => File['/etc/openshift/env/'],
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  file { '/etc/openshift/env/OPENSHIFT_BROKER_HOST':
    ensure  => present,
    content => $::openshift_origin::broker_hostname,
    require => File['/etc/openshift/env/'],
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
}
