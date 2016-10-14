class networking::networkmanager {
  #LB: when we write red hat style ifcfg-* files, NetworkManager must be told to
  #reload them to see them.
  exec { 'nmcli_reload':
    command     => '/usr/bin/nmcli conn reload',
    refreshonly => true,
  }
}
