module Surety
  module Generator

    def send_message(message_content)
      Surety::Message.generate_message(message_content)
    end

  end
end
