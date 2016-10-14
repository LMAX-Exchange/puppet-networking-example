#=Define: network::dummy
#
#This define installs a generic dummy network interface and makes sure it is always up and running.
#It should be replaced with the network_config user defined type instead of using a template, but
#it works for now and it even ensures the interface is 'up', which the network_config type does not (yet).
#
#=Parameters
#name:: The name of the dummy interface, usually 'dummyX'.
#ipaddr:: The IP address of the dummy interface (eg: 172.29.1.1).
#netmask:: The netmask of the dummy interface (eg: 255.255.255.0).
#cidr:: The cidr of the netmask, so /24 or /32.
#network:: The network of the dummy interface (eg: 172.29.1.0).
#broadcast:: The broadcast address of the dummy interface (eg: Bcast:172.29.1.255).
#multicast:: Whether the dummy interface supports multicast, valid values are 'true' or 'false', defaults to 'false'.
define networking::dummy(
  $ipaddr,
  $cidr,
  $netmask,
  $network,
  $broadcast,
  $nm_controlled = '',
  $multicast = false
) {
  #Set up some variables
  $dummy_module = 'dummy'
  $modprobe_dir = '/etc/modprobe.d'
  $network_scripts_dir = '/etc/sysconfig/network-scripts'
  $dummy_network_ifcfg_file = "${network_scripts_dir}/ifcfg-${name}"
  $dummy_modprobe_file = "${modprobe_dir}/${dummy_module}-${name}.conf"
  $multicast_cmd="/sbin/ip link set ${name} multicast on"

  #Push out a network config file for a dummy network interface
  file { $dummy_network_ifcfg_file:
    ensure  => present,
    content => template("${module_name}/ifcfg.erb"),
  }

  #Push out a modprobe configuration file to alias the dummy network driver to this dummy
  #device.
  file { $dummy_modprobe_file:
    ensure  => present,
    content => "alias ${name} ${dummy_module}\n",
    notify  => Exec["modprobe ${name}"],
  }

  #We've aliases this dummy device to the dummy kernel driver, need to modprobe it to make
  #sure the alias is picked up and the device created. Since the device might exist before
  #hand, lets remove and it and re-add it if we can.
  exec { "modprobe ${name}":
    command     => "/sbin/modprobe -r ${name} && /sbin/modprobe ${name}",
    refreshonly => true,
  }

  #Add the IP address and broadcast address to the dummy interface.
  exec { "add ${name}":
    command => "/sbin/ip addr add ${ipaddr}/${cidr} broadcast ${broadcast} dev ${name}",
    require => Exec["modprobe ${name}"],
    unless  => "/sbin/ip addr show ${name} | grep -w ${ipaddr}",
  }

  #Up the dummy interface and set multicast value. The 'unless' condition changes
  #if multicast is set on or not, hence the use of the selectors.
  $cmd = $multicast ? {
    true    => "/sbin/ip link set ${name} multicast on up",
    default => "/sbin/ip link set ${name} multicast off up",
  }
  $unless = $multicast ? {
    true    => "/sbin/ip link show ${name} | grep -w MULTICAST | grep -w UP",
    default => "/sbin/ip link show ${name} | grep -w UP",
  }
  exec { "up ${name}":
    command => $cmd,
    require => Exec["add ${name}"],
    unless  => $unless,
  }

  if ($::operatingsystem == 'Fedora') {
    # If using fedora we should bring up the dummy interface on boot
    $dummy_net_systemd_target = '/etc/systemd/system/dummy-net.service'
    file { $dummy_net_systemd_target:
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => "puppet:///modules/${module_name}/dummy-net.service",
    }

    service { 'dummy-net':
      enable  => true,
      require => File[$dummy_net_systemd_target],
    }
  }
}
