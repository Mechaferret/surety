require File.expand_path('test_helper.rb', File.dirname(__FILE__))

class ProcessorTest < Test::Unit::TestCase

  def setup
    $success = $lock_failed = $lock_expired = 0
    Resque.redis.namespace = nil
    Resque.redis.flushall
    Resque.redis.namespace = 'test_surety'
    Surety::Configuration.database_prefix = 'surety'
    Surety::Configuration.message_processing_delegate = TestDelegate
  end
  
  def test_request_next
    Surety::Processor.request_next
    assert Resque.redis.llen('queue:surety_messages')==1
  end
  
  def test_perform_successful
    Surety::Message.new.connection.execute("truncate table messages")
    @message1 = Surety::Message.generate_message('Good Message 1')
    @message2 = Surety::Message.generate_message('Message 2')
    Surety::Processor.request_next
    Resque::Worker.new(:surety_messages).process
    @message1.reload
    assert_message_matches(@message1, 
      {
        :message_content=>'Good Message 1',
        :state => 'completed',
        :processing_attempt_count => 1,
        :failure_count => 0,
        :failed_at => nil,
        :last_exception => nil
      })
    assert_in_delta(@message1.processing_started_at, Time.now, 5)
    assert_in_delta(@message1.completed_at, Time.now, 5)
    assert TestDelegate.processing_result=='Success processing Good Message 1'
    assert Resque.redis.llen('queue:surety_messages')==1
  end
  
  def test_perform_fail
    Surety::Message.new.connection.execute("truncate table messages")
    @message1 = Surety::Message.generate_message('Bad Message 1')
    @message2 = Surety::Message.generate_message('Message 2')
    Surety::Processor.request_next
    Resque::Worker.new(:surety_messages).process
    @message1.reload
    assert_message_matches(@message1, 
      {
        :message_content=>'Bad Message 1',
        :state => 'failed',
        :processing_attempt_count => 1,
        :failure_count => 1,
        :completed_at => nil,
      })
    assert_in_delta(@message1.processing_started_at, Time.now, 5)
    assert_in_delta(@message1.failed_at, Time.now, 5)
    assert @message1.last_exception.present?
    assert TestDelegate.processing_result=='Failure processing Bad Message 1'
    assert Resque.redis.llen('queue:surety_messages')==1
  end
  
  def test_perform_multiple
    Surety::Message.new.connection.execute("truncate table messages")
    @message1 = Surety::Message.generate_message('Good Message 1')
    @message2 = Surety::Message.generate_message('Bad Message 2')
    @message3 = Surety::Message.generate_message('Good Message 3')
    @message4 = Surety::Message.generate_message('Left Alone Message 4')
    Surety::Processor.request_next
    Resque::Worker.new(:surety_messages).process
    assert TestDelegate.processing_result=='Success processing Good Message 1'
    Resque::Worker.new(:surety_messages).process
    assert TestDelegate.processing_result=='Failure processing Bad Message 2'
    Resque::Worker.new(:surety_messages).process
    assert TestDelegate.processing_result=='Success processing Good Message 3'
    assert Resque.redis.llen('queue:surety_messages')==1
    @message1.reload
    assert_message_matches(@message1, 
      {
        :message_content=>'Good Message 1',
        :state => 'completed',
        :processing_attempt_count => 1,
        :failure_count => 0,
        :failed_at => nil,
        :last_exception => nil
      })
    assert_in_delta(@message1.processing_started_at, Time.now, 5)
    assert_in_delta(@message1.completed_at, Time.now, 5)
    @message2.reload
    assert_message_matches(@message2, 
      {
        :message_content=>'Bad Message 2',
        :state => 'failed',
        :processing_attempt_count => 1,
        :failure_count => 1,
        :completed_at => nil,
      })
    assert_in_delta(@message2.processing_started_at, Time.now, 5)
    assert_in_delta(@message2.failed_at, Time.now, 5)
    assert @message2.last_exception.present?
    assert Resque.redis.llen('queue:surety_messages')==1
    @message3.reload
    assert_message_matches(@message3, 
      {
        :message_content=>'Good Message 3',
        :state => 'completed',
        :processing_attempt_count => 1,
        :failure_count => 0,
        :failed_at => nil,
        :last_exception => nil
      })
    assert_in_delta(@message3.processing_started_at, Time.now, 5)
    assert_in_delta(@message3.completed_at, Time.now, 5)
  end
  
end