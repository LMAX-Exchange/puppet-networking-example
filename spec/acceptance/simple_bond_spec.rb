require 'spec_helper_acceptance'

describe 'networking::simple_bond' do
  describe 'running puppet code' do
    it 'should work with no errors' do
      pp = <<-EOS
        file { '/etc/snmp':
          ensure => directory,
        }
        networking::simple_bond { 'bond0':
          slaves => [ 'eth0', 'eth1', ],
          ipaddr => '192.168.242.10',
          bonding_type => 'active-backup',
          is_gateway => true,
          require => File['/etc/snmp'],
        }
      EOS
      #run twice, test for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-bond0') do
      it { should be_file }
      its(:content) { should match /^IPADDR=192\.168\.242\.10$/ }
      its(:content) { should match /^GATEWAY=192\.168\.242\.1$/ }
      its(:content) { should match /^DEVICE=bond0$/ }
      its(:content) { should match /^BONDING_OPTS="mode=active-backup miimon=100"$/ }
      its(:content) { should match /^TYPE=Bonding$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-eth0') do
      it { should be_file }
      its(:content) { should_not match /^IPADDR=/ }
      its(:content) { should_not match /^GATEwAY=/ }
      its(:content) { should match /^DEVICE=eth0$/ }
      its(:content) { should match /^TYPE=Ethernet$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^SLAVE=yes$/ }
      its(:content) { should match /^MASTER=bond0$/ }
    end
    describe file('/etc/sysconfig/network-scripts/ifcfg-eth1') do
      it { should be_file }
      its(:content) { should_not match /^IPADDR=/ }
      its(:content) { should_not match /^GATEwAY=/ }
      its(:content) { should match /^DEVICE=eth1$/ }
      its(:content) { should match /^TYPE=Ethernet$/ }
      its(:content) { should match /^ONBOOT=yes$/ }
      its(:content) { should match /^SLAVE=yes$/ }
      its(:content) { should match /^MASTER=bond0$/ }
    end
  end
end
