#=Class: networking::monitoring
#
#Common monitoring for the networking module.
class networking::monitoring (
  $interfaces                  = $::networking::interfaces,
  $new_gateway_check           = $::networking::new_gateway_check,
  $new_carrier_check           = $::networking::new_carrier_check,
  $expiring_frame_error_check  = $::networking::expiring_frame_error_check,
) {
  include ::snmpd

  if (is_hash($interfaces)) {
    $interface_list = join(sort(join_keys_with_filter($interfaces, 'enable')), ',')
  } else {
    $interface_list = ''
  }

  nagios::host::service::out_of_hours { 'network_unmanaged':
    service_description => 'Unmanaged Interfaces',
    notes               => 'UnmanagedInterfaces',
    check_command       => "network_unmanaged!${$interface_list}",
    servicegroups       => [ 'NetworkPhysical', 'NetworkUnmanaged' ],
  }

  $lldp_script = '/etc/snmp/interfaces.py'
  file { $lldp_script:
    ensure => present,
    mode   => '0755',
    source => "puppet:///modules/${module_name}/${lldp_script}",
    tag    => 'snmpd',
  }
  snmpd::config_line { 'interfaces':
    line    => "extend interfaces ${lldp_script}",
    require => File[$lldp_script],
  }

  if (str2bool($new_gateway_check)) {
    $check_single_gateway_script = '/etc/snmp/check_single_gateway.sh'
    file { $check_single_gateway_script:
      source  => "puppet:///modules/${module_name}/${check_single_gateway_script}",
      mode    => '0755',
      require => Class['snmpd'],
    }
  } else {
    nagios::host::service::fast { 'check_gateways':
      service_description => 'Gateway status',
      servicegroups       => 'Gateway Status',
      notes               => 'GatewayStatus',
      check_command       => 'snmp_extend!gateway_check',
    }
  }

  if (str2bool($new_carrier_check)) {
    $check_carrier_script = '/usr/local/bin/check_carrier.sh'
    file { $check_carrier_script:
      source => "puppet:///modules/${module_name}/${check_carrier_script}",
      mode   => '0755',
    }
  }
  if (str2bool($expiring_frame_error_check)) {
    $expiring_frame_error_check_script = '/usr/local/bin/check_frame_errors_expiring.sh'
    file { $expiring_frame_error_check_script:
      source => "puppet:///modules/${module_name}/${expiring_frame_error_check_script}",
      mode   => '0755',
    }
  }
}
