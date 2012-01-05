require File.expand_path('test_helper.rb', File.dirname(__FILE__))

class GeneratorTest < Test::Unit::TestCase

  def setup
    Surety::Configuration.database_prefix = 'surety'
  end
  
  def test_message_generation
    TestGenerator.new.generate_test_message
    message = Surety::Message.first
    assert message.present?
    assert_message_matches(message, 
      {
        :message_content=>'This is a test',
        :state => 'unprocessed',
        :processing_attempt_count => 0,
        :failure_count => 0,
        :processing_started_at => nil,
        :completed_at => nil,
        :failed_at => nil,
        :last_exception => nil
      })
  end
  
end