#=Class: networking::config
#
#Configures the network interfaces for a Puppet client.
class networking::config (
    $udev_static_interface_names             = $::networking::udev_static_interface_names,
    $udev_static_interface_names_config_file = '/etc/udev/rules.d/70-persistent-net.rules',
    $extra_udev_static_interface_names       = $::networking::extra_udev_static_interface_names,
    $interfaces                              = $::networking::interfaces,
    $routes                                  = $::networking::routes,
    $rules                                   = $::networking::rules,
    $monitor                                 = $::networking::monitor,
    $new_gateway_check                       = $::networking::new_gateway_check,
) {
  #Everything needs a loopback interface. Just incase someone accidently creates a network_config
  #resource without the exclusive => "false" parameter, we'll make sure that Puppet doesn't nuke it
  #by specifying it below.
  include ::networking::lo

  #Use the create_resources function to generate resources using the hash data. It's rather
  #strict, so if you're missing a required parameter (like in a define), it will cause a fatal failure
  #with a rather generic error message. We try to mitigate this - as well as work around limitations
  #in the network_config custom type - by using the lmax_network user defined type as a wrapper.

  # We want to blow up here if there's no networking config. Do not set a default here.

  # We don't need this on F20 pairing stations
if ($::operatingsystem != 'Fedora') {
  file { '/sbin/ifup-local':
    ensure => present,
    source => "puppet:///modules/${module_name}/sbin/ifup-local",
    owner  => 'root',
    mode   => '0700',
  }
}
  if (is_hash($interfaces)) {
    create_resources('networking::config::interface', $interfaces)
  }

  if (is_hash($routes)) {
    create_resources('networking::config::route', $routes)
  }

  if (is_hash($rules)) {
    create_resources('networking::config::rule', $rules)
  }

  if ($udev_static_interface_names == true) {
    file { $udev_static_interface_names_config_file:
      ensure  => 'file',
      content => template("${module_name}/${udev_static_interface_names_config_file}.erb"),
    }
  }
}
