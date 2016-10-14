#=Define: networking::config::interface
#
#The networking::interface definition handles creating network configuration scripts for
#Red Hat / Fedora flavoured systems.
#
#This user defined type is a mainly a wrapper around the Puppet-Network module, but it supports
#extra options that the network_config custom type does not. It will also be a wrapper for better
#error handling, as create_resources is not the most user-friendly Puppet function.
define networking::config::interface(
  $type                           = 'Ethernet',
  $hwaddr                         = undef,
  $broadcast                      = undef,
  $cidr                           = undef,
  $enable                         = true,
  $extra                          = undef,
  $ipaddr                         = undef,
  $mtu                            = undef,
  $netmask                        = undef,
  $network                        = undef,
  $gateway                        = undef,
  $options                        = undef,
  $onboot                         = 'yes',
  $bootproto                      = 'none',
  $vlan                           = undef,
  $bridge                         = undef,
  $master                         = undef,
  $ethtool_opts                   = '',
  $slave                          = undef,
  $bonding_opts                   = undef,
  $monitor_lldp_patching          = $::networking::monitor_lldp_patching,
  $monitor                        = $::networking::config::monitor,
  $testip                         = undef,
  $reverse_dns_check              = undef,
  $tune_tso_gso_off_on_tg3        = $::networking::tune_tso_gso_off_on_tg3,
  $tune_tso_gso_off_on_virtio_net = $::networking::tune_tso_gso_off_on_virtio_net,
  $tune_ringbuffer_to_max         = $::networking::tune_ringbuffer_to_max,
  $new_gateway_check              = $::networking::new_gateway_check,
  $new_carrier_check              = $::networking::new_carrier_check,
  $reverse_dns_check              = $::networking::reverse_dns_check,
) {
  include ::networking

  $interface_name = $name
  # If you're specifying a bonding interface you have to specify bonding_opts,
  # or the machine won't create the interface. We silently go "ok", so lets
  # stop doing that.
  $lower_type = downcase($type)
  if ($lower_type == 'bonding' and $bonding_opts == undef) {
    fail("Your network configuration for ${title} is invalid. You've specified type => ${type} but bonding_opts is undefined. Your server will not bring up this interface with this config.")
  }

  if ($interface_name == undef) {
    fail('Networking interface name cannot be undef')
  }
  #LB: add a concat fragment to indicate this network interface is managed
  concat::fragment { "managed_interface_${interface_name}":
    target  => $::networking::managed_interfaces_file,
    content => "${interface_name}\n",
    order   => '10',
  tag       => 'snmpd',
  }

  #LB: automatically turn off tcp-segmentation-offload and generic-segmentation-offload
  #on Broadcom / TG3 interfaces. This was the cause of problems between Cisco ASAs.
  $tg3_interfaces = split($::nic_driver_tg3, ',')
  $virtio_net_interfaces = split($::nic_driver_virtio_net, ',')
  if (($tune_tso_gso_off_on_tg3) and ($interface_name in $tg3_interfaces))
  or (($tune_tso_gso_off_on_virtio_net) and ($interface_name in $virtio_net_interfaces)) {
    #turn off tso and gso immediately with an Exec
    exec { "disable tso and gso on ${interface_name}":
      command => "/sbin/ethtool -K ${interface_name} tso off gso off",
      onlyif  => "/sbin/ethtool -k ${interface_name} | grep segmentation-offload | grep -q ': on'",
    }
    $tso_ethtool_opts = "-K ${interface_name} tso off gso off"
  } elsif ((!$tune_tso_gso_off_on_tg3) and ($interface_name in $tg3_interfaces))
      or  ((!$tune_tso_gso_off_on_virtio_net) and ($interface_name in $virtio_net_interfaces)) {
    #turn on tso and gso immediately with an Exec
    exec { "enable tso and gso on ${interface_name}":
      command => "/sbin/ethtool -K ${interface_name} tso on gso on",
      onlyif  => "/sbin/ethtool -k ${interface_name} | grep segmentation-offload | grep -q ': off'",
    }
    $tso_ethtool_opts = ''
  } else {
    $tso_ethtool_opts = ''
  }

  #LB: tune the ring buffers on the network card to maximum size
  if (str2bool($tune_ringbuffer_to_max)) {
    #figure out if we need to make an adjustment right now by comparing the current and max size
    if (has_key($::interface_ringbuffer, $interface_name)) {
      $int_buf = $::interface_ringbuffer[$interface_name]
      if ($int_buf['rx_cur'] < $int_buf['rx_max']) {
        exec { "tune ${interface_name} RX ringbuffer to ${int_buf['rx_max']}":
          command => "/sbin/ethtool -G ${interface_name} rx ${int_buf['rx_max']}",
        }
      }
      if ($int_buf['tx_cur'] < $int_buf['tx_max']) {
        exec { "tune ${interface_name} TX ringbuffer to ${int_buf['tx_max']}":
          command => "/sbin/ethtool -G ${interface_name} tx ${int_buf['tx_max']}",
        }
      }
      $rb_ethtool_opts = "-G ${interface_name} rx ${int_buf['rx_max']} tx ${int_buf['tx_max']}"
    } else {
      $rb_ethtool_opts = ''
    }
  } else {
    $rb_ethtool_opts = ''
  }
  $ethtool_array = delete([$ethtool_opts, $tso_ethtool_opts, $rb_ethtool_opts], '')

  if (size($ethtool_array) > 0) {
    $generated_ethtool_opts = join($ethtool_array, ';')
  }

  #Define a network_config custom type for this interface, which writes the /etc/sysconfig/network-scripts/ file.
  lmax_network_config { $interface_name:
    ensure       => present,
    exclusive    => false,
    hwaddr       => $hwaddr,
    broadcast    => $broadcast,
    ipaddr       => $ipaddr,
    netmask      => $netmask,
    network      => $network,
    gateway      => $gateway,
    type         => $type,
    onboot       => $onboot,
    mtu          => $mtu,
    bootproto    => $bootproto,
    vlan         => $vlan,
    bridge       => $bridge,
    master       => $master,
    ethtool_opts => $generated_ethtool_opts,
    slave        => $slave,
    bonding_opts => $bonding_opts,
  }

  if (str2bool($monitor)) {
    #LB: every time we define an interface, define monitoring for it as well
    networking::monitoring::interface { $interface_name:
      type                  => $type,
      hwaddr                => $hwaddr,
      broadcast             => $broadcast,
      cidr                  => $cidr,
      enable                => $enable,
      extra                 => $extra,
      ipaddr                => $ipaddr,
      mtu                   => $mtu,
      netmask               => $netmask,
      network               => $network,
      gateway               => $gateway,
      options               => $options,
      onboot                => $onboot,
      bootproto             => $bootproto,
      vlan                  => $vlan,
      bridge                => $bridge,
      master                => $master,
      ethtool_opts          => $generated_ethtool_opts,
      slave                 => $slave,
      bonding_opts          => $bonding_opts,
      monitor_lldp_patching => $monitor_lldp_patching,
      monitor               => $monitor,
      new_gateway_check     => $new_gateway_check,
      new_carrier_check     => $new_carrier_check,
      reverse_dns_check     => $reverse_dns_check,
      testip                => $testip,
    }
  }
}
