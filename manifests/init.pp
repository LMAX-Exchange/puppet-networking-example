#=Class: networking
class networking (
  $interfaces                        = undef,
  $udev_static_interface_names       = false,
  $extra_udev_static_interface_names = undef,
  $routes                            = undef,
  $rules                             = undef,
  $monitor                           = false,
  $new_gateway_check                 = false,
  $new_carrier_check                 = false,
  $reverse_dns_check                 = false,
  $monitor_lldp_patching             = true,
  $tune_tso_gso_off_on_tg3           = false,
  $tune_tso_gso_off_on_virtio_net    = false,
  $tune_ringbuffer_to_max            = false,
  $expiring_frame_error_check        = false,
  $active_passive_bonding_options    = 'mode=active-backup miimon=100',
  $lacp_bonding_options              = 'mode=802.3ad xmit_hash_policy=layer3+4 lacp_rate=slow miimon=100',
  $subnet_site                       = '192.168',
  $vlan_web                          = '2',
  $vlan_application                  = '3',
  $vlan_database                     = '4',
  $vlan_payments                     = '5',
  $vlan_stock                        = '6',
  $subnet_web                        = undef,
  $subnet_application                = undef,
  $subnet_database                   = undef,
  $subnet_payments                   = undef,
  $subnet_stock                      = undef,
  $subnet_web_bond                   = undef,
  $subnet_application_bond           = undef,
  $subnet_database_bond              = undef,
  $subnet_payments_bond              = undef,
  $subnet_stock_bond                 = undef,
) {
  #internal variables $_subnet_* default to the concatenation of $subnet_site and the corresponding VLAN number
  #if no class parameter override is specified.
  $_subnet_web         = pick($subnet_web, "${subnet_site}.${vlan_web}")
  $_subnet_application = pick($subnet_application, "${subnet_site}.${vlan_application}")
  $_subnet_database    = pick($subnet_database, "${subnet_site}.${vlan_database}")
  $_subnet_payments    = pick($subnet_payments, "${subnet_site}.${vlan_payments}")
  $_subnet_stock       = pick($subnet_stock, "${subnet_site}.${vlan_stock}")

  #internal variable $_subnet_*_bond follows the number of the corresponding VLAN tag, unless
  #a class parameter overrides it
  $_subnet_web_bond         = pick($subnet_web_bond, "bond${vlan_web}")
  $_subnet_application_bond = pick($subnet_application_bond, "bond${vlan_application}")
  $_subnet_database_bond    = pick($subnet_database_bond, "bond${vlan_database}")
  $_subnet_payments_bond    = pick($subnet_payments_bond, "bond${vlan_payments}")
  $_subnet_stock_bond       = pick($subnet_stock_bond, "bond${vlan_stock}")

  if ($subnet_site == undef) { fail('Parameter subnet_site cannot be undef') }
  validate_string($subnet_site)
  if ($active_passive_bonding_options == undef) { fail('Parameter active_passive_bonding_options cannot be undef') }
  validate_string($active_passive_bonding_options)
  if ($lacp_bonding_options == undef) { fail('Parameter lacp_bonding_options cannot be undef') }
  validate_string($lacp_bonding_options)
  if ($vlan_web == undef) { fail('Parameter vlan_web cannot be undef') }
  validate_string($vlan_web)
  if ($vlan_application == undef) { fail('Parameter vlan_application cannot be undef') }
  validate_string($vlan_application)
  if ($vlan_database == undef) { fail('Parameter vlan_database cannot be undef') }
  validate_string($vlan_database)
  if ($vlan_payments == undef) { fail('Parameter vlan_payments cannot be undef') }
  validate_string($vlan_payments)
  if ($vlan_stock == undef) { fail('Parameter vlan_stock cannot be undef') }
  validate_string($vlan_stock)

  $managed_interfaces_file = '/etc/snmp/managed_interfaces.txt'
  concat { $managed_interfaces_file:
    owner => 'root',
    group => 'root',
    mode  => '0644',
    tag   => 'snmp',
  }
  concat::fragment { 'managed_interfaces_header':
    target  => $managed_interfaces_file,
    order   => '01',
    content => "#Managed by Puppet\n#This file contains a list of all managed network interfaces.\n",
    tag     => 'snmpd',
  }

  include ::networking::config
  if ($monitor) {
    include ::networking::monitoring
  }
}
