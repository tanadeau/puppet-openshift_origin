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
class openshift_origin::console {
  if $::openshift_origin::manage_firewall {
    include openshift_origin::firewall::apache
  }
  include openshift_origin::selbooleans
  include openshift_origin::selbooleans::broker_console
  include openshift_origin::broker_console_dirs

  package { 'openshift-origin-console':
    ensure  => present,
    require => [
      Class['openshift_origin::install_method'],
      Package['httpd'],
    ]
  }

  # These dirs should be created by the package.
  file {
    [
      '/var/log/openshift/console',
      '/var/log/openshift/console/httpd',
      '/var/www/openshift/console',
      '/var/www/openshift/console/httpd',
      '/var/www/openshift/console/httpd/run',
    ]:
    ensure  => directory,
  }

  selinux_fcontext {
    [
      '/var/log/openshift/console(/.*)?',
      '/var/log/openshift/console/httpd(/.*)?',
    ]:
    ensure   => 'present',
    seltype  => 'httpd_log_t',
  }

  selinux_fcontext { '/var/www/openshift/console/httpd/run(/.*)?':
    ensure   => 'present',
    seltype  => 'httpd_var_run_t',
  }

  # Add semanage types to dirs before anything else goes into them.
  File['/var/log/openshift/console'] {
    seltype => 'httpd_log_t',
    require => [
      Class['openshift_origin::broker_console_dirs'],
      Selinux_fcontext['/var/log/openshift/console(/.*)?'],
    ],
  }

  File['/var/www/openshift/console/httpd/run'] {
    seltype => 'httpd_var_run_t',
    require => [
      Package['httpd'],
      Class['openshift_origin::broker_console_dirs'],
      Selinux_fcontext['/var/www/openshift/console/httpd/run(/.*)?'],
    ],
  }

  file { 'openshift console.conf':
    path    => '/etc/openshift/console.conf',
    content => template('openshift_origin/console/console.conf.erb'),
    owner   => 'apache',
    group   => 'apache',
    mode    => '0644',
    require => [
      Package['openshift-origin-console'],
      Class['openshift_origin::broker_console_dirs'],
    ],
    notify  => Service['openshift-console'],
  }

  if $::openshift_origin::development_mode == true {
    file { 'openshift console-dev.conf':
      path    => '/etc/openshift/console-dev.conf',
      content => template('openshift_origin/console/console.conf.erb'),
      owner   => 'apache',
      group   => 'apache',
      mode    => '0644',
      require => [
        Package['openshift-origin-console'],
        Class['openshift_origin::broker_console_dirs'],
      ],
      notify  => Service['openshift-console'],
    }
  }

  exec { 'restorecon console dir':
    command  => 'restorecon -R /var/www/openshift/console',
    provider => 'shell',
    require  => Package['openshift-origin-console'],
    notify   => Service['openshift-console'],
  }

  service { 'openshift-console':
    ensure     => true,
    require    => Package['openshift-origin-console'],
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
