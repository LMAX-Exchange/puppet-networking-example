## file managed by modulesync_configs
## Any manual changes will be overwritten
require 'simplecov'
require 'simplecov-console'
SimpleCov.start do
  add_filter '/spec'
  add_filter '/vendor'
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console

  ])
end

require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
require 'rspec-puppet-utils'

include RspecPuppetFacts


RSpec.configure do |c|
  #c.fail_fast = true

  # Enable disabling of tests
  c.filter_run_excluding :broken => true

  #enable in module hiera data for tests
  c.hiera_config = 'spec/fixtures/hiera.yaml'

  c.default_facts = {
    :osfamily               => 'RedHat',
    :operatingsystem        => 'CentOS',
    :operatingsystemrelease => '6',
    :concat_basedir         => '/dne',
    :cache_bust             => Time.now,  # hopefully invalidate the cache for each test. May need to be in each 'describe'
  }
end

at_exit do
  RSpec::Puppet::Coverage.report!()
end
