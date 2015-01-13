# Runs oo-admin-yum-validator ensuring OSE repos have higher priorities and
# a few key package exclusions in order to assist in ensuring a supportable
# install
#
# oo-admin-yum-validator has the following roles node, broker, client, node-eap,
# node-fuse, node-amq which we have to translate puppet's concept of roles into,
# broker is trivial, node roles get dicey because we have to examine the
# cartridges being installed and add aditional oo-admin-yum-validator roles
# based on those
class openshift_origin::oo_admin_yum_validator {
  if $::openshift_origin::ose_version {
    package{ 'openshift-enterprise-yum-validator': }

    $carts = $::openshift_origin::cartridges_to_install
    $roles = $::openshift_origin::roles
    if member($carts, 'amq') and member($roles, 'node') { $role_amq = 'node-amq' } else { $role_amq = '' }
    if member($carts, 'jbosseap') and member($roles, 'node') { $role_eap = 'node-eap' } else { $role_eap = '' }
    if member($carts, 'fuse') and member($roles, 'node') { $role_fuse = 'node-fuse' } else { $role_fuse = '' }
    if member($roles, 'node') { $role_node = 'node' } else { $role_node = '' }
    if member($roles, 'broker') { $role_broker = 'broker -r client' } else { $role_broker = '' }
    $role_list = [$role_node, $role_amq, $role_eap, $role_fuse, $role_broker]
    $role_string = join( prefix( delete( $role_list, '' ), ' -r ' ), '' )

    # oo-admin-yum-validator -a returns 1 if it made changes and 0 if no changes
    # so use a wrapper to fix everything then call it again to check for issues
    file { '/usr/local/bin/puppet-oo-admin-yum-validator':
      mode    => '0755',
      content => template('openshift_origin/puppet-oo-admin-yum-validator.erb'),
      notify  => Exec['Yum validator fix-all'],
    }
    # refresh only so we only run this when roles change
    exec { 'Yum validator fix-all':
      command     => '/usr/local/bin/puppet-oo-admin-yum-validator',
      require     => [  Package['openshift-enterprise-yum-validator'],
                        File['/usr/local/bin/puppet-oo-admin-yum-validator'], ],
      refreshonly => true,
    }
  }
}
