class TestGenerator
  include Surety::Generator
  
  def generate_test_message
    send_message('This is a test')
  end
end