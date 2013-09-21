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
class openshift_origin::params {
  # Make sure the tools needed to manage the firewall are installed
  $firewall_package     = $::use_firewalld ? {
    'true'  => 'firewalld',
    default => 'system-config-firewall-base',
  }

  # Set the base firewall command for enableling services
  $firewall_service_cmd = $::use_firewalld ? {
    'true'  => '/usr/bin/firewall-cmd --permanent --zone=public --add-service=',
    default => '/usr/sbin/lokkit --service=',
  }

  # Set the base firewall command for enableling services
  $firewall_port_cmd    = $::use_firewalld ? {
    'true'  => '/usr/bin/firewall-cmd --permanent --zone=public --add-port=',
    default => '/usr/sbin/lokkit --port=',
  }
  
  $os_init_provider     =  $::operatingsystem ? {
    'Fedora' => 'systemd',
    'CentOS' => 'redhat',
    default  => 'redhat',
  }
  
  $service   = $::operatingsystem ? {
    'Fedora' => '/usr/sbin/service',
    default  => '/sbin/service',
  }

  $rpm       = $::operatingsystem ? {
    'Fedora' => '/usr/bin/rpm',
    default  => '/bin/rpm',
  }

  $rm        = $::operatingsystem ? {
    'Fedora' => '/usr/bin/rm',
    default  => '/bin/rm',
  }

  $touch     = $::operatingsystem ? {
    'Fedora' => '/usr/bin/touch',
    default  => '/bin/touch',
  }

  $chown     = $::operatingsystem ? {
    'Fedora' => '/usr/bin/chown',
    default  => '/bin/chown',
  }

  $httxt2dbm = $::operatingsystem ? {
    'Fedora' => '/usr/bin/httxt2dbm',
    default  => '/usr/sbin/httxt2dbm',
  }

  $chmod     = $::operatingsystem ? {
    'Fedora' => '/usr/bin/chmod',
    default  => '/bin/chmod',
  }

  $grep      = $::operatingsystem ? {
    'Fedora' => '/usr/bin/grep',
    default  => '/bin/grep',
  }

  $cat       = $::operatingsystem ? {
    'Fedora' => '/usr/bin/cat',
    default  => '/bin/cat',
  }

  $mv        = $::operatingsystem ? {
    'Fedora' => '/usr/bin/mv',
    default  => '/bin/mv',
  }

  $echo      = $::operatingsystem ? {
    'Fedora' => '/usr/bin/echo',
    default  => '/bin/echo',
  }
}