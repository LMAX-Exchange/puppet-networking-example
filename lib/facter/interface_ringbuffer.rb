#LB: This custom fact will list the current and maximum TX and RX ring buffer sizes
#of every physical interface.

#Facter already knows about interfaces
phys_ints = Array.new
Facter.value(:interfaces).split(',').each do |int|
  #call ethtool to get the driver for this NIC, we only want physical devices
  driver = %x{/sbin/ethtool -i #{int} 2>/dev/null | grep 'driver: '}.chomp.sub("driver: ", "")
  if driver != '' and driver != 'bonding' and driver != 'virtio_net'
    phys_ints.push(int)
  end
end

#Call "ethtool -g" to get current and max ring buffer sizes
interface_ringbuffer = Hash.new
phys_ints.each do |int|
  begin
    ethtool_g = %x{/sbin/ethtool -g #{int} 2>/dev/null | grep -P '^(RX|TX):' | awk '{print $2}'}
    arr = ethtool_g.split(/\n/)

    if arr.length > 1
      interface_ringbuffer[int] = {
        'rx_max' => arr[0],
        'tx_max' => arr[1],
        'rx_cur' => arr[2],
        'tx_cur' => arr[3],
      }
    end
  end
end
Facter.add("interface_ringbuffer") do
  confine :kernel => :linux
  setcode do
    interface_ringbuffer
  end
end
