#=Define: networking::monitoring::interface
define networking::monitoring::interface(
  $type = 'Ethernet',
  $hwaddr = undef,
  $broadcast = undef,
  $cidr = undef,
  $enable = true,
  $extra = undef,
  $ipaddr = undef,
  $mtu = undef,
  $netmask = undef,
  $network = undef,
  $gateway = undef,
  $options = undef,
  $onboot = 'yes',
  $bootproto = 'none',
  $vlan = undef,
  $bridge = undef,
  $master = undef,
  $ethtool_opts = undef,
  $slave = undef,
  $bonding_opts = undef,
  $monitor_lldp_patching = $::networking::monitor_lldp_patching,
  $monitor = $::networking::config::monitor,
  $new_gateway_check = $::networking::new_gateway_check,
  $new_carrier_check = $::networking::new_carrier_check,
  $reverse_dns_check = $::networking::reverse_dns_check,
  $testip = undef,
  $expiring_frame_error_check = $::networking::expiring_frame_error_check,
) {

  if (str2bool($monitor) and str2bool($reverse_dns_check) and ($ipaddr)) {
    nagios::host::service::slow { "check_reverse_dns_${ipaddr}":
      service_description => "Reverse DNS Check ${ipaddr}",
      notes               => 'ReverseDNS',
      check_command       => "check_reverse_dns!${ipaddr}",
      servicegroups       => [ 'networking', 'check_reverse_dns' ],
    }
  }
  if (str2bool($monitor) and str2bool($new_gateway_check)) {
    # we want to use the new check...
    if ($ipaddr != undef) {
      # though it only makes sense to use the check if we have an IP...
      # $i3 = regsubst($ipaddress,'^(\d+)\.(\d+)\.(\d+)\.(\d+)$','\3')
      if ($testip != undef) {
        $testip_actual = $testip
      } else {
        $testip_actual = regsubst($ipaddr,'^(\d+)\.(\d+)\.(\d+)\.(\d+)$','\1.\2.\3.1')
      }
      snmpd::config_line { "check_gateway_${name}":
        line    => "extend check_gateway_${name} /etc/snmp/check_single_gateway.sh ${testip_actual}",
        require => File['/etc/snmp/check_single_gateway.sh'],
      }
      # now actually do the check..
      nagios::host::service::fast { "check_gateway_${name}":
        service_description => "Gateway Check ${title}",
        notes               => 'GatewayCheck',
        check_command       => "snmp_extend!check_gateway_${name}",
        servicegroups       => [ 'networking', 'check_gateway', "check_gateway_${name}" ],
      }
    }
    if ($gateway != undef) {
      # the added bonus here is we'll blow up if we have 2 default gateways... we should never have 2 default gateways
      snmpd::config_line { 'check_gateway_default':
        line    => "extend check_gateway_default /etc/snmp/check_single_gateway.sh ${gateway}",
        require => File['/etc/snmp/check_single_gateway.sh'],
      }
      # now actually do the check..
      nagios::host::service::fast { 'check_gateway_default':
        service_description => 'Gateway Check default',
        notes               => 'GatewayCheck',
        check_command       => 'snmp_extend!check_gateway_default',
        servicegroups       => [ 'networking', 'check_gateway', 'check_gateway_default' ],
      }
    }


  }
  if (str2bool($monitor)) {
    if ($type == 'Ethernet' and $enable and !str2bool($vlan) and $name !~ /.*:.*/) {
      if str2bool($::is_virtual) {
        # notify{"virtual ${name} ${::is_virtual} == true":}
        # What checks do we want to do on a VM?
      } else {

        if (str2bool($expiring_frame_error_check)) {
          snmpd::config_line { "expiring_frame_error_check_${name}":
            line    => "extend expiring_frame_error_check_${name} /usr/local/bin/check_frame_errors_expiring.sh ${name}",
            require => File['/usr/local/bin/check_frame_errors_expiring.sh'],
          }
          # now actually do the check..
          nagios::host::service::fast { "expiring_frame_error_check_${name}":
            service_description => "Expiring Frame Error Check ${title}",
            notes               => 'ExpiringFrameErrorCheck',
            check_command       => "snmp_extend!expiring_frame_error_check_${name}",
            servicegroups       => [ 'networking', 'check_frame_error', "check_frame_error_${name}" ],
          }
        }


        #LB: selectively turn off monitoring some interfaces if they are known to
        #have dodgy LLDP responses, the direct attached networks between Fixprobes
        #for example.
        if ($monitor_lldp_patching) {
          nagios::host::service::end_of_day { "lldp_patching_${name}":
            service_description => "New LLDP Patching ${name}",
            notes               => 'LLDPcheck',
            check_command       => "lldp_patching_new!${name}",
            servicegroups       => [ 'Patching' ],
          }
        }
        if (str2bool($new_carrier_check)) {
          $check_hash_original = {
            "${name}-carrier" => { check => 'carrier' },
            "${name}-duplex" => { check => 'duplex' },
            "${name}-speed" => { check => 'speed' },
          }

          if (str2bool($expiring_frame_error_check)) {
            $check_hash = $check_hash_original
          } else {
            $check_hash = merge( $check_hash_original, { "${name}-crc" => { check => 'crc' }, } )
          }
          $interface_hash = { interface => $name }

          create_resources('networking::monitoring::interface::check', $check_hash, $interface_hash)
        } else {
          nagios::host::service::fast { "network_carrier_${name}":
            service_description => "Carrier Check ${name}",
            notes               => 'Carriercheck',
            check_command       => "network_physical!${name}!carrier",
            servicegroups       => [ 'NetworkPhysical', 'NetworkCarrier' ],
          }
          nagios::host::service::slow { "network_speed_${name}":
            service_description => "Speed Check ${name}",
            notes               => 'Speedcheck',
            check_command       => "network_physical!${name}!speed",
            servicegroups       => [ 'NetworkPhysical', 'NetworkSpeed' ],
          }
          nagios::host::service::slow { "network_duplex_${name}":
            service_description => "Duplex Check ${name}",
            notes               => 'Duplexcheck',
            check_command       => "network_physical!${name}!duplex",
            servicegroups       => [ 'NetworkPhysical', 'NetworkDuplex' ],
          }
          #LB: this check is fundamentally wrong: you can't use Nagios to monitor
          #a counter, you need to graph a counter.
          # heathn: Yes, but we can alert if the errors get too high (ie >20 , not >0)
          nagios::host::service::slow { "network_frame_${name}":
            service_description => "CRC Frame Error Check ${name}",
            notes               => 'FrameErrorcheck',
            check_command       => "network_physical!${name}!frame",
            servicegroups       => [ 'NetworkPhysical', 'NetworkFrame' ],
          }
        }
      }
    }
  }
}
