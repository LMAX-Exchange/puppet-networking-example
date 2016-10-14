require 'puppet'

module Puppet

  Puppet::Type.newtype(:lmax_network_rule) do
    @doc = "The rule configuration type"

    ensurable

    newparam(:exclusive) do
      d = "Enforces that no rule configuration exists besides what puppet defines.\n"
      d << "Enabled by default, set it to false in any resource to disable globally."
      desc(d)

      newvalues(:true, :false)
      # this behaviorally defaults to true (see network_scripts.rb exists?()/initialize())
      # using defaultto(:true) would prevent users from setting this to false
    end

    newparam(:device) do
      isnamevar
      desc "The network device for which rule will be configured"
    end

    newparam(:rules) do
      desc "The rules to be configured"
    end
  end
end
