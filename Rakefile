require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

desc 'Default: run specs.'
task default: :spec

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = true
end
