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

Also configurable are three parameters related to failure retries: 

* retry interval: base amount of time to wait before a retry, in minutes. Defaults to 10. 
* backoff factor: factor to divide the failure count by before calculating an exponential backoff. The backoff factor is (2^floor(failure count/backoff interval)). Defaults to 2.
* max backoff: maximum number of powers of 2 to backoff. Defaults to 7 (which gives a backoff factor of 128; together with the default retry interval of 10, this produces a default max backoff amount of 1280 minutes ~ 1 day).

Example configuration (from a sample config/initializers/surety.rb file)

    Surety::Configuration.database_prefix = 'surety_'
    Surety::Configuration.message_processing_delegate = MessageDistributor
    Surety::Configuration.retry_interval = 20
    Surety::Configuration.backoff_factor = 4
    Surety::Configuration.max_backoff = 5


Install
=======

### As a gem

    $ gem install surety


Acknowledgements
================

Copyright (c) 2012 Monica McArthur, released under the MIT license.

Thanks to Ryan and Steve for arguing that this gem was necessary... it is.
