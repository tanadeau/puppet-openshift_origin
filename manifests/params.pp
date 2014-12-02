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
  $ruby_scl_prefix = $::operatingsystem ? {
    default  => 'ruby193-',
  }

  $ruby_scl_path_prefix = $::operatingsystem ? {
    default  => '/opt/rh/ruby193/root',
  }

  $node_shmmax = $::architecture ? {
    'x86_64' => 68719476736,
    default  => 33554432,
  }

  $node_shmall = $::architecture ? {
    'x86_64' => 4294967296,
    default  => 2097152,
  }

  $repos_base = $::operatingsystem ? {
    default  => 'https://mirror.openshift.com/pub/origin-server/nightly/rhel-6',
  }

}
