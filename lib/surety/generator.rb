module Surety
  module Generator
    extend ActiveSupport::Concern
    
    module InstanceMethods
      
      def send_message(message_content)
        Surety::Message.generate_message(message_content)
      end
      
    end
  
  end
end