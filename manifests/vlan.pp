define networking::vlan(
  $ipaddr,
  $is_gateway   = false,
  $gateway      = undef,
) {
  include ::networking

  #LB: there are some situations where we might want a vlan tagged interface
  #without an IP
  if ($ipaddr != undef) {
    validate_ipv4_address($ipaddr)
    validate_bool($is_gateway)
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
  }

  networking::config::interface { $name:
    enable    => true,
    onboot    => 'yes',
    vlan      => 'yes',
    type      => 'Ethernet',
    ipaddr    => $ipaddr,
    netmask   => '255.255.255.0',
    network   => $_network,
    broadcast => $_broadcast,
    gateway   => $_gateway,
  }
}
