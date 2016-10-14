#= define networking::wireless
#
#Creates a wireless network connection of the given SSID (name) and key.
define networking::wireless($key) {
  include ::networking::networkmanager

  #LB: get the wireless device name and mac address.
  #At the moment we only expect to use this on Fedora 21 and laptops, so we
  #can assume we're using the Broadcom 'wl' driver. In Fed21 this appears
  #as facter fact as 'wl0' though (that's what ethtool says).
  $device_name = $::nic_driver_wl0
  if ((!$device_name) or ($device_name == '') or ($device_name == undef) or (size($device_name) <= 0)) {
    notice("No wireless device driver found, can't continue in Networking::Wireless[${name}]")
  } else {
    $mac = inline_template("<%= scope.lookupvar('macaddress_${device_name}') %>")

    file { "/etc/sysconfig/network-scripts/keys-${name}":
      ensure  => present,
      mode    => '0600',
      owner   => 'root',
      group   => 'root',
      content => "WPA_PSK='${key}'\n",
      notify  => Class[networking::networkmanager],
    }
    file { "/etc/sysconfig/network-scripts/ifcfg-${name}":
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => template("${module_name}/ifcfg-wireless.erb"),
      notify  => Class[networking::networkmanager],
    }
  }
}
