require 'spec_helper'
describe 'networking::simple_bond' do
  let(:title) { 'bond0' }
  let(:name) { 'bond0' }
  let(:facts) {
    {
      :concat_basedir => '/dne',
      :operatingsystem => 'CentOS',
      :operatingsystemrelease => '6',
      :operatingsystemmajrelease => '6',
    }
  }

  context 'with no slaves parameter' do
    let(:params) {{
      :ipaddr => '192.168.0.1',
    }}
    it { expect { should compile }.to raise_error(/Must pass slaves/) }
  end
  context 'with no ipaddr parameter' do
    let(:params) {{
      :slaves => [ 'eth0' ]
    }}
    it { expect { should compile }.to raise_error(/is not a valid IPv4 address/) }
  end

  context 'with an invalid IP address' do
    let(:params) {
      {
        :slaves => [ 'eth0' ],
        :ipaddr => 'notanIP',
        :bonding_type => 'active-backup',
        :is_gateway => false,
      }
    }
    it do
      expect { should compile }.to raise_error(/is not a valid IPv4 address/)
    end
  end

  context 'with an invalid gateway' do
    let(:params) {
      {
        :slaves => [ 'eth0' ],
        :ipaddr => '192.168.0.10',
        :bonding_type => 'active-backup',
        :is_gateway => true,
        :gateway => 'notAnIP',
      }
    }
    it do
      expect { should compile }.to raise_error(/is not a valid IPv4 address/)
    end
  end

  context 'with an invalid bonding_type' do
    let(:params) {{
      :slaves => [ 'eth0' ],
      :ipaddr => '192.168.0.10',
      :bonding_type => 'fake',
    }}
    it do
      expect { should compile }.to raise_error(/must be one of/)
    end
  end

  context 'with two slaves' do
    let(:params) {
      {
        :slaves => [ 'eth0', ],
        :ipaddr => '192.168.0.10',
        :bonding_type => 'lacp',
        :is_gateway => false
      }
    }
    it { should compile }
    it { should contain_networking__config__interface('bond0') .with(
      'enable'       => true,
      'onboot'       => 'yes',
      'type'         => 'Bonding',
      'bonding_opts' => 'mode=802.3ad xmit_hash_policy=layer3+4 lacp_rate=slow miimon=100'
    ) }
  end

  context 'with two slaves' do
    let(:params) {
      {
        :slaves => [ 'eth0', 'eth1', ],
        :ipaddr => '192.168.0.10',
        :bonding_type => 'active-backup',
        :is_gateway => false
      }
    }
    it { should compile }
    it { should contain_networking__config__interface('bond0') .with(
        'enable'       => true,
        'onboot'       => 'yes',
        'ipaddr'       => '192.168.0.10',
        'netmask'      => '255.255.255.0',
        'network'      => '192.168.0.0',
        'broadcast'    => '192.168.0.255',
        'type'         => 'Bonding',
        'bonding_opts' => 'mode=active-backup miimon=100',
        'gateway'      => nil
      ) }
    it { should contain_networking__config__interface('eth0') .with(
        'enable'       => true,
        'onboot'       => 'yes',
        'ipaddr'       => nil,
        'netmask'      => nil,
        'network'      => nil,
        'broadcast'    => nil,
        'type'         => 'Ethernet',
        'gateway'      => nil,
        'slave'        => 'yes',
        'master'       => 'bond0'
      ) }
    it { should contain_networking__config__interface('eth1') .with(
        'enable'       => true,
        'onboot'       => 'yes',
        'ipaddr'       => nil,
        'netmask'      => nil,
        'network'      => nil,
        'broadcast'    => nil,
        'type'         => 'Ethernet',
        'gateway'      => nil,
        'slave'        => 'yes',
        'master'       => 'bond0'
      ) }
  end

  context 'with two slaves and gateway set' do
    let(:params) {
      {
        :slaves => [ 'eth0', 'eth1', ],
        :ipaddr => '192.168.0.10',
        :bonding_type => 'active-backup',
        :is_gateway => true
      }
    }
    it { should compile }
    it { should contain_networking__config__interface('bond0') .with(
        'enable'       => true,
        'onboot'       => 'yes',
        'ipaddr'       => '192.168.0.10',
        'netmask'      => '255.255.255.0',
        'network'      => '192.168.0.0',
        'broadcast'    => '192.168.0.255',
        'type'         => 'Bonding',
        'bonding_opts' => 'mode=active-backup miimon=100',
        'gateway'      => '192.168.0.1'
      ) }
    it { should contain_networking__config__interface('eth0') .with(
        'enable'       => true,
        'onboot'       => 'yes',
        'ipaddr'       => nil,
        'netmask'      => nil,
        'network'      => nil,
        'broadcast'    => nil,
        'type'         => 'Ethernet',
        'gateway'      => nil,
        'slave'        => 'yes',
        'master'       => 'bond0'
      ) }
    it { should contain_networking__config__interface('eth1') .with(
        'enable'       => true,
        'onboot'       => 'yes',
        'ipaddr'       => nil,
        'netmask'      => nil,
        'network'      => nil,
        'broadcast'    => nil,
        'type'         => 'Ethernet',
        'gateway'      => nil,
        'slave'        => 'yes',
        'master'       => 'bond0'
      ) }
  end

  context 'with two slaves and custom gateway set' do
    let(:params) {
      {
        :slaves => [ 'eth0', 'eth1', ],
        :ipaddr => '192.168.0.10',
        :bonding_type => 'active-backup',
        :is_gateway => true,
        :gateway => '192.168.0.57'
      }
    }
    it { should compile }
    it { should contain_networking__config__interface('bond0') .with(
        'enable'       => true,
        'onboot'       => 'yes',
        'ipaddr'       => '192.168.0.10',
        'netmask'      => '255.255.255.0',
        'network'      => '192.168.0.0',
        'broadcast'    => '192.168.0.255',
        'type'         => 'Bonding',
        'bonding_opts' => 'mode=active-backup miimon=100',
        'gateway'      => '192.168.0.57'
      ) }
    it { should contain_networking__config__interface('eth0') .with(
        'enable'       => true,
        'onboot'       => 'yes',
        'ipaddr'       => nil,
        'netmask'      => nil,
        'network'      => nil,
        'broadcast'    => nil,
        'type'         => 'Ethernet',
        'gateway'      => nil,
        'slave'        => 'yes',
        'master'       => 'bond0'
      ) }
    it { should contain_networking__config__interface('eth1') .with(
        'enable'       => true,
        'onboot'       => 'yes',
        'ipaddr'       => nil,
        'netmask'      => nil,
        'network'      => nil,
        'broadcast'    => nil,
        'type'         => 'Ethernet',
        'gateway'      => nil,
        'slave'        => 'yes',
        'master'       => 'bond0'
      ) }
  end

  context 'with vlan_tagged=true' do
    let(:params) {{
      :slaves => [ 'eth0', 'eth1', ],
      :ipaddr => '192.168.0.10',
      :bonding_type => 'active-backup',
      :vlan_tagged => 'true',
    }}
    it { should compile }
    it { should contain_networking__config__interface('bond0') .with(
      'enable'       => true,
      'onboot'       => 'yes',
      'ipaddr'       => '192.168.0.10',
      'netmask'      => '255.255.255.0',
      'network'      => '192.168.0.0',
      'broadcast'    => '192.168.0.255',
      'type'         => 'Bonding',
      'bonding_opts' => 'mode=active-backup miimon=100'
    )}
  end

  context 'with vlan_tagged=true and ipaddr=undef' do
    let(:params) {{
      :slaves => [ 'eth0', 'eth1', ],
      :bonding_type => 'active-backup',
      :vlan_tagged => 'true',
    }}
    it { should compile }
    it { should contain_networking__config__interface('bond0') .with(
      'enable'       => true,
      'onboot'       => 'yes',
      'ipaddr'       => nil,
      'netmask'      => nil,
      'network'      => nil,
      'broadcast'    => nil,
      'type'         => 'Bonding',
      'bonding_opts' => 'mode=active-backup miimon=100'
    )}
  end
end
