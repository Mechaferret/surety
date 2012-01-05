dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift dir + '/../lib'
$TESTING = true

ENV['RAILS_ENV'] = 'test'

require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_support/test_case'
require 'resque'
require 'state_machine'

require 'surety'


config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.configurations = config
require 'mysql2'
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])

load(File.dirname(__FILE__) + "/schema.rb")

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures
  self.fixture_path = File.dirname(__FILE__) + "/fixtures"
  self.use_transactional_fixtures = false
  self.use_instantiated_fixtures = false
  fixtures :all
end


# make sure we can run redis
if !system('which redis-server')
  puts '', "** can't find `redis-server` in your path"
  puts "** try running `sudo rake install`"
  abort ''
end

# start our own redis when the tests start,
# kill it when they end
at_exit do
  next if $!

  if defined?(MiniTest)
    exit_code = MiniTest::Unit.new.run(ARGV)
  else
    exit_code = Test::Unit::AutoRunner.run
  end

  pid = `ps -e -o pid,command | grep [r]edis-test`.split(" ")[0]
  puts 'Killing test redis server...'
  `rm -f #{dir}/dump.rdb`
  Process.kill('KILL', pid.to_i)
  exit exit_code
end

puts 'Starting redis for testing at localhost:9736...'
`redis-server #{dir}/redis-test.conf`
Resque.redis = '127.0.0.1:9736'
Resque.redis.namespace = 'test_surety'

Dir.glob(File.expand_path(dir + '/fixtures/*')).each { |filename| require filename }

def assert_message_matches(message, attrs)
  attrs.each_key {|key|
    #puts "checking message key: #{key} #{message.send(key.to_sym)} #{attrs[key]}"
    assert message.send(key.to_sym)==attrs[key]
  }
end