Ruby Marks 
==========

[![Build Status](https://secure.travis-ci.org/andrerpbts/ruby_marks.png?branch=master)](http://travis-ci.org/andrerpbts/ruby_marks)

A simple OMR ([Optical Mark Recognition](http://en.wikipedia.org/wiki/Optical_mark_recognition)) gem for ruby 1.9.x.


Requirements
------------

This gem uses [ImageMagick](http://www.imagemagick.org) to manipulate the given images.
You can verify if this utility is installed by the command line `which convert`, which should return 
the current ImageMagick path.

For example, `/usr/local/bin/convert`.

If not installed:

### MacOS X

If you're on Mac OS X, Homebrew may be your best option:

    brew install imagemagick


### Ubuntu

On Ubuntu, the `apt-get` should be enough:
    
    apt-get install imagemagick


Install
-------

If you are using `Bundler`, just put this line in your Gemfile:

```ruby
gem 'ruby_marks'
```

Then run bundle install command:
    
    bundle

If not, you still can run a default gem installation method:
    
    gem install ruby_marks

And require it in your ruby code:

```ruby
require 'ruby_marks' 
```

Usage
-----

Unfortunatelly, this gem will require a bit more configuration to work, since the implementation depends 
a lot of your document sizes, positions, brightness, etc...

That said, lets describe it's basic structure. The example will assume this base document:

[![Document Example](https://github.com/andrerpbts/ruby_marks/blob/master/assets/sheet_demo1.png)](https://github.com/andrerpbts/ruby_marks/blob/master/assets/sheet_demo1.png)

Then a basic code to scan it properly:

```ruby
recognizer = RubyMarks::Recognizer.new
recognizer.configure do |config|

  config.clock_marks_scan_x = 42
  config.clock_width = 29
  config.clock_height = 12

  config.define_group :one do |group|
    group.clocks_range = 1..5
    group.x_distance_from_clock = 89
  end

  config.define_group :two do |group|
    group.clocks_range = 1..5
    group.x_distance_from_clock = 315
  end

  config.define_group :three do |group|
    group.clocks_range = 1..5
    group.x_distance_from_clock = 542
  end

  config.define_group :four do |group|
    group.clocks_range = 1..5
    group.x_distance_from_clock = 769
  end

  config.define_group :five do |group|
    group.clocks_range = 1..5
    group.x_distance_from_clock = 996
  end
end
```

Supported versions
------------------

* Ruby 1.9.2
* Ruby 1.9.3


