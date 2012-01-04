dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift dir + '/../lib'
$TESTING = true

require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_support/test_case'

require 'surety'
