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

  ensure_resource('package', [
      'rubygem-openshift-origin-node',
      "${::openshift_origin::ruby_scl_prefix}rubygem-passenger-native",
      'openshift-origin-port-proxy',
      'openshift-origin-node-util',
      'policycoreutils-python',
      'openshift-origin-msg-node-mcollective',
      'git',
      'make',
      'oddjob',
      'vim-enhanced',
    ], {
      ensure  => present,
      require => Class['openshift_origin::install_method'],
    }
  )
  
  include openshift_origin::cartridges
  include openshift_origin::mcollective_server  
  
  file { 'openshift node config':
    ensure  => present,
    path    => '/etc/openshift/node.conf',
    content => template('openshift_origin/node/node.conf.erb'),
    require => Package['rubygem-openshift-origin-node'],
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
    
  # We combine these setsebool commands into a single semanage command
  # because separate commands take a long time to run.
  exec { 'node selinux booleans':
    command  => template('openshift_origin/selinux/node.erb'),
    provider => 'shell',
    require  => [
      Package['rubygem-openshift-origin-node'],
      File['openshift node config'],
    ]
  }
  
  exec { 'Initialize quota DB':
    command => '/usr/sbin/oo-init-quota',
    require => Package['openshift-origin-node-util'],
    unless  => '/usr/bin/quota -f /var/lib/openshift/ -q 2>/dev/null',
  }
  
  augeas { 'Tune Sysctl knobs':
    context => "/files/etc/sysctl.conf",
    changes => [
      # Increase kernel semaphores to accomodate many httpds.
      "set kernel.sem '250  32000 32  4096'",

      # Move ephemeral port range to accommodate app proxies.
      "set net.ipv4.ip_local_port_range '15000 35530'",

      # Increase the connection tracking table size.
      "set net.netfilter.nf_conntrack_max 1048576"
    ],
    notify => Exec['Reload sysctl']
  }
  
  # Reload sysctl.conf to get the new settings.
  #
  # Note: We could add -e here to ignore errors that are caused by
  # options appearing in sysctl.conf that correspond to kernel modules
  # that are not yet loaded.  On the other hand, adding -e might cause
  # us to miss some important error messages.
  exec{ 'Reload sysctl':
    command     => '/usr/sbin/sysctl -p /etc/sysctl.conf',
    refreshonly => true,
  }
  
  case $::openshift_origin::node_container_plugin {
    'selinux': { include openshift_origin::plugins::container::selinux }
    'libvirt': { include openshift_origin::plugins::container::libvirt }
  }
  
  if member( $::openshift_origin::node_frontend_plugins, 'apache-mod-rewrite' ) { include openshift_origin::plugins::frontend::apache_mod_rewrite }
  if member( $::openshift_origin::node_frontend_plugins, 'nodejs-websocket' ) { include openshift_origin::plugins::frontend::nodejs_websocket }
  
  augeas { 'Tune sshd config':
    context => "/files/etc/ssh/sshd_config",
    changes => [
      'set MaxSessions 40',
      'set MaxStartups 40',
      'set AcceptEnv[5]/01 GIT_SSH',
    ],
    onlyif => "match AcceptEnv[*]/*[. = 'GIT_SSH'] size == 0"
  }
  
  service { [
      'openshift-port-proxy',
      'openshift-tc',
      'sshd',
      'oddjobd',
      'messagebus',
    ]:
    enable  => true,
    require => [
      Package['openshift-origin-port-proxy'],
      Package['rubygem-openshift-origin-node'],      
      Package['openshift-origin-node-util'],
      Package["mcollective"],
      Package["oddjob"],
    ],
  }
  
  service { ['openshift-gears']:
    enable  => true,
    require => [
      Package['rubygem-openshift-origin-node'],      
      Package['openshift-origin-node-util'],
    ],
    provider => $os_init_provider,
  }
  
  file { 'create node setting markers dir':
    ensure  => 'directory',
    path    => '/var/lib/openshift/.settings',
    owner   => 'root',
    group   => 'root',
    mode    => '0755'
  }
  
  exec { 'Open port for SSH':
    command => "${openshift_origin::params::firewall_service_cmd}ssh",
    require => Package['firewall-package'],
  }

  exec { 'Open port for HTTP':
    command => "${openshift_origin::params::firewall_service_cmd}http",
    require => Package['firewall-package'],
  }

  exec { 'Open port for HTTPS':
    command => "${openshift_origin::params::firewall_service_cmd}https",
    require => Package['firewall-package'],
  }
  
  $webproxy_http_port = $::use_firewalld ? {
    'true'  => '8000/tcp',
    default => '8000:tcp',
  }

  exec { 'Open HTTP port for Node-webproxy':
    command => "${openshift_origin::params::firewall_port_cmd}${webproxy_http_port}",
    require => Package['firewall-package'],
  }

  $webproxy_https_port = $::use_firewalld ? {
    'true'  => '8443/tcp',
    default => '8443:tcp',
  }

  exec { 'Open HTTPS port for Node-webproxy':
    command => "${openshift_origin::params::firewall_port_cmd}${webproxy_https_port}",
    require => Package['firewall-package'],
  }
}
