require 'spec_helper'

describe 'networking' do
  let(:facts) {{
    :concat_basedir => '/dne',
    :operatingsystem => 'CentOS',
    :operatingsystemrelease => '6',
    :operatingsystemmajrelease => '6',
  }}

  context 'with no params' do
    it { should compile }
    it { should contain_class('networking::config') }
    it { should contain_concat('/etc/snmp/managed_interfaces.txt') }
  end

  context 'with single interface params' do
    let(:params) {{
      :interfaces => {
        'eth0' => {
          'broadcast' => '192.168.10.255',
          'enable'    => true,
          'gateway'   => '192.168.10.1',
          'ipaddr'    => '192.168.10.10',
          'netmask'   => '192.168.10.0',
          'onboot'    => 'yes',
          'type'      => 'Ethernet',
        }
      },
    }}
    it { should contain_networking__config__interface('eth0').with( {
      'type'      => 'Ethernet',
      'enable'    => true,
      'onboot'    => 'yes',
      'ipaddr'    => '192.168.10.10',
      'broadcast' => '192.168.10.255',
      'netmask'   => '192.168.10.0',
      'gateway'   => '192.168.10.1',
    } ) }
  end
end
