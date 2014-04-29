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
define openshift_origin::openshift_cartridge  {
  $cart_prefix = 'openshift-origin-cartridge-'
  case $name {
    'jenkins', 'jenkins-client': {
      include openshift_origin::cartridges::jenkins
      $full_cart_name = "${cart_prefix}${name}"
    }
    'mariadb', 'mysql': {
      case $::operatingsystem {
        'Fedora' : {
          $full_cart_name = "${cart_prefix}mariadb"
        }
        default  : {
          $full_cart_name = "${cart_prefix}mysql"
        }
      }
    }
    default: {
      $full_cart_name = "${cart_prefix}${name}"
    }
  }
  package { $full_cart_name:
    ensure  => present,
    require => Class['openshift_origin::install_method'],
    notify  => Service["${::openshift_origin::params::ruby_scl_prefix}mcollective"],
  }
}
