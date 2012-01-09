require File.expand_path('test_helper.rb', File.dirname(__FILE__))

class MessageTimezoneTest < Test::Unit::TestCase

  def setup
    Surety::Configuration.database_prefix = 'surety_'
    ActiveRecord::Base.default_timezone = :utc
    @message = Surety::Message.generate_message('Testing message')
  end
  
  def test_needs_processing_failure_timeout_when_active_record_using_utc
    Surety::Message.new.connection.execute("truncate table messages")
    @message1 = Surety::Message.generate_message('Message 1')
    @message2 = Surety::Message.generate_message('Message 2')
    message = Surety::Message.needs_processing.first
    message.begin_processing!
    assert message.present?
    assert_message_matches(message, {
      :message_content=>'Message 1',
      :state => 'processing',
      :processing_attempt_count => 1,
      :failure_count => 0,
      :completed_at => nil,
      :failed_at => nil,
      :last_exception => nil
    })
    assert_in_delta(message.processing_started_at, Time.now, 5)
    @message1.reload
    @message1.fail_processing!
    message = Surety::Message.get_next_for_processing
    assert message.present?
    assert_message_matches(message, {
      :message_content=>'Message 2',
      :state => 'processing',
      :processing_attempt_count => 1,
      :failure_count => 0,
      :completed_at => nil,
      :failed_at => nil,
      :last_exception => nil
    })
    assert_in_delta(message.processing_started_at, Time.now, 5)
    @message1.failed_at = Time.now-40.minutes
    @message1.save
    message = Surety::Message.get_next_for_processing
    assert message.present?
    assert_message_matches(message, {
      :message_content=>'Message 1',
      :state => 'processing',
      :processing_attempt_count => 2,
      :failure_count => 1,
      :completed_at => nil,
      :last_exception => nil
    })
    assert_in_delta(message.processing_started_at, Time.now, 5)
  end

end
