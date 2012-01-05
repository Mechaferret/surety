module Surety
  module Configuration
    extend self
    
    attr_accessor :database_prefix, :message_processing_delegate
    
    def database
      "#{database_prefix}#{ENV['RAILS_ENV']}"
    end
    
  end
end
