require File.expand_path('test_helper.rb', File.dirname(__FILE__))

class MessageBackoffTest < Test::Unit::TestCase
  
  def setup
    Surety::Configuration.database_prefix = 'surety_'
    Surety::Message.new.connection.execute("truncate table messages")
    @message = Surety::Message.generate_message('Testing message')
    @message.begin_processing!
    @message.fail_processing!
  end
  
  def test_backoff_with_one_failure
    # Before interval
    message = Surety::Message.needs_processing.first
    assert message.nil?
    # After interval
    @message.failed_at = Time.now-12.minutes
    @message.save
    message = Surety::Message.needs_processing.first
    assert message.present?
  end
  
  def test_backoff_with_backoff_factor_failures
    @message.failed_at = Time.now-12.minutes
    @message.failure_count = 2
    # Before interval
    message = Surety::Message.needs_processing.first
    assert message.nil?
    # After interval
    @message.failed_at = Time.now-21.minutes
    @message.save
    message = Surety::Message.needs_processing.first
    assert message.present?
  end
  
  def test_max_backoff
    @message.failed_at = Time.now-1277.minutes
    @message.failure_count = 20
    # Before interval
    message = Surety::Message.needs_processing.first
    assert message.nil?
    # After interval
    @message.failed_at = Time.now-1285.minutes
    @message.save
    message = Surety::Message.needs_processing.first
    assert message.present?
  end
  
end