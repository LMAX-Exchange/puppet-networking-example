#=Define: networking::config::rule
define networking::config::rule (
  $rules = undef
) {
    lmax_network_rule { $name:
      ensure    => present,
      exclusive => true,
      device    => $name,
      rules     => $rules,
  }
}
