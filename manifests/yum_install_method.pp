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
  if ( $::openshift_origin::os_repo != undef ) {
    case $::operatingsystem {
      'Fedora' : {
        augeas { 'Custom OS repository':
          context => "/files/etc/yum.repos.d/fedora.repo",
          changes => [
            "set fedora/baseurl ${::openshift_origin::os_repo}",
            "set fedora/gpgcheck 0",
            "rm  fedora/mirrorlist",
          ],
        }
      }
      'CentOS' : {
        augeas { 'Custom OS repository':
          context => "/files/etc/yum.repos.d/CentOS-Base.repo",
          changes => [
            "set base/baseurl ${::openshift_origin::os_repo}",
            "set base/gpgcheck 0",
            "rm  base/mirrorlist",
          ],
        }
      }
      default  : {
        augeas { 'Custom OS repository':
          context => "/files/etc/yum.repos.d/RHEL-Base.repo",
          changes => [
            "set base/baseurl ${::openshift_origin::os_repo}",
            "set base/gpgcheck 0",
            "rm  base/mirrorlist",
          ],
        }
      }
    }
  }
  
  if ( $::openshift_origin::os_updates_repo != undef ) {
    case $::operatingsystem {
      'Fedora' : {
        augeas { 'Custom OS Update repository':
          context => "/files/etc/yum.repos.d/fedora-updates.repo",
          changes => [
            "set updates/baseurl ${::openshift_origin::os_updates_repo}",
            "set updates/gpgcheck 0",
            "rm  updates/mirrorlist",
          ],
        }
      }
      'CentOS' : {
        augeas { 'Custom OS Update repository':
          context => "/files/etc/yum.repos.d/CentOS-Base.repo",
          changes => [
            "set updates/baseurl ${::openshift_origin::os_updates_repo}",
            "set updates/gpgcheck 0",            
            "rm  updates/mirrorlist",
          ],
        }
      }
      default  : {
        augeas { 'Custom OS Update repository':
          context => "/files/etc/yum.repos.d/RHEL-Base.repo",
          changes => [
            "set updates/baseurl ${::openshift_origin::os_updates_repo}",
            "set updates/gpgcheck 0",          
            "rm  updates/mirrorlist",
          ],
        }
      }
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
      package { 'yum-plugin-priorities':
        ensure  => present,
      }
      augeas { 'priorities.conf':
        context => "/files/etc/yum/pluginconf.d/priorities.conf",
        changes => "set main/enabled 1",
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

  augeas { 'OpenShift Repository':
    context => "/files/etc/yum.repos.d/openshift.repo",
    changes => [
      "set origin-base/id origin-base",
      "set origin-base/baseurl ${repo_path_1}",
      "set origin-base/gpgcheck 0",
      "set origin-base/enabled 1",
      "set origin-base/priority 1",
      "set origin-deps/id origin-deps",
      "set origin-deps/baseurl ${deps_path}",
      "set origin-deps/gpgcheck 0",
      "set origin-deps/enabled 1",
      "set origin-deps/priority 1",
    ]
  }
  
  if ( $::openshift_origin::jenkins_repo_base != undef ) {
    augeas { 'Jenkins repository':
      context => "/files/etc/yum.repos.d/jenkins_repo.repo",
      changes => [
        "set jenkins_repo/id jenkins-repo",
        "set jenkins_repo/baseurl ${::openshift_origin::jenkins_repo_base}",
        "set jenkins_repo/gpgcheck 0",
      ],
    }
  }

  if ( $::openshift_origin::jboss_repo_base != undef ) {
    augeas { 'JBoss Repository':
      context => "/files/etc/yum.repos.d/jboss_repo.repo",
      changes => [
        "set jboss_repo/id jboss-repo",
        "set jboss_repo/baseurl ${::openshift_origin::jboss_repo_base}",
        "set jboss_repo/gpgcheck 0",
      ],
    }
  }

  if ( $::openshift_origin::optional_repo != undef ) {
    augeas { 'Optional Repository':
      context => "/files/etc/yum.repos.d/optional.repo",
      changes => [
        "set optional_repo/id optional",
        "set optional_repo/baseurl ${::openshift_origin::optional_repo}",
        "set optional_repo/gpgcheck 0",
      ],
    }
  }
}
