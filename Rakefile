require 'rake/clean'
require 'rake/packagetask'
require 'rspec/core/rake_task'
require 'rspec'
require 'rubygems'
require 'rubygems/package_task'
require 'tbm'

CLEAN.include( 'coverage', 'pkg' )

desc '"spec" (run RSpec)'
task :default => :spec

desc "Run RSpec on spec/*"
RSpec::Core::RakeTask.new

desc "Generate code coverage"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec,/gems/,/rubygems/', '--text-report']
end

spec = Gem::Specification.new do |spec|
  spec.name = 'tbm'
  spec.version = Tunnel::VERSION
  spec.date = Tunnel::DATE
  spec.summary = 'Named SSH tunnels, like bookmarks.'
  spec.description = 'The "Tunnel Boring Machine" is meant to bore ssh tunnels through the internet to your desired destination simply and repeatedly, as often as you need them. This is a tool for someone who needs SSH tunnels frequently.'
  spec.author = 'Geoffrey Wiseman'
  spec.email = 'geoffrey.wiseman@codiform.com'
  spec.homepage = 'http://github.com/geoffreywiseman/tunnel-boring-machine'
  spec.executables << 'tbm'
  
  spec.files = Dir['{lib,spec}/**/*.rb', 'bin/*', 'Rakefile', 'README.md', 'UNLICENSE']
  
  spec.add_dependency( 'net-ssh', '>= 2.6.2' )
end

Gem::PackageTask.new( spec ) do |pkg|
  pkg.need_tar_gz = true
  pkg.need_zip = true
end