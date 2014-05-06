require 'spec_helper'

describe 'openshift_origin' do
  let :facts do {
    :osfamily => 'RedHat',
  } end

  describe 'with minimal parameters' do
    let :params do {
      :bind_key => 'something',
    } end

    it { should compile.with_all_deps }
  end

  describe 'broker example' do
    let :params do {
      # Components to install on this host:
      :roles => ['broker','nameserver','msgserver','datastore'],

      # BIND / named config
      # This is the key for updating the OpenShift BIND server
      :bind_key                       => 'something',
      # The domain under which applications should be created.
      :domain                         => 'example.com',
      # Apps would be named <app>-<namespace>.example.com
      # This also creates hostnames for local components under our domain
      :register_host_with_nameserver  => true,
      # Forward requests for other domains (to Google by default)
      :conf_nameserver_upstream_dns   => ['8.8.8.8', '8.8.4.4'],

      # NTP Servers for OpenShift hosts to sync time
      :ntp_servers => ['ntp.example.com iburst'],

      # The FQDNs of the OpenShift component hosts
      :broker_hostname     => 'broker.example.com',
      :nameserver_hostname => 'broker.example.com',
      :datastore_hostname  => 'broker.example.com',
      :msgserver_hostname  => 'broker.example.com',

      # Auth OpenShift users created with htpasswd tool in /etc/openshift/htpasswd
      :broker_auth_plugin         => 'htpasswd',
      # Username and password for initial openshift user
      :openshift_user1            => 'openshift',
      :openshift_password1        => 'password',

      #Enable development mode for more verbose logs
      :development_mode           => true,
    } end

    it { should compile.with_all_deps }
  end

  describe 'node example' do
    let :params do {
      # Components to install on this host:
      :roles => ['node'],

      # BIND / named config
      # This is the key for updating the OpenShift BIND server
      :bind_key                       => 'something',
      # The domain under which applications should be created.
      :domain                         => 'example.com',
      # Apps would be named <app>-<namespace>.example.com
      # This also creates hostnames for local components under our domain
      :register_host_with_nameserver  => true,
      # Forward requests for other domains (to Google by default)
      :conf_nameserver_upstream_dns   => ['8.8.8.8', '8.8.4.4'],

      # NTP Servers for OpenShift hosts to sync time
      :ntp_servers => ['ntp.example.com iburst'],

      # The FQDNs of the OpenShift component hosts
      :broker_hostname     => 'broker.example.com',
      :msgserver_hostname  => 'broker.example.com',
      :node_hostname       => 'node.example.com',

      # To enable installing the Jenkins cartridge:
      :install_method    => 'yum',
      :jenkins_repo_base => 'http://pkg.jenkins-ci.org/redhat',

      # Cartridges to install on Node hosts
      :install_cartridges         => ['php', 'mysql'],

      #Enable development mode for more verbose logs
      :development_mode           => true,
    } end

    it { should compile.with_all_deps }
  end
end
