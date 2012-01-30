module Surety
  class Message < ActiveRecord::Base
    require 'state_machine'
    establish_connection Surety::Configuration.database

    scope :unprocessed, where(:state => 'unprocessed')
    scope :processing,  where(:state => 'processing')
    scope :completed,   where(:state => 'completed')
    scope :failed,      where(:state => 'failed')
    
    scope :needs_processing, lambda {
      db_time = Time.now.send(ActiveRecord::Base.default_timezone.to_s=='utc' ? :utc : :localtime)
      {:conditions=>"(messages.state='unprocessed') or (messages.state='failed' and messages.failed_at<('#{(db_time).strftime('%Y-%m-%d %H:%M:%S')}' - 
        INTERVAL (#{Surety::Configuration.retry_interval || 10}*
        POW(2, if(floor(failure_count/#{Surety::Configuration.backoff_factor || 2})>#{Surety::Configuration.max_backoff || 7}, 
        #{Surety::Configuration.max_backoff || 7},
        floor(failure_count/#{Surety::Configuration.backoff_factor || 2})))) 
        MINUTE))",
      :order => :created_at, :limit=>1}
    }

    def self.generate_message(message_content)
      self.create(:message_content=>message_content)
    end
    
    def self.get_next_for_processing
      next_message = nil
      ActiveRecord::Base.transaction do
        next_message = self.needs_processing.first
        next_message.begin_processing! if next_message
      end
      next_message
    end

    state_machine :state, :initial => :unprocessed do
      state :unprocessed
      state :processing
      state :completed
      state :failed
      
      event :begin_processing do
        transition [:unprocessed, :failed] => :processing
      end
      
      event :complete_processing do
        transition :processing => :completed
      end
      
      event :fail_processing do
        transition :processing => :failed
      end

      before_transition :on => :begin_processing, :do => :reserve
      before_transition :on => :complete_processing, :do => :record_completion
      before_transition :on => :fail_processing, :do => :record_failure
    end
    
    def reserve
      self.processing_started_at = Time.now
      self.processing_attempt_count = self.processing_attempt_count+1
    end
    
    def process
      begin
        Surety::Configuration.message_processing_delegate.process(self)
        self.complete_processing!
      rescue Exception => ex
        self.last_exception = ex
        self.fail_processing!
        raise ex
      end
    end
    
    def record_completion
      self.completed_at = Time.now
      self.last_exception = nil
    end

    def record_failure
      self.failed_at = Time.now
      self.failure_count = self.failure_count+1
    end

  end
end
