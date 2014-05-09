# Introduction
# Class used to load-balance brokers in a
# high-availability OpenShift deployment.
#
# Module Dependencies
#  duritong/sysctl
#  arioch/keepalived
#  puppetlabs/haproxy
#
# Example Usage
# class { 'openshift_origin' :
#   broker_cluster_members      => ['broker01.example.com','broker02.example.com','broker03.example.com'],
#   broker_cluster_ip_addresses => ['10.10.10.11','10.10.10.12','10.10.10.13'],
#   broker_virtual_ip_address   => '10.10.10.10',
#   broker_virtual_hostname     => 'broker.example.com',
#   load_balancer_master        => true,
# }
#
class openshift_origin::load_balancer(
  $enable               = true,
  $manage_service       = true,
  $state_master         = $::openshift_origin::load_balancer_master,
  $virtual_ipaddress    = $::openshift_origin::broker_virtual_ip_address,
  $server_names         = $::openshift_origin::broker_cluster_members,
  $ipaddresses          = $::openshift_origin::broker_cluster_ip_addresses,
  $interface            = $::openshift_origin::conf_node_external_eth_dev,
  $http_port            = '80',
  $ssl_port             = '443',
  $virtual_router_id    = '50',
  $auth_pass            = $::openshift_origin::load_balancer_auth_password,

) {

  include keepalived

  if 'broker' and 'load_balancer' in $::openshift_origin::roles {
    Class[openshift_origin::plugins::frontend::apache] -> Class['haproxy']
  }

  if ($state_master == true) {
    $priority = '101'
  } else {
    $priority = '100'
  }

  # Required by sysctl module
  Exec { path => '/usr/bin:/usr/sbin:/bin:/sbin' }

  sysctl::value { 'net.ipv4.ip_nonlocal_bind': 
    value => '1',
  }

  keepalived::vrrp::instance { $virtual_router_id:
    interface         => $interface,
    priority          => $priority,
    state             => $state_master,
    virtual_ipaddress => [$virtual_ipaddress],
    virtual_router_id => $virtual_router_id,
    auth_type         => 'PASS',
    auth_pass         => $auth_pass,
    track_script      => ['haproxy'],
  }

  keepalived::vrrp::script { 'haproxy':
    script => '/usr/bin/killall -0 haproxy',
  }

  class { 'haproxy':
    manage_service   => $manage_service,
    enable           => $enable,
    defaults_options => {
                         'log'     => 'global',
                         'option'  => 'redispatch',
                         'retries' => '3',
                         'timeout' => [
                                       'http-request 10s',
                                       'queue 1m',
                                       'connect 10s',
                                       'client 1m',
                                       'server 1m',
                                       'check 10s',
                                      ],
                         'maxconn' => '8000',
                        }
  }

  haproxy::listen { 'broker_http_cluster':
    ipaddress => $virtual_ipaddress,
    ports     => $http_port,
    options   => {
                  'option'  => ['tcpka', 'tcplog'],
                  'mode'    => 'tcp',
                  'balance' => 'source',
                 },
  }

  haproxy::balancermember { 'http_brokers':
    listening_service => 'broker_http_cluster',
    server_names      => $server_names,
    ipaddresses       => $ipaddresses,
    ports             => $http_port,
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'broker_ssl_cluster':
    ipaddress => $virtual_ipaddress,
    ports     => $ssl_port,
    options   => {
                  'option'  => ['tcpka', 'tcplog'],
                  'mode'    => 'tcp',
                  'balance' => 'source',
                 },
  }

  haproxy::balancermember { 'ssl_brokers':
    listening_service => 'broker_ssl_cluster',
    server_names      => $server_names,
    ipaddresses       => $ipaddresses,
    ports             => $ssl_port,
    options           => 'check inter 2000 rise 2 fall 5',
  }
}
