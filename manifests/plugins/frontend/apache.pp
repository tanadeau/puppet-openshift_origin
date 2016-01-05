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
class openshift_origin::plugins::frontend::apache {
  include openshift_origin::httpd_certificate

  anchor { 'openshift_origin::plugins::fronted::apache_begin': } ->
  Package['httpd'] ->
  Class['openshift_origin::httpd_certificate'] ->
  anchor { 'openshift_origin::plugins::fronted::apache_end': }

  package { 'httpd':
    require => Class['openshift_origin::install_method'],
  }

  if 'broker' in $::openshift_origin::roles {
    file { 'broker proxy config':
      ensure  => present,
      path    => '/etc/httpd/conf.d/000002_openshift_origin_broker_proxy.conf',
      content => template('openshift_origin/plugins/frontend/apache/broker_proxy.conf.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => Package['httpd'],
      notify  => Service['httpd'],
    }

    $httpd_servername_path    = '/etc/httpd/conf.d/000002_openshift_origin_broker_servername.conf'
    $servername_conf_template = 'openshift_origin/plugins/frontend/apache/broker_servername.conf.erb'

  } elsif 'node' in $::openshift_origin::roles {
    $httpd_servername_path    = '/etc/httpd/conf.d/000001_openshift_origin_node_servername.conf'
    $servername_conf_template = 'openshift_origin/plugins/frontend/apache/node_servername.conf.erb'
  }

  if ('broker' and 'load_balancer' in $::openshift_origin::roles) or $::openshift_origin::broker_ip_addr != $::ipaddress {
    exec { 'httpd_conf':
      path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
      command => "sed -ri \'s/Listen 80/Listen ${openshift_origin::broker_ip_addr}:80/\' /etc/httpd/conf/httpd.conf",
      unless  => "grep \"Listen ${openshift_origin::broker_ip_addr}:80\" /etc/httpd/conf/httpd.conf",
      require => Package['httpd'],
      notify  => Service['httpd'],
    }
    exec { 'ssl_conf':
      path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'],
      command => "sed -ri \'s/Listen 443/Listen ${openshift_origin::broker_ip_addr}:443/\' /etc/httpd/conf.d/ssl.conf",
      unless  => "grep \"Listen ${openshift_origin::broker_ip_addr}:443\" /etc/httpd/conf.d/ssl.conf",
      require => Package['httpd'],
      notify  => Service['httpd'],
    }
  }

  service { 'httpd':
    ensure     => true,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    =>  Package['httpd'],
  }

  file { 'servername config':
    ensure  => present,
    path    => $httpd_servername_path,
    content => template($servername_conf_template),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['httpd'],
    notify  => Service['httpd'],
  }
}
