require 'spec_helper_acceptance'

describe 'networking' do
  describe 'building various network configurations' do
    it 'should work with no errors' do
      pp = <<-EOS
        file { '/etc/snmp':
          ensure => directory,
        }
        class { 'networking':
          tune_tso_gso_off_on_virtio_net => true,
          rules => {
            'lo' => {
              'rules' => [
                'fwmark 111 lookup 100',
              ]
            }
          },
          routes => {
            'eth0' => {
              'device' => 'eth0',
              'routes' => [
                '192.168.50.0/24 via 192.168.10.1',
                '192.168.30.0/24 via 192.168.10.1 dev eth0',
              ]
            }
          },
          interfaces => {
            'eth0' => {
              'type'         => 'Ethernet',
              'enable'       => true,
              'onboot'       => 'yes',
              'ipaddr'       => '192.168.10.10',
              'gateway'      => '192.168.10.1',
              'netmask'      => '255.255.255.0',
              'broadcast'    => '192.168.10.255',
              'mtu'          => 9000,
              'ethtool_opts' => '-X',
            },
            'eth0:0' => {
              'enable'       => true,
              'onboot'       => 'yes',
              'ipaddr'       => '192.168.10.50',
              'broadcast'    => '192.168.10.255',
              'netmask'      => '255.255.255.0',
            },
            'bond0' => {
              'enable'       => true,
              'onboot'       => 'yes',
              'type'         => 'Bonding',
              'ipaddr'       => '192.168.10.10',
              'netmask'      => '255.255.255.0',
              'broadcast'    => '192.168.10.255',
              'gateway'      => '192.168.10.1',
              'bonding_opts' => 'mode=802.3ad xmit_hash_policy=layer3+4 lacp_rate=slow miimon=100',
            },
            'eth1' => {
              'enable' => true,
              'onboot' => 'yes',
              'type'   => 'Ethernet',
              'slave'  => 'yes',
              'master' => 'bond0',
            },
            'eth2' => {
              'enable' => true,
              'onboot' => 'yes',
              'type'   => 'Ethernet',
              'slave'  => 'yes',
              'master' => 'bond0',
            },
            'bond1.10' => {
              'enable'    => true,
              'onboot'    => 'yes',
              'vlan'      => 'yes',
              'ipaddr'    => '192.168.10.10',
              'netmask'   => '255.255.255.0',
              'broadcast' => '192.168.10.255',
              'gateway'   => '192.168.10.1',
            },
            'bond1' => {
              'enable'       => true,
              'onboot'       => 'yes',
              'type'         => 'Bonding',
              'bonding_opts' => 'mode=active-backup',
            },
            'eth3' => {
              'enable' => true,
              'onboot' => 'yes',
              'type'   => 'Ethernet',
              'slave'  => 'yes',
              'master' => 'bond1',
            },
            'eth4' => {
              'enable' => true,
              'onboot' => 'yes',
              'type'   => 'Ethernet',
              'slave'  => 'yes',
              'master' => 'bond1',
            },
            'br10' => {
              'type'      => 'Bridge',
              'enable'    => true,
              'onboot'    => 'yes',
              'ipaddr'    => '192.168.10.10',
              'netmask'   => '255.255.255.0',
              'broadcast' => '192.168.10.255',
              'gateway'   => '192.168.10.1',
            },
            'bond2.10' => {
              'enable' => true,
              'onboot' => 'yes',
              'vlan'   => 'yes',
            },
            'bond2' => {
              'enable'       => true,
              'onboot'       => 'yes',
              'type'         => 'Bonding',
              'bonding_opts' => 'mode=802.3ad xmit_hash_policy=layer3+4 lacp_rate=slow miimon=100',
            },
            'eth5' => {
              'enable' => true,
              'onboot' => 'yes',
              'type'   => 'Ethernet',
              'slave'  => 'yes',
              'master' => 'bond2',
            },
            'eth6' => {
              'enable' => true,
              'onboot' => 'yes',
              'type'   => 'Ethernet',
              'slave'  => 'yes',
              'master' => 'bond2',
            }
          }
        }
      EOS
      #run twice, test for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end
    describe file('/etc/sysconfig/network-scripts/route-eth0') do
      it { should be_file }
      its(:content) { should match /^192\.168\.50\.0\/24 via 192\.168\.10\.1$/ }
      its(:content) { should match /^192\.168\.30\.0\/24 via 192\.168\.10\.1 dev eth0$/ }
    end
    describe file('/etc/sysconfig/network-scripts/rule-lo') do
      it { should be_file }
      its(:content) { should match /^fwmark 111 lookup 100$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-eth0') do
      it { should be_file }
      its(:content) { should match /^IPADDR=192\.168\.10\.10$/ }
      its(:content) { should match /^GATEWAY=192\.168\.10\.1$/ }
      its(:content) { should match /^DEVICE=eth0$/ }
      its(:content) { should match /^TYPE=Ethernet$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^BROADCAST=192\.168\.10\.255$/ }
      its(:content) { should match /^NETMASK=255\.255\.255\.0$/ }
      its(:content) { should match /^MTU=9000$/ }
      its(:content) { should match /^ETHTOOL_OPTS="-X -K eth0 tso off gso off"$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-eth0:0') do
      it { should be_file }
      its(:content) { should match /^IPADDR=192\.168\.10\.50$/ }
      its(:content) { should match /^DEVICE=eth0:0$/ }
      its(:content) { should match /^TYPE=Ethernet$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^BROADCAST=192\.168\.10\.255$/ }
      its(:content) { should match /^NETMASK=255\.255\.255\.0$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-bond0') do
      it { should be_file }
      its(:content) { should match /^IPADDR=192\.168\.10\.10$/ }
      its(:content) { should match /^GATEWAY=192\.168\.10\.1$/ }
      its(:content) { should match /^DEVICE=bond0$/ }
      its(:content) { should match /^TYPE=Bonding$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^BROADCAST=192\.168\.10\.255$/ }
      its(:content) { should match /^NETMASK=255\.255\.255\.0$/ }
      its(:content) { should match /^BONDING_OPTS="mode=802\.3ad xmit_hash_policy=layer3\+4 lacp_rate=slow miimon=100"$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-eth1') do
      it { should be_file }
      its(:content) { should_not match /^IPADDR=/ }
      its(:content) { should_not match /^GATEWAY=/ }
      its(:content) { should match /^DEVICE=eth1$/ }
      its(:content) { should match /^TYPE=Ethernet$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^SLAVE=yes$/ }
      its(:content) { should match /^MASTER=bond0$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-eth2') do
      it { should be_file }
      its(:content) { should_not match /^IPADDR=/ }
      its(:content) { should_not match /^GATEWAY=/ }
      its(:content) { should match /^DEVICE=eth2$/ }
      its(:content) { should match /^TYPE=Ethernet$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^SLAVE=yes$/ }
      its(:content) { should match /^MASTER=bond0$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-bond1.10') do
      it { should be_file }
      its(:content) { should match /^DEVICE=bond1.10$/ }
      its(:content) { should match /^TYPE=Ethernet$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^VLAN=yes$/ }
      its(:content) { should match /^IPADDR=192\.168\.10\.10$/ }
      its(:content) { should match /^GATEWAY=192\.168\.10\.1$/ }
      its(:content) { should match /^BROADCAST=192\.168\.10\.255$/ }
      its(:content) { should match /^NETMASK=255\.255\.255\.0$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-bond1') do
      it { should be_file }
      its(:content) { should match /^DEVICE=bond1$/ }
      its(:content) { should match /^TYPE=Bonding$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^BONDING_OPTS=mode=active-backup$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-eth3') do
      it { should be_file }
      its(:content) { should_not match /^IPADDR=/ }
      its(:content) { should_not match /^GATEWAY=/ }
      its(:content) { should match /^DEVICE=eth3$/ }
      its(:content) { should match /^TYPE=Ethernet$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^SLAVE=yes$/ }
      its(:content) { should match /^MASTER=bond1$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-eth4') do
      it { should be_file }
      its(:content) { should_not match /^IPADDR=/ }
      its(:content) { should_not match /^GATEWAY=/ }
      its(:content) { should match /^DEVICE=eth4$/ }
      its(:content) { should match /^TYPE=Ethernet$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^SLAVE=yes$/ }
      its(:content) { should match /^MASTER=bond1$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-br10') do
      it { should be_file }
      its(:content) { should match /^DEVICE=br10$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^TYPE=Bridge$/ }
      its(:content) { should match /^IPADDR=192\.168\.10\.10$/ }
      its(:content) { should match /^GATEWAY=192\.168\.10\.1$/ }
      its(:content) { should match /^BROADCAST=192\.168\.10\.255$/ }
      its(:content) { should match /^NETMASK=255\.255\.255\.0$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-bond2.10') do
      it { should be_file }
      its(:content) { should match /^DEVICE=bond2.10$/ }
      its(:content) { should match /^TYPE=Ethernet$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^VLAN=yes$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-bond2') do
      it { should be_file }
      its(:content) { should match /^DEVICE=bond2$/ }
      its(:content) { should match /^TYPE=Bonding$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^BONDING_OPTS="mode=802\.3ad xmit_hash_policy=layer3\+4 lacp_rate=slow miimon=100"$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-eth5') do
      it { should be_file }
      its(:content) { should_not match /^IPADDR=/ }
      its(:content) { should_not match /^GATEWAY=/ }
      its(:content) { should match /^DEVICE=eth5$/ }
      its(:content) { should match /^TYPE=Ethernet$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^SLAVE=yes$/ }
      its(:content) { should match /^MASTER=bond2$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-eth6') do
      it { should be_file }
      its(:content) { should_not match /^IPADDR=/ }
      its(:content) { should_not match /^GATEWAY=/ }
      its(:content) { should match /^DEVICE=eth6$/ }
      its(:content) { should match /^TYPE=Ethernet$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^SLAVE=yes$/ }
      its(:content) { should match /^MASTER=bond2$/ }
    end
  end
end
