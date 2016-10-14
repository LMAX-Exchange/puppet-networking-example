#LB: This custom fact will create Facter facts of the format nic_driver_<driver>
#that contain a comma separated string of all the networking interfaces that use this driver.

#Facter already knows about interfaces
drivers = Hash.new
Facter.value(:interfaces).split(',').each do |int|
  #call ethtool to get the driver for this NIC
  driver = %x{/sbin/ethtool -i #{int} 2>/dev/null | grep 'driver: '}.chomp.sub("driver: ", "")
  if driver == ''
    driver = 'virtual'
  end
  if not drivers.has_key?(driver)
    drivers[driver] = Array.new
  end
  drivers[driver] << int
end

#Add Fact per driver, with comma separated interfaces in each Fact
drivers.each do |driver,ints|
  Facter.add("nic_driver_#{driver}") do
    confine :kernel => :linux
    setcode do
      ints.join(',')
    end
  end
end
