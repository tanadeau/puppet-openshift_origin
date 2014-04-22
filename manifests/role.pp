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
define register_dns( $fqdn ) {
  if $::openshift_origin::register_host_with_nameserver {
    if $fqdn != 'localhost' {
      ensure_resource( 'exec', "Register ${fqdn}", {
          command => template("openshift_origin/register_dns.erb"),
          provider => 'shell'
        }
      )
    }
  }
}

class openshift_origin::install_method {
  include openshift_origin::params

  case $::openshift_origin::install_method {
    'none' : {}
    'yum'  : {
      include openshift_origin::yum_install_method
      # TODO: This is a major hack intended to ensure that all yum repos are defined before we try to do anything else.
      file { '/tmp':
        ensure  => directory,
        require => Class['openshift_origin::yum_install_method'],
      }
    }
  }
}

class openshift_origin::role {
  include openshift_origin::params
  include openshift_origin::install_method
  if $::openshift_origin::manage_firewall {
    include openshift_origin::firewall::ssh
  }

  if ( $::openshift_origin::configure_ntp ) {
    package { 'ntpdate':
      ensure => 'present',
    }
    class { 'ntp':
      servers    => $::openshift_origin::ntp_servers,
      autoupdate => true,
    }
  }
}

class openshift_origin::role::broker inherits openshift_origin::role {
  include openshift_origin::client_tools
  include openshift_origin::broker
  include openshift_origin::console

  register_dns{ 'register broker dns':
    fqdn    => $::openshift_origin::broker_hostname,
    require => Class['openshift_origin::client_tools','openshift_origin::broker','openshift_origin::console']
  }
}

class openshift_origin::role::nameserver inherits openshift_origin::role {
  include openshift_origin::nameserver
  
  register_dns{ 'register nameserver dns':
    fqdn    => $::openshift_origin::nameserver_hostname,
    require => Class['openshift_origin::nameserver']
  }
}

class openshift_origin::role::node inherits openshift_origin::role {
  include openshift_origin::node

  register_dns{ 'register node dns':
    fqdn    => $::openshift_origin::node_hostname,
    require => Class['openshift_origin::node'],
  }
}

class openshift_origin::role::msgserver inherits openshift_origin::role {
  include openshift_origin::msgserver

  register_dns{ 'register msgserver dns':
    fqdn    => $::openshift_origin::msgserver_hostname,
    require => Class['openshift_origin::msgserver'],
  }
}

class openshift_origin::role::datastore inherits openshift_origin::role {
  include openshift_origin::datastore

  register_dns{ 'register datastore dns':
    fqdn    => $::openshift_origin::datastore_hostname,
    require => Class['openshift_origin::datastore'],
  }
}
