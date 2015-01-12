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
class openshift_origin::rsyslog {

  if $::openshift_origin::syslog_enabled == true {
    file { '/tmp/rsyslog7_yum.txt':
      ensure => 'file',
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/openshift_origin/rsyslog7_yum.txt'
    }

    exec {'install_rsyslog7':
      provider  => shell,
      path      => [ '/bin/', '/usr/bin/' ],
      logoutput => true,
      command   => '/usr/bin/yum shell -y /tmp/rsyslog7_yum.txt',
      require   => File['/tmp/rsyslog7_yum.txt'],
      unless    => 'rpm -q rsyslog7'
    }

    if $::openshift_origin::syslog_central_server_hostname != undef {
      file { '/etc/rsyslog.d/forward.conf':
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        content => template('openshift_origin/rsyslog/forward_conf.erb'),
        require => Exec['install_rsyslog7'],
        notify  => Service['rsyslog']
      }
    }

    service { 'rsyslog':
      ensure  => running,
      enable  => true,
      require => Exec['install_rsyslog7']
    }
  }
}

