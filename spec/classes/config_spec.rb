require 'spec_helper'

describe 'networking::config' do
   let(:facts) {{
    :concat_basedir => '/dne',
    :operatingsystem => 'CentOS',
    :operatingsystemrelease => '6',
    :operatingsystemmajrelease => '6'
  }}

  context 'with no params' do
    it { should compile }
    it { should contain_class('networking::config') }
    it { should_not contain_file('/etc/udev/rules.d/70-persistent-net.rules') }
  end

  context 'with udev_static_interface_names=true' do
    let(:params) {{
      :udev_static_interface_names => true,
      :interfaces => {
        'eth0' => {
          'broadcast' => '192.168.10.255',
          'enable'    => true,
          'hwaddr'    => '01:02:03:04:05:06',
          'gateway'   => '192.168.10.1',
          'ipaddr'    => '192.168.10.10',
          'netmask'   => '192.168.10.0',
          'onboot'    => 'yes',
          'type'      => 'Ethernet',
        }
      },
    }}
    it { should contain_file('/etc/udev/rules.d/70-persistent-net.rules').with_content(/^SUBSYSTEM=="net", ACTION=="add", DRIVERS=="\?\*", ATTR\{address\}=="01:02:03:04:05:06", ATTR\{type\}=="1", KERNEL=="eth\*", NAME="eth0"$/) }
  end

  context 'with extra_udev_static_interface_names' do
    let(:params) {{
      :udev_static_interface_names => true,
      :interfaces => nil,
      :extra_udev_static_interface_names => {
        'eth0' => '01:02:03:04:05:06',
      }
    }}
    it { should contain_file('/etc/udev/rules.d/70-persistent-net.rules').with_content(/^SUBSYSTEM=="net", ACTION=="add", DRIVERS=="\?\*", ATTR\{address\}=="01:02:03:04:05:06", ATTR\{type\}=="1", KERNEL=="eth\*", NAME="eth0"$/) }
  end
end
