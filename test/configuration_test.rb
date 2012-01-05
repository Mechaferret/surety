require File.expand_path('test_helper.rb', File.dirname(__FILE__))

class ConfigurationTest < Test::Unit::TestCase

  def setup
    Surety::Configuration.database_prefix = 'surety_'
  end
  
  def test_database_configuration
    assert Surety::Configuration.database=='surety_test'
  end
  
end