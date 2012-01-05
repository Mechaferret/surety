class TestDelegate
  def self.process(message)
    #puts "processing #{message.inspect}"
    if message.message_content.match('Good')
      @@processing_result = "Success processing #{message.message_content}"
    elsif message.message_content.match('Bad')
      @@processing_result = "Failure processing #{message.message_content}"
      raise Exception.new('opps')
    else
      @@processing_result = 'What?'
    end
    #puts "result is #{@@processing_result}"
  end
  
  def self.processing_result
    @@processing_result
  end
end