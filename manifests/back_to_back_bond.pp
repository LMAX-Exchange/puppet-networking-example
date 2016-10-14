define networking::back_to_back_bond(
  $slaves,
  $ipaddr,
  $other_ipaddr,
) {
  validate_array($slaves)
  validate_ipv4_address($ipaddr)
  validate_ipv4_address($other_ipaddr)

  $_first_three_octets = regsubst($ipaddr, '^(\d+)\.(\d+)\.(\d+)\.(\d+)$', '\1.\2.\3')
  $_network = "${_first_three_octets}.0"
  $_broadcast = "${_first_three_octets}.255"

  networking::config::interface { $name:
    enable                => true,
    onboot                => 'yes',
    type                  => 'Bonding',
    ipaddr                => $ipaddr,
    testip                => $other_ipaddr,
    netmask               => '255.255.255.0',
    network               => $_network,
    broadcast             => $_broadcast,
    reverse_dns_check     => false,
    monitor_lldp_patching => false,
    bonding_opts          => 'mode=balance-rr miimon=100',
  }
  networking::config::interface { $slaves:
    enable                => true,
    onboot                => 'yes',
    slave                 => 'yes',
    type                  => 'Ethernet',
    master                => $name,
    reverse_dns_check     => false,
    monitor_lldp_patching => false,
  }
}
