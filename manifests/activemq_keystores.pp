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
# This class creates a java keystore for ActiveMQ using provided CA, Cert, and
# Keys
class openshift_origin::activemq_keystores (

  $ca = $::openshift_origin::msgserver_tls_ca,
  $cert = $::openshift_origin::msgserver_tls_cert,
  $private_key = $::openshift_origin::msgserver_tls_key,
  $keystore_password = $::openshift_origin::msgserver_tls_keystore_password,


  $activemq_confdir = '/etc/activemq',
  $activemq_user = 'activemq',
) {

  # ----- Restart ActiveMQ if the SSL credentials ever change       -----
  # ----- Uncomment if you are fully managing ActiveMQ with Puppet. -----

  Package['activemq'] -> Class[$title]
  Java_ks['activemq_cert:keystore'] ~> Service['activemq']
  Java_ks['activemq_ca:truststore'] ~> Service['activemq']


  # ----- Manage PEM files -----

  File {
    owner => root,
    group => root,
    mode  => 0600,
  }
  file {"${activemq_confdir}/ssl_credentials":
    ensure => directory,
    mode   => '0700',
  }
  file {"${activemq_confdir}/ssl_credentials/activemq_certificate.pem":
    ensure => file,
    source => $cert,
  }
  file {"${activemq_confdir}/ssl_credentials/activemq_private.pem":
    ensure => file,
    source => $private_key,
  }
  file {"${activemq_confdir}/ssl_credentials/ca.pem":
    ensure => file,
    source => $ca,
  }

  # ----- Manage Keystore Contents -----

  # Each keystore should have a dependency on the PEM files it relies on.

  # Truststore with copy of CA cert
  java_ks { 'activemq_ca:truststore':
    ensure       => latest,
    certificate  => "${activemq_confdir}/ssl_credentials/ca.pem",
    target       => "${activemq_confdir}/truststore.jks",
    password     => $keystore_password,
    trustcacerts => true,
    require      => File["${activemq_confdir}/ssl_credentials/ca.pem"],
  }

  # Keystore with ActiveMQ cert and private key
  java_ks { 'activemq_cert:keystore':
    ensure      => latest,
    certificate => "${activemq_confdir}/ssl_credentials/activemq_certificate.pem",
    private_key => "${activemq_confdir}/ssl_credentials/activemq_private.pem",
    target      => "${activemq_confdir}/keystore.jks",
    password    => $keystore_password,
    require     => [
      File["${activemq_confdir}/ssl_credentials/activemq_private.pem"],
      File["${activemq_confdir}/ssl_credentials/activemq_certificate.pem"]
    ],
  }


  # ----- Manage Keystore Files -----

  # Permissions only.
  # No ensure, source, or content.

  file {"${activemq_confdir}/keystore.jks":
    owner   => $activemq_user,
    group   => $activemq_user,
    mode    => '0600',
    require => Java_ks['activemq_cert:keystore'],
  }
  file {"${activemq_confdir}/truststore.jks":
    owner   => $activemq_user,
    group   => $activemq_user,
    mode    => '0600',
    require => Java_ks['activemq_ca:truststore'],
  }

}
