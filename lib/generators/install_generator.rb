require 'rails/generators'

module Surety
  class InstallGenerator < Rails::Generators::Base

    source_root File.join(File.dirname(__FILE__), 'templates')

    def manifest
      copy_file "20120104151700_create_messages.rb", "db/migrate/20120104151700_create_messages.rb"
    end
  end
end