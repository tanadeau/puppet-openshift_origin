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
class openshift_origin::firewall::activemq {

  if $::openshift_origin::manage_firewall {
    require openshift_origin::firewall

    if $::openshift_origin::msgserver_tls_enabled == 'strict' {
      $activemq_port = '61614'
      $activemq_openwire_port = '61617'
    } elsif $::openshift_origin::msgserver_tls_enabled == 'enabled' {
      $activemq_port = '61613-61614'
      $activemq_openwire_port = '61616-61617'
    } else {
      $activemq_port = '61613'
      $activemq_openwire_port = '61616'
    }
    
    lokkit::ports { 'ActiveMQ':
      tcpPorts => [ $activemq_port ],
    }

    if $::openshift_origin::msgserver_cluster {
      lokkit::ports { 'ActiveMQ-Openwire':
        tcpPorts => [ $activemq_openwire_port ],
      }
    }
  }
}
