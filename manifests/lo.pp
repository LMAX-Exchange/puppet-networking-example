#=Class: networking::network::lo
#
#Make sure a loopback network script always exists. Protects against people messing it up
#with a network_config type, or something deleting it from the file system by hand.
class networking::lo {
  lmax_network_config { 'lo':
    ensure    => present,
    exclusive => false,
    ipaddr    => '127.0.0.1',
    netmask   => '255.0.0.0',
    network   => '127.0.0.0',
    broadcast => '127.255.255.255',
    userctl   => 'no',
    bootproto => 'none',
    onboot    => 'yes',
  }
}
