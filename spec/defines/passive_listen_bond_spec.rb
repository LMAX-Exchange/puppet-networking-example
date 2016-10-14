require 'spec_helper'
describe 'networking::passive_listen_bond' do
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

  context 'with no parameters' do
    it { expect { should compile }.to raise_error(/Must pass slaves/) }
  end

  context 'with two slaves' do
    let(:params) {
      {
        :slaves => [ 'eth0', 'eth1', ],
      }
    }
    it { should compile }
    it { should contain_networking__config__interface('bond0').with(
        'enable'                => true,
        'onboot'                => 'yes',
        'ipaddr'                => nil,
        'netmask'               => nil,
        'network'               => nil,
        'broadcast'             => nil,
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
