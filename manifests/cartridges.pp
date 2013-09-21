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
class openshift_origin::cartridges {
  package { 'jenkins':
    ensure  => "1.510-1.1",
  }

  package { 'yum-plugin-versionlock':
    ensure  => latest,
  }

  exec { '/usr/bin/yum versionlock jenkins':
    require => [
      Package['jenkins'],
      Package['yum-plugin-versionlock'],
    ]
  }

  case $::operatingsystem {
    'Fedora' : {
      $mariadb_cart = 'openshift-origin-cartridge-mariadb'
    }
    default  : {
      $mariadb_cart = 'openshift-origin-cartridge-mysql'    
    }
  }
  
  ensure_resource('package', [
      'openshift-origin-cartridge-10gen-mms-agent',
      'openshift-origin-cartridge-cron',
      'openshift-origin-cartridge-diy',
      'openshift-origin-cartridge-haproxy',
      'openshift-origin-cartridge-mongodb',
      'openshift-origin-cartridge-nodejs',
      'openshift-origin-cartridge-perl',
      'openshift-origin-cartridge-php',
      'openshift-origin-cartridge-phpmyadmin',
      'openshift-origin-cartridge-postgresql',
      'openshift-origin-cartridge-python',
      'openshift-origin-cartridge-ruby',
      'openshift-origin-cartridge-jenkins',
      'openshift-origin-cartridge-jenkins-client',
      $mariadb_cart,
    ], {
      ensure  => latest,
      require => [
        Class['openshift_origin::install_method'],
        Package['jenkins'],
      ],
      notify => Exec['oo-admin-cartridge'],
    }
  )
  
  if( $::openshift_origin::install_jbossews_cartridge == true ) {
    ensure_resource('package', 'openshift-origin-cartridge-jbossews', {
        ensure  => latest,
        require => [
          Class['openshift_origin::install_method'],
        ],
        notify => Exec['oo-admin-cartridge'],
      }
    )
  }
  
  if( $::openshift_origin::install_jbosseap_cartridge == true ) {
    ensure_resource('package', 'openshift-origin-cartridge-jbosseap', {
        ensure  => latest,
        require => [
          Class['openshift_origin::install_method'],
        ],
        notify => Exec['oo-admin-cartridge'],
      }
    )
  }
  
  if( $::openshift_origin::install_jbossas_cartridge == true ) {
    ensure_resource('package', 'openshift-origin-cartridge-jbossas', {
        ensure  => latest,
        require => [
          Class['openshift_origin::install_method'],
        ],
        notify => Exec['oo-admin-cartridge'],
      }
    )
  }
  
  if( $::openshift_origin::development_mode == true ) {
    package { [
      'openshift-origin-cartridge-mock',
      'openshift-origin-cartridge-mock-plugin',
    ]:
      ensure  => latest,
      require => [
        Class['openshift_origin::install_method'],
      ],
      notify => Exec['oo-admin-cartridge'],
    }
  }
  
  # Note, this does not handle cartridge uninstalls
  exec { 'oo-admin-cartridge':
    command     => '/usr/sbin/oo-admin-cartridge --recursive -a install -s /usr/libexec/openshift/cartridges/',
    refreshonly => true,
    notify      => Exec['openshift-facts']
  }
}