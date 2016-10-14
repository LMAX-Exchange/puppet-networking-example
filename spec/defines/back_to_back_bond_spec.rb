require 'spec_helper'
describe 'networking::back_to_back_bond' do
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
      :ipaddr => 'notanIP',
      :other_ipaddr => '192.168.0.20',
    }}
    it { expect { should compile }.to raise_error(/Must pass slaves/) }
  end
  context 'with a non-array slaves parameter' do
    let(:params) {{
      :slaves => 'string',
      :ipaddr => 'notanIP',
      :other_ipaddr => '192.168.0.20',
    }}
    it { expect { should compile }.to raise_error(/is not an Array/) }
  end
  context 'with no ipaddr parameter' do
    let(:params) {{
      :slaves => [ 'eth0' ],
      :other_ipaddr => '192.168.0.20',
    }}
    it { expect { should compile }.to raise_error(/Must pass ipaddr/) }
  end
  context 'with no other_ipaddr parameter' do
    let(:params) {{
      :slaves => [ 'eth0' ],
      :ipaddr => 'notanIP',
    }}
    it { expect { should compile }.to raise_error(/Must pass other_ipaddr/) }
  end

  context 'with an invalid IP address' do
    let(:params) {{
      :slaves => [ 'eth0' ],
      :ipaddr => 'notanIP',
      :other_ipaddr => '192.168.0.20',
    }}
    it { expect { should compile }.to raise_error(/is not a valid IPv4 address/) }
  end

  context 'with an invalid other IP address' do
    let(:params) {{
      :slaves => [ 'eth0' ],
      :ipaddr => '192.168.0.10',
      :other_ipaddr => 'notAnIP',
    }}
    it { expect { should compile }.to raise_error(/is not a valid IPv4 address/) }
  end

  context 'with two slaves' do
    let(:params) {{
      :slaves => [ 'eth0', 'eth1' ],
      :ipaddr => '192.168.0.10',
      :other_ipaddr => '192.168.0.20',
    }}
    it { should compile }
    it { should contain_networking__config__interface('bond0').with(
        'enable'                => true,
        'onboot'                => 'yes',
        'ipaddr'                => '192.168.0.10',
        'testip'                => '192.168.0.20',
        'netmask'               => '255.255.255.0',
        'network'               => '192.168.0.0',
        'broadcast'             => '192.168.0.255',
        'type'                  => 'Bonding',
        'bonding_opts'          => 'mode=balance-rr miimon=100',
        'gateway'               => nil,
        'reverse_dns_check'     => false,
        'monitor_lldp_patching' => false
      ) }
    it { should contain_networking__config__interface('eth0').with(
        'enable'                => true,
        'onboot'                => 'yes',
        'ipaddr'                => nil,
        'netmask'               => nil,
        'network'               => nil,
        'broadcast'             => nil,
        'type'                  => 'Ethernet',
        'gateway'               => nil,
        'slave'                 => 'yes',
        'master'                => 'bond0',
        'reverse_dns_check'     => false,
        'monitor_lldp_patching' => false
      ) }
    it { should contain_networking__config__interface('eth1').with(
        'enable'                => true,
        'onboot'                => 'yes',
        'ipaddr'                => nil,
        'netmask'               => nil,
        'network'               => nil,
        'broadcast'             => nil,
        'type'                  => 'Ethernet',
        'gateway'               => nil,
        'slave'                 => 'yes',
        'master'                => 'bond0',
        'reverse_dns_check'     => false,
        'monitor_lldp_patching' => false
      ) }
  end
end
