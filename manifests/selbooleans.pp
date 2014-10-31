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
# == Class openshift_origin::selbooleans
# These SELinux booleans must be set on any OpenShift Broker, console or Node host.
#
class openshift_origin::selbooleans {
  selboolean {
    [
      'httpd_unified',
      'httpd_can_network_connect',
      'httpd_can_network_relay',
      'httpd_run_stickshift',
      'httpd_read_user_content',
      'httpd_enable_homedirs',
    ]:
    value      => 'on',
    persistent => true,
  }
}
