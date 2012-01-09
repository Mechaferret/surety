Surety
============

A lightweight guaranteed-delivery messaging system.


Dependency Notes
================

* Surety uses ActiveRecord to persist the message requests in order to provide transactional, guaranteed-delivery requests. Requires ActiveRecord 3.0.0 or higher.
* Surety uses Resque to underpin the message processing/retry loop. Requires Resque 1.19.0 or higher.


Usage / Examples
================

A simple class that can send a message for guaranteed delivery:

    class TestGenerator
      include Surety::Generator
    
      def some_method
        self.send_message(message_content)
      end
    end
    

On the server side, to start up the loop to process messages:

  Surety::Processor.request_next

    
Configuration
=============

Both the prefix for the ActiveRecord database connection name (as specified in database.yml) and the class to which Surety delegates messages for processing after pulling them off the queue are configurable.

Example configuration (from a sample config/initializers/surety.rb file)

Surety::Configuration.database_prefix = 'surety_'
Surety::Configuration.message_processing_delegate = MessageDistributor


Install
=======

### As a gem

    $ gem install surety


Acknowledgements
================

Copyright (c) 2012 Monica McArthur, released under the MIT license.

Thanks to Ryan and Steve for arguing that this gem was necessary... it is.
