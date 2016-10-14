require 'spec_helper'
describe 'networking::config::interface' do
  let(:title) { 'bond0' }
  let(:name) { 'bond0' }
  let(:facts) {{
    :concat_basedir => '/dne',
    :operatingsystem => 'CentOS',
    :operatingsystemrelease => '6',
    :operatingsystemmajrelease => '6',
    :nic_driver_tg3 => 'eth0',
    :nic_driver_virtual => 'eth1',
    :interface_ringbuffer => { 'eth0' => { 'rx_cur'=>'256', 'rx_max'=>'2048', 'tx_max'=>'4096', 'tx_cur'=>'256'} },
  }}

  context 'with bond member style parameters' do
    let(:title) { 'eth0' }
    let(:name) { 'eth0' }
    let(:params) {{
      :type         => 'Ethernet',
      :enable       => true,
      :onboot       => 'yes',
      :slave        => 'yes',
      :master       => 'bond0',
      :ethtool_opts => 'foo',
    }}

    it 'should add a network_config resource for eth0 that is slaved to bond0' do
      should contain_lmax_network_config('eth0').with({
        :ensure    => 'present',
        :exclusive => false,
        :ipaddr    => nil,
        :onboot    => 'yes',
        :slave     => 'yes',
        :master    => 'bond0',
      })
    end

    it 'should not try turn off TSO' do
      should_not contain_exec('disable tso and gso on eth0')
    end

    it 'should just have ethtool opts we specify, no extras' do
      should contain_lmax_network_config('eth0').with({
      'ethtool_opts' => 'foo'
      })
    end
  end

  context 'with TSO off on tg3' do
    let(:title) { 'eth0' }
    let(:name) { 'eth0' }
    let(:params) {{
      :type         => 'Ethernet',
      :ethtool_opts => 'foo',
      'tune_tso_gso_off_on_tg3' => true,
    }}
    it 'should not try turn off TSO' do
      should contain_exec('disable tso and gso on eth0')
    end

    it 'should have our ethtool opts plus the tso/gso tuning off' do
      should contain_lmax_network_config('eth0').with({
      'ethtool_opts' => 'foo;-K eth0 tso off gso off'
      })
    end
  end

  context 'with ringbuffer max size set' do
    let(:title) { 'eth0' }
    let(:name) { 'eth0' }
    let(:params) {{
      :type         => 'Ethernet',
      :ethtool_opts => 'foo',
      'tune_ringbuffer_to_max' => true,
    }}
    it 'should set ringbuffer size to maximum' do
      should contain_lmax_network_config('eth0').with({
        'ethtool_opts' => 'foo;-G eth0 rx 2048 tx 4096'
      })
    end
  end

  context 'with both TSO off and ringbuffer max size set' do
    let(:title) { 'eth0' }
    let(:name) { 'eth0' }
    let(:params) {{
      :type         => 'Ethernet',
      :ethtool_opts => 'foo',
      'tune_tso_gso_off_on_tg3' => true,
      'tune_ringbuffer_to_max' => true,
    }}
    it 'should configure ringbuffer size to maximum' do
      should contain_lmax_network_config('eth0').with({
        'ethtool_opts' => 'foo;-K eth0 tso off gso off;-G eth0 rx 2048 tx 4096'
      })
    end
    it 'should set ringbuffer size now' do
      should contain_exec('tune eth0 RX ringbuffer to 2048').with({
        'command' => '/sbin/ethtool -G eth0 rx 2048'
      })
      should contain_exec('tune eth0 TX ringbuffer to 4096').with({
        'command' => '/sbin/ethtool -G eth0 tx 4096'
      })
    end
  end

  context 'with ringbuffer max size set and the interface already tuned' do
    let(:facts) {{
      :concat_basedir => '/dne',
      :operatingsystem => 'CentOS',
      :operatingsystemrelease => '6',
      :operatingsystemmajrelease => '6',
      :nic_driver_tg3 => 'eth0',
      :interface_ringbuffer => { 'eth0' => { 'rx_cur'=>'2048', 'rx_max'=>'2048', 'tx_max'=>'4096', 'tx_cur'=>'4096'} },
    }}
    let(:title) { 'eth0' }
    let(:name) { 'eth0' }
    let(:params) {{
      :type         => 'Ethernet',
      'tune_ringbuffer_to_max' => true,
    }}
    it 'should configure ringbuffer size to maximum' do
      should contain_lmax_network_config('eth0').with({
        'ethtool_opts' => '-G eth0 rx 2048 tx 4096'
      })
    end
    it 'show not set ringbuffer size now' do
      should_not contain_exec('tune eth0 RX ringbuffer to 2048')
      should_not contain_exec('tune eth0 TX ringbuffer to 4096')
    end
  end
end
