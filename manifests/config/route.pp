#=Define: networking::config::route
define networking::config::route (
  $device = undef,
  $routes = undef
) {
  lmax_network_route { $name:
    ensure    => present,
    exclusive => true,
    device    => $device,
    routes    => $routes,
  }
}
