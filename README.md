Surety
============

A lightweight guaranteed-delivery messaging system.


Usage / Examples
================

A simple class that can send a message for guaranteed delivery:

    class TestGenerator
      include Surety::Generator
    
      def some_method
        self.send_message(message_content)
      end
    end


Install
=======

### As a gem

    $ gem install surety


Acknowledgements
================

Copyright (c) 2012 Monica McArthur, released under the MIT license.

Thanks to Ryan and Steve for arguing that this gem was necessary... it is.
