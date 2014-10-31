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
#
# == Class openshift_origin::httpd_certificate
# Generates a self-signed certificate for the host httpd if necessary
#
class openshift_origin::httpd_certificate {
  if member( $::openshift_origin::roles, 'node' ) {
    $cert_domain   = "*.${::openshift_origin::domain}"
    $cert_requires = Package['httpd']
  }
  else {
    $cert_domain   = $::openshift_origin::broker_hostname
    $cert_requires = Package['openshift-origin-broker']
  }

  if member( $::openshift_origin::roles, 'node' ) and
      ($::openshift_origin::conf_node_public_key != undef) and
      ($::openshift_origin::conf_node_private_key != undef) {
    file { 'node public key':
      ensure  => present,
      path    => '/etc/pki/tls/certs/localhost.crt',
      content => $::openshift_origin::conf_node_public_key,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      require => Package['httpd'],
      notify  => Service['httpd'],
    }

    file { 'node private key':
      ensure  => present,
      path    => '/etc/pki/tls/private/localhost.key',
      content => $::openshift_origin::conf_node_private_key,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      require => Package['httpd'],
      notify  => Service['httpd'],
    }
  }
  else {
    exec { 'generate self-signed httpd keypair':
      command => "cat << EOF | /usr/bin/openssl req -new -rand /dev/urandom \
        -newkey rsa:2048 -nodes -keyout /etc/pki/tls/private/localhost.key \
        -x509 -days 3650 \
        -out /etc/pki/tls/certs/localhost.crt 2> /dev/null && chmod 0600 \
        /etc/pki/tls/private/localhost.key /etc/pki/tls/certs/localhost.crt
XX
SomeState
SomeCity
${::openshift_origin::conf_console_product_title} default
Temporary certificate
${cert_domain}
root@${::openshift_origin::domain}
EOF",
      creates => '/etc/pki/tls/certs/localhost.crt',
      require => $cert_requires,
      notify  => Service['httpd'],
    }
  }
}
