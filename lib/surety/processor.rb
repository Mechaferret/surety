module Surety
  class Processor
    
    @queue = :surety_messages
    
    def self.perform
      puts "[Surety::Processor]: Handling surety message"
      message = Surety::Message.get_next_for_processing
      puts "[Surety::Processor]: Found message #{message.inspect}"
      begin
        message.process
      rescue Exception => ex
        raise ex
      ensure
        request_next
      end
        
    end
    
    def self.request_next
      Resque.enqueue(self)
    end
    
  end
end