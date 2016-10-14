## file managed by modulesync_configs
## Any manual changes will be overwritten

require 'rubygems'
require 'bundler/setup'

require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet/version'
require 'puppet/vendor/semantic/lib/semantic' unless Puppet.version.to_f < 3.6
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'
require 'metadata-json-lint/rake_task'
require 'rubocop/rake_task'  unless RUBY_VERSION.to_f < 1.9

# These gems aren't always present, for instance
# on Travis with --without development
begin
  require 'puppet_blacksmith/rake_tasks'  unless RUBY_VERSION.to_f < 1.9
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

RuboCop::RakeTask.new  unless RUBY_VERSION.to_f < 1.9

exclude_paths = [
  "bundle/**/*",
  "pkg/**/*",
  "vendor/**/*",
  "spec/**/*",
]

# Coverage from puppetlabs-spec-helper requires rcov which
# doesn't work in anything since 1.8.7
#Rake::Task[:coverage].clear

Rake::Task[:lint].clear

PuppetLint.configuration.fail_on_warnings = true
PuppetLint.configuration.send('relative')
PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.send('disable_140chars')
PuppetLint.configuration.send('disable_class_inherits_from_params_class')
PuppetLint.configuration.send('disable_documentation')
PuppetLint.configuration.send('disable_single_quote_string_with_variables')

PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = exclude_paths
end

desc "Populate CONTRIBUTORS file"
task :contributors do
  system("git log --format='%aN' | sort -u > CONTRIBUTORS")
end

desc "Run validate, syntax, lint, and spec tests."
task :test => [
  :validate,
  :metadata_lint,
  :syntax,
  :lint,
#  :rubocop,
  :spec,
]

desc "Validate manifests, templates, and ruby files"
task :validate do
  Dir['manifests/**/*.pp'].each do |manifest|
    sh "puppet parser validate --noop #{manifest}"
  end
  Dir['spec/**/*.rb', 'lib/**/*.rb'].each do |ruby_file|
    sh "ruby -c #{ruby_file}" unless ruby_file =~ /spec\/fixtures/
  end
  Dir['templates/**/*.erb'].each do |template|
    sh "erb -P -x -T '-' #{template} | ruby -c"
  end
end

desc "Run beaker acceptance tests on a single spec file"
RSpec::Core::RakeTask.new(:beakerfile, :file) do |t, task_args|
  t.rspec_opts = ['--color']
  t.pattern = "spec/acceptance/#{task_args[:file]}"
end

desc "Run spec tests on a single spec/classes/something_spec.rb spec file"
RSpec::Core::RakeTask.new(:single, :file) do |t, task_args|
  Rake::Task[:spec_prep].invoke
  t.rspec_opts = ['--color']
  t.pattern = "spec/{classes,defines}/#{task_args[:file]}"
end
