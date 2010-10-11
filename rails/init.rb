# Rails initialization (for Rails 2.x)
#
# This will load the adapter for the currently used database configuration, if
# it exists.

begin
  adapter = ActiveRecord::Base.configurations[RAILS_ENV]['adapter']
  require "spatial_adapter/#{adapter}"
  # Also load the adapter for the test environment.  In 2.2, at least, when running db:test:prepare, the first
  # connection instantiated is the RAILS_ENV one, not 'test'.
  test_adapter = ActiveRecord::Base.configurations['test']['adapter']
  require "spatial_adapter/#{test_adapter}"
rescue LoadError => e
  puts "Caught #{e} #{e.message} #{e.backtrace.join("\n")}"
  raise SpatialAdapter::NotCompatibleError.new("spatial_adapter does not currently support the #{adapter} database.")
end
