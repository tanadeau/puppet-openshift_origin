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
class openshift_origin::yum_install_method {
  package { 'yum-plugin-priorities':
    ensure => present,
  }

  if $::openshift_origin::os_repo != undef {
    yumrepo { 'openshift-os-base':
      baseurl    => $::openshift_origin::os_repo,
      priority   => 1,
      gpgcheck   => 0,
      mirrorlist => absent,
      require    => Package['yum-plugin-priorities'],
    }
  }
  if $::openshift_origin::os_updates_repo != undef {
    yumrepo { 'openshift-os-updates':
      baseurl    => $::openshift_origin::os_updates_repo,
      priority   => 1,
      gpgcheck   => 0,
      mirrorlist => absent,
      require    => Package['yum-plugin-priorities'],
    }
  }
  if $::openshift_origin::repos_base =~ /nightly/ {
    if $::openshift_origin::architecture == undef {
      $repo_path = "${::openshift_origin::repos_base}/packages/latest/${::architecture}"
      $deps_path = "${::openshift_origin::repos_base}/dependencies/${::architecture}"
    } else {
      $repo_path = "${::openshift_origin::repos_base}/packages/latest/${::openshift_origin::architecture}"
      $deps_path = "${::openshift_origin::repos_base}/dependencies/${::openshift_origin::architecture}"
    }
    if $::operatingsystem == 'Fedora' {
      augeas { 'priorities.conf':
        context => '/files/etc/yum/pluginconf.d/priorities.conf',
        lens    => 'Yum.lns',
        incl    => '/etc/yum/pluginconf.d/priorities.conf',
        changes => 'set main/enabled 1',
      }
    }
  } else {
    if $::openshift_origin::architecture == undef {
      if $::architecture =~ /arm/ {
          $repo_path = "${::openshift_origin::repos_base}/packages/armhfp"
          $deps_path = "${::openshift_origin::repos_base}/dependencies/armhfp"
      } else {
          $repo_path = "${::openshift_origin::repos_base}/packages/${::architecture}"
          $deps_path = "${::openshift_origin::repos_base}/dependencies/${::architecture}"
      }
    } else {
      $repo_path = "${::openshift_origin::repos_base}/packages/${::openshift_origin::architecture}"
      $deps_path = "${::openshift_origin::repos_base}/dependencies/${::openshift_origin::architecture}"
    }
  }

  if $::openshift_origin::override_install_repo != undef {
    $repo_path_1 = $::openshift_origin::override_install_repo
  } else {
    $repo_path_1 = $repo_path
  }

  yumrepo { 'openshift-origin':
    baseurl    => $repo_path_1,
    priority   => 1,
    gpgcheck   => 0,
    mirrorlist => absent,
    require    => Package['yum-plugin-priorities'],
  }

  yumrepo { 'openshift-deps':
    baseurl    => $deps_path,
    priority   => 1,
    gpgcheck   => 0,
    mirrorlist => absent,
    require    => Package['yum-plugin-priorities'],
  }

  if $::openshift_origin::jenkins_repo_base != undef {
    yumrepo { 'jenkins-repo':
      baseurl  => $::openshift_origin::jenkins_repo_base,
      gpgcheck => 0,
      require  => Package['yum-plugin-priorities'],
    }
  }

  if $::openshift_origin::jboss_repo_base != undef {
    yumrepo { 'jboss-repo':
      baseurl  => $::openshift_origin::jboss_repo_base,
      gpgcheck => 0,
      require  => Package['yum-plugin-priorities'],
    }
  }

  if $::openshift_origin::optional_repo != undef {
    yumrepo { 'openshift-optional':
      baseurl  => $::openshift_origin::optional_repo,
      priority => 1,
      gpgcheck => 0,
      require  => Package['yum-plugin-priorities'],
    }
  }
}
