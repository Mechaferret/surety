module Surety
  module Configuration
    extend self
    
    attr_accessor :database_prefix, :message_processing_delegate, :retry_interval, :backoff_factor, :max_backoff
    
    def database
      "#{database_prefix}#{ENV['RAILS_ENV'] || Rails.env}"
    end
    
  end
end
