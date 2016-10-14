define networking::monitoring::interface::check (
  $interface,
  $check,
) {
  snmpd::config_line { "check_specific_carrier_${interface}_${check}":
    line    => "extend check_specific_carrier_${interface}_${check} /usr/local/bin/check_carrier.sh ${interface} ${check}",
    require => File['/usr/local/bin/check_carrier.sh'],
  }

  nagios::host::service::slow { "check_specific_carrier_${interface}_${check}":
    service_description => "Carrier Check ${interface} ${check}",
    notes               => 'CarrierCheck',
    check_command       => "check_specific_carrier!${interface}!${check}!",
    servicegroups       => [
      'networking',
      'check_carrier',
      "check_carrier_${check}",
      "check_carrier_${interface}",
      "check_carrier_${interface}_${check}",
    ],
  }


}
