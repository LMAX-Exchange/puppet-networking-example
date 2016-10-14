define networking::passive_listen_bond(
  $slaves,
) {
  validate_array($slaves)

  networking::config::interface { $name:
    enable                => true,
    onboot                => 'yes',
    type                  => 'Bonding',
    ipaddr                => undef,
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
