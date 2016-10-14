require 'spec_helper'
describe 'networking::vlan' do
  let(:title) { 'eth0.10' }
  let(:name) { 'eth0.10' }
  let(:facts) {{
    :concat_basedir => '/dne',
    :operatingsystem => 'CentOS',
    :operatingsystemrelease => '6',
    :operatingsystemmajrelease => '6',
  }}

  context 'with no ipaddr parameter' do
    let(:params) {{ }}
    it { expect { should compile }.to raise_error(/Must pass ipaddr/) }
  end

  context 'with an invalid IP address' do
    let(:params) {{
      :ipaddr => 'notanIP',
    }}
    it { expect { should compile }.to raise_error(/is not a valid IPv4 address/) }
  end

  context 'with is_gateway=undef' do
    let(:params) {{
      :ipaddr => '192.168.10.10',
    }}
    it { should compile }
    it { should contain_networking__config__interface('eth0.10').with(
      'enable'                => true,
      'onboot'                => 'yes',
      'vlan'                  => 'yes',
      'ipaddr'                => '192.168.10.10',
      'netmask'               => '255.255.255.0',
      'network'               => '192.168.10.0',
      'broadcast'             => '192.168.10.255',
      'type'                  => 'Ethernet',
      'gateway'               => nil
    )}
  end

  context 'with is_gateway=true' do
    let(:params) {{
      :ipaddr     => '192.168.10.10',
      :is_gateway => true,
    }}
    it { should compile }
    it { should contain_networking__config__interface('eth0.10').with(
      'enable'                => true,
      'onboot'                => 'yes',
      'vlan'                  => 'yes',
      'ipaddr'                => '192.168.10.10',
      'netmask'               => '255.255.255.0',
      'network'               => '192.168.10.0',
      'broadcast'             => '192.168.10.255',
      'type'                  => 'Ethernet',
      'gateway'               => '192.168.10.1'
    )}
  end

  context 'with non-standard gateway' do
    let(:params) {{
      :ipaddr     => '192.168.10.10',
      :is_gateway => true,
      :gateway    => '192.168.10.20',
    }}
    it { should compile }
    it { should contain_networking__config__interface('eth0.10').with(
      'enable'                => true,
      'onboot'                => 'yes',
      'vlan'                  => 'yes',
      'ipaddr'                => '192.168.10.10',
      'netmask'               => '255.255.255.0',
      'network'               => '192.168.10.0',
      'broadcast'             => '192.168.10.255',
      'type'                  => 'Ethernet',
      'gateway'               => '192.168.10.20'
    )}
  end
end
