## file managed by modulesync_configs
## Any manual changes will be overwritten

notification :off


group :test, halt_on_fail: true do
    guard 'rake', :task => 'test' do
      watch(%r{^manifests\/(.+)\.pp$})
      watch(%r{^spec\/(classes|defines)/.+\.rb$})
      watch('.fixtures.yml')
      watch('Gemfile')
      watch('metadata.json')
    end
end
