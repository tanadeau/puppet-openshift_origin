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
class openshift_origin::broker {
  include openshift_origin::broker_console_dirs
  include openshift_origin::firewall::apache
  include openshift_origin::selbooleans
  include openshift_origin::selbooleans::broker_console
  include openshift_origin::rsyslog

  anchor { 'openshift_origin::broker_begin': } ->
  Class['openshift_origin::broker_console_dirs'] ->
  Class['openshift_origin::selbooleans'] ->
  Class['openshift_origin::selbooleans::broker_console'] ->
  Class['openshift_origin::firewall::apache'] ->
  anchor { 'openshift_origin::broker_end': }

  anchor { 'openshift_origin::broker_frontend_begin': } ->
  class { 'openshift_origin::plugins::frontend::apache': } ->
  anchor { 'openshift_origin::broker_frontend_end': }

  anchor { 'openshift_origin::broker_mco_begin': } ->
  class { 'openshift_origin::mcollective_client': } ->
  anchor { 'opensfhit_origin::broker_mco_end': }

  case $::openshift_origin::broker_dns_plugin {
    'nsupdate' : {
      anchor { 'openshift_origin::broker_dns_begin': } ->
      class { 'openshift_origin::plugins::dns::nsupdate': } ->
      anchor { 'openshift_origin::broker_dns_end': }
    }
    'avahi'    : {
      anchor { 'openshift_origin::broker_dns_begin': } ->
      class { 'openshift_origin::plugins::dns::avahi': } ->
      anchor { 'openshift_origin::broker_dns_end': }
    }
    'route53'  : {
      anchor { 'openshift_origin::broker_dns_begin': } ->
      class { 'openshift_origin::plugins::dns::route53': } ->
      anchor { 'openshift_origin::broker_dns_end': }
    }
    default    : { fail('A broker_dns_plugin value must be specified. Supported values are: nsupdate, avahi, route53.') }
  }

  case $::openshift_origin::broker_auth_plugin {
    'mongo'    : {
      anchor { 'openshift_origin::broker_auth_begin': } ->
      class { 'openshift_origin::plugins::auth::mongo': } ->
      anchor { 'openshift_origin::broker_auth_end': }
    }
    'htpasswd' : {
      anchor { 'openshift_origin::broker_auth_begin': } ->
      class { 'openshift_origin::plugins::auth::htpasswd': } ->
      anchor { 'openshift_origin::broker_auth_end': }
    }
    'kerberos' : {
      anchor { 'openshift_origin::broker_auth_begin': } ->
      class { 'openshift_origin::plugins::auth::kerberos': } ->
      anchor { 'openshift_origin::broker_auth_end': }
    }
    'ldap'     : {
      anchor { 'openshift_origin::broker_auth_begin': } ->
      class { 'openshift_origin::plugins::auth::ldap': } ->
      anchor { 'openshift_origin::broker_auth_end': }
    }
    default    : {
      anchor { 'openshift_origin::broker_auth_begin': } ->
      class { 'openshift_origin::plugins::auth::htpasswd': } ->
      anchor { 'openshift_origin::broker_auth_end': }
    }
  }

  package {
    [
      'openshift-origin-broker',
      'openshift-origin-broker-util',
      'rubygem-openshift-origin-msg-broker-mcollective',
      'rubygem-openshift-origin-admin-console',
    ]:
    ensure  => present,
    require => [
      Class['openshift_origin::install_method'],
      Package['httpd'],
    ]
  }

  # declare all resources with the common set of parameters
  file {
    [
      '/var/log/openshift/broker',
      '/var/www/openshift/broker',
      '/var/www/openshift/broker/httpd',
      '/var/www/openshift/broker/httpd/run',
      '/var/www/openshift/broker/tmp',
      '/var/www/openshift/broker/tmp/cache',
      '/var/www/openshift/broker/tmp/sessions',
      '/var/www/openshift/broker/tmp/pids',
      '/var/www/openshift/broker/tmp/sockets',
    ]:
    ensure  => directory,
  }

  selinux_fcontext { '/var/www/openshift/broker/httpd/run(/.*)?':
    ensure  => 'present',
    seltype => 'httpd_var_run_t',
  }

  selinux_fcontext { '/var/www/openshift/broker/tmp(/.*)?':
    ensure  => 'present',
    seltype => 'httpd_tmp_t',
  }

  selinux_fcontext { '/var/log/openshift/broker(/.*)?':
    ensure  => 'present',
    seltype => 'httpd_log_t',
  }

  # Make sure the semanage rules are set up right away.
  File['/var/www/openshift/broker/httpd/run'] {
      seltype => 'httpd_var_run_t',
      require => [
        Package['httpd'],
        Class['openshift_origin::broker_console_dirs'],
        Selinux_fcontext['/var/www/openshift/broker/httpd/run(/.*)?'],
      ]
  }

  File['/var/www/openshift/broker/tmp'] {
    purge   => true,
    recurse => true,
    seltype => 'httpd_tmp_t',
    require => [
      Package['httpd'],
      Class['openshift_origin::broker_console_dirs'],
      Selinux_fcontext['/var/www/openshift/broker/tmp(/.*)?'],
      Exec['Broker gem dependencies'],
    ]
  }

  File['/var/log/openshift/broker'] {
    seltype => 'httpd_log_t',
    require => [
      Class['openshift_origin::broker_console_dirs'],
      Selinux_fcontext['/var/log/openshift/broker(/.*)?'],
    ]
  }

  if $::openshift_origin::conf_broker_auth_private_key == undef {
    exec { 'Generate self signed keys for broker auth':
      command => '/usr/bin/openssl genrsa -out /etc/openshift/server_priv.pem 2048 && \
                  /usr/bin/openssl rsa -in /etc/openshift/server_priv.pem -pubout > \
                  /etc/openshift/server_pub.pem',
      creates => '/etc/openshift/server_pub.pem',
      require => Class['openshift_origin::broker_console_dirs'],
      notify  => Service['openshift-broker'],
    }
  } else {
    file { 'broker auth private key':
      ensure  => present,
      path    => '/etc/openshift/server_priv.pem',
      content => $::openshift_origin::conf_broker_auth_private_key,
      owner   => 'apache',
      group   => 'apache',
      mode    => '0640',
      require => [ Class['openshift_origin::broker_console_dirs'], Package['httpd'], ],
      notify  => Service['openshift-broker'],
    }

    exec { 'broker auth public key':
      command => '/usr/bin/openssl rsa -in /etc/openshift/server_priv.pem -pubout > \
                  /etc/openshift/server_pub.pem && chown apache:apache \
                  /etc/openshift/server_pub.pem && chmod 0640 /etc/openshift/server_pub.pem',
      creates => '/etc/openshift/server_pub.pem',
      require => File['broker auth private key'],
      notify  => Service['openshift-broker'],
    }
  }

  if $::openshift_origin::quickstarts_json {
    $quickstart_content = $::openshift_origin::quickstarts_json
  } elsif $::openshift_origin::ose_version == undef {
    $quickstart_content = template('openshift_origin/broker/quickstarts.json.erb')
  } else {
    $quickstart_content = ''
  }

  exec {'clear console cache':
    refreshonly => true,
    subscribe   => File['quickstarts'],
    command     => 'oo-admin-console-cache --clear',
  }

  file { 'quickstarts':
    ensure  => present,
    path    => '/etc/openshift/quickstarts.json',
    content => $quickstart_content,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['openshift-origin-broker'],
    notify  => Service['openshift-broker'],
  }

  file { 'mcollective broker plugin config':
    ensure  => present,
    path    => '/etc/openshift/plugins.d/openshift-origin-msg-broker-mcollective.conf',
    content => template('openshift_origin/broker/msg-broker-mcollective.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['rubygem-openshift-origin-msg-broker-mcollective'],
  }

  file { 'openshift broker.conf':
    path    => '/etc/openshift/broker.conf',
    content => template('openshift_origin/broker/broker.conf.erb'),
    owner   => 'apache',
    group   => 'apache',
    mode    => '0644',
    require => Package['openshift-origin-broker','httpd'],
    notify  => Service['openshift-broker'],
  }

  if $::openshift_origin::development_mode == true {
    file { 'openshift broker-dev.conf':
      path    => '/etc/openshift/broker-dev.conf',
      content => template('openshift_origin/broker/broker.conf.erb'),
      owner   => 'apache',
      group   => 'apache',
      mode    => '0644',
      require => Package['openshift-origin-broker','httpd'],
      notify  => Service['openshift-broker'],
    }
  }
  $development_file_present = $::openshift_origin::development_mode ? {
    true    => present,
    default => absent,
  }
  file { '/etc/openshift/development':
    ensure => $development_file_present,
    source => 'puppet:///modules/openshift_origin/development',
  }

  # SCL and Puppet don't play well together; circumvents the use of the `scl enable ruby193` mechanism while
  # still invoking ruby commands in the correct context
  $broker_bundle_show = 'LD_LIBRARY_PATH=/opt/rh/ruby193/root/usr/lib64 GEM_PATH=/opt/rh/ruby193/root/usr/local/share/gems:/opt/rh/ruby193/root/usr/share/gems /opt/rh/ruby193/root/usr/bin/bundle show'

  exec { 'Broker gem dependencies':
    cwd         => '/var/www/openshift/broker/',
    command     => "rm -f Gemfile.lock && ${broker_bundle_show}",
    before      => File['/var/www/openshift/broker/tmp'],
    require     => [
      Package['openshift-origin-broker'],
      File['openshift broker.conf','mcollective broker plugin config'],
    ],
    notify      => [
      Service['openshift-broker'],
      File['/var/www/openshift/broker/Gemfile.lock'],
    ],
    subscribe   => Package['openshift-origin-broker'],
    refreshonly => true,
  }

  # This File resource is to guarantee that the Gemfile.lock created
  # by the subscribed Exec has the appropriate permissions (otherwise
  # it is created as owned by root:root)
  file { '/var/www/openshift/broker/Gemfile.lock':
    ensure                  => present,
    owner                   => 'apache',
    group                   => 'apache',
    mode                    => '0644',
    selinux_ignore_defaults => true,
    require                 => Package['openshift-origin-broker','httpd'],
    subscribe               => Exec['Broker gem dependencies'],
  }

  service { 'openshift-broker':
    ensure     => true,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['openshift-origin-broker'],
    subscribe  => File['/etc/openshift/development'],
  }
  exec { 'Remove mod_ssl default vhost':
    command => '/bin/sed -i \'/VirtualHost/,/VirtualHost/ d\' /etc/httpd/conf.d/ssl.conf',
    onlyif  => '/bin/grep \'VirtualHost _default\' /etc/httpd/conf.d/ssl.conf',
    require => Package['openshift-origin-broker'],
    notify  => Service['httpd'],
  }

  if $::openshift_origin::apache_https_port != '443' {
    exec { 'Change mod_ssl Listen port':
      command => "/bin/sed -i 's/^Listen 443$/Listen ${::openshift_origin::apache_https_port}/' /etc/httpd/conf.d/ssl.conf",
      onlyif  => '/bin/grep \'^Listen 443$\' /etc/httpd/conf.d/ssl.conf',
      require => Package['openshift-origin-broker'],
      notify  => Service['httpd'],
    }
  }
}
