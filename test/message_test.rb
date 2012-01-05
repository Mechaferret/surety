require File.expand_path('test_helper.rb', File.dirname(__FILE__))

class MessageTest < Test::Unit::TestCase

  def setup
    Surety::Configuration.database_prefix = 'surety_'
    @message = Surety::Message.generate_message('Testing message')
  end
  
  def test_database_name
    assert Surety::Message.new.connection.current_database=='surety_test'
  end
  
  def test_message_creation
    assert_message_matches(@message, 
      {
        :message_content=>'Testing message',
        :state => 'unprocessed',
        :processing_attempt_count => 0,
        :failure_count => 0,
        :processing_started_at => nil,
        :completed_at => nil,
        :failed_at => nil,
        :last_exception => nil
      })
  end
  
  def test_message_processing
    @message.begin_processing!
    assert_message_matches(@message, 
      {
        :message_content=>'Testing message',
        :state => 'processing',
        :processing_attempt_count => 1,
        :failure_count => 0,
        :completed_at => nil,
        :failed_at => nil,
        :last_exception => nil
      })
      assert_in_delta(@message.processing_started_at, Time.now, 5)
  end
    
  def test_message_completion
    @message.begin_processing!
    @message.complete_processing!
    assert_message_matches(@message, 
      {
        :message_content=>'Testing message',
        :state => 'completed',
        :processing_attempt_count => 1,
        :failure_count => 0,
        :failed_at => nil,
        :last_exception => nil
      })
      assert_in_delta(@message.processing_started_at, Time.now, 5)
      assert_in_delta(@message.completed_at, Time.now, 5)
  end
  
  def test_message_failure
    @message.begin_processing!
    @message.fail_processing!
    assert_message_matches(@message, 
      {
        :message_content=>'Testing message',
        :state => 'failed',
        :processing_attempt_count => 1,
        :failure_count => 1,
        :completed_at => nil,
        :last_exception => nil
      })
      assert_in_delta(@message.processing_started_at, Time.now, 5)
      assert_in_delta(@message.failed_at, Time.now, 5)
  end

  def test_message_retry
    @message.begin_processing!
    @message.fail_processing!
    message_first_fail = Time.now
    sleep(10)
    @message.begin_processing!
    @message.complete_processing!
    assert_message_matches(@message, 
      {
        :message_content=>'Testing message',
        :state => 'completed',
        :processing_attempt_count => 2,
        :failure_count => 1,
        :last_exception => nil
      })
      assert_in_delta(@message.processing_started_at, Time.now, 5)
      assert_in_delta(@message.completed_at, Time.now, 5)
      assert_in_delta(@message.failed_at, message_first_fail, 5)
  end
  
  def test_bad_transitions
    assert_raise(StateMachine::InvalidTransition) {
      @message.fail_processing!
    }
    assert_raise(StateMachine::InvalidTransition) {
      @message.complete_processing!
    }
    @message.begin_processing!
    @message.fail_processing!
    assert_raise(StateMachine::InvalidTransition) {
      @message.complete_processing!
    }
    @message.begin_processing!
    @message.complete_processing!
    assert_raise(StateMachine::InvalidTransition) {
      @message.fail_processing!
    }
    assert_raise(StateMachine::InvalidTransition) {
      @message.complete_processing!
    }
    assert_raise(StateMachine::InvalidTransition) {
      @message.begin_processing!
    }
  end
  
  def test_needs_processing
    Surety::Message.new.connection.execute("truncate table messages")
    @message1 = Surety::Message.generate_message('Message 1')
    @message2 = Surety::Message.generate_message('Message 2')
    @message3 = Surety::Message.generate_message('Message 3')
    @message4 = Surety::Message.generate_message('Message 4')
    @message5 = Surety::Message.generate_message('Message 5')
    @message6 = Surety::Message.generate_message('Message 6')
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
    message = Surety::Message.needs_processing.first
    message.begin_processing!
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
    @message3.begin_processing!
    @message3.complete_processing!
    message = Surety::Message.needs_processing.first
    message.begin_processing!
    assert message.present?
    assert_message_matches(message, {
      :message_content=>'Message 4',
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
    message = Surety::Message.needs_processing.first
    message.begin_processing!
    assert message.present?
    assert_message_matches(message, {
      :message_content=>'Message 5',
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
    message = Surety::Message.needs_processing.first
    message.begin_processing!
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
  
  def test_gets_next_for_processing
    Surety::Message.new.connection.execute("truncate table messages")
    @message1 = Surety::Message.generate_message('Message 1')
    @message2 = Surety::Message.generate_message('Message 2')
    @message3 = Surety::Message.generate_message('Message 3')
    @message4 = Surety::Message.generate_message('Message 4')
    @message5 = Surety::Message.generate_message('Message 5')
    @message6 = Surety::Message.generate_message('Message 6')
    message = Surety::Message.get_next_for_processing
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
    @message3.begin_processing!
    @message3.complete_processing!
    message = Surety::Message.get_next_for_processing
    assert message.present?
    assert_message_matches(message, {
      :message_content=>'Message 4',
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
      :message_content=>'Message 5',
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