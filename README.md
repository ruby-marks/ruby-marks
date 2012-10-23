Ruby Marks 
==========

A simple OMR ([Optical Mark Recognition](http://en.wikipedia.org/wiki/Optical_mark_recognition)) gem for ruby 1.9.x.


Requirements
------------

This gem uses ImageMagick[http://www.imagemagick.org] to manipulate the given images.
You can verify if this utility is installed by the command line `which convert`, which should return 
the actually current ImageMagick path.

For example, `/usr/local/bin/convert`.


== Install

If you are using +Bundler+, just put this line in your Gemfile:
```ruby
gem 'ruby_marks'
```

Then run bundle install command:
      % bundle

If not, you still run a default gem installation method:
      % gem install ruby_marks

And require it in your ruby code:
```ruby
  require 'ruby_marks' 
```

== Usage

Unfortunatelly, this gem will require a bit more configuration to work, since the implementation depends 
a lot of your document sizes, positions, brightness, etc...

That said, lets describe the basic structure you may have on your code:


== Supported versions

* Ruby 1.9.2
* Ruby 1.9.3

== Build Status [![Build Status](http://travis-ci.org/andrerpbts/ruby_marks)]

