define networking::simple_bond(
  $slaves,
  $ipaddr       = undef,
  $bonding_type = 'active-backup',
  $is_gateway   = false,
  $gateway      = undef,
  $vlan_tagged  = false,
) {
  include ::networking

  validate_array($slaves)
  #LB: $ipaddr is allowed to be undef only when $vlan_tagged is true
  if (!$vlan_tagged) {
    validate_ipv4_address($ipaddr)
  }
  validate_bool($is_gateway)
  if ! ($bonding_type in [ 'lacp', 'active-backup', ]) {
    fail("Parameter 'bonding_type' must be one of 'lacp' or 'active-backup'")
  }
  $bonding_opts = $bonding_type ? {
    'lacp'  => $::networking::lacp_bonding_options,
    default => $::networking::active_passive_bonding_options,
  }

  #LB: if $ipaddr is set, put all the IP information on the bond interface.
  if ($ipaddr) {
    $_first_three_octets = regsubst($ipaddr, '^(\d+)\.(\d+)\.(\d+)\.(\d+)$', '\1.\2.\3')
    $_network = "${_first_three_octets}.0"
    $_broadcast = "${_first_three_octets}.255"
    if ($is_gateway) {
      if ($gateway == undef) {
        $_gateway = "${_first_three_octets}.1"
      } else {
        $_gateway = $gateway
      }
      validate_ipv4_address($_gateway)
    } else {
      $_gateway = undef
    }

    networking::config::interface { $name:
      enable       => true,
      onboot       => 'yes',
      type         => 'Bonding',
      ipaddr       => $ipaddr,
      netmask      => '255.255.255.0',
      network      => $_network,
      broadcast    => $_broadcast,
      gateway      => $_gateway,
      testip       => $_gateway,
      bonding_opts => $bonding_opts,
    }
  } else {
    networking::config::interface { $name:
      enable       => true,
      onboot       => 'yes',
      type         => 'Bonding',
      bonding_opts => $bonding_opts,
    }
  }

  networking::config::interface { $slaves:
    enable => true,
    onboot => 'yes',
    slave  => 'yes',
    type   => 'Ethernet',
    master => $name,
  }
}
