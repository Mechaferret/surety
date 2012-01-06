module Surety
  class Processor
    
    @queue = :surety_messages
    
    def self.perform
      message = nil
      puts "[Surety::Processor]: Handling surety message"
      begin
        message = Surety::Message.get_next_for_processing
        puts "[Surety::Processor]: Found message #{message.inspect}"
        message.process if message
      rescue Exception => ex
        puts "[Surety::Processor]: error #{ex.to_s}"
        puts "[Surety::Processor]: #{ex.backtrace.join("\n")}"
        raise ex
      ensure
        sleep 5 if message.nil?
        request_next
      end
        
    end
    
    def self.request_next
      Resque.enqueue(self)
    end
    
  end
end