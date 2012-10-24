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


Supported versions
------------------

* Ruby 1.9.2
* Ruby 1.9.3


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


How it Works
============

The gem will scan a document column search for this small full-filled black rectangles **(clock marks)**. 
For each clock mark found, it will perform a line scan in each group looking for a marked position. 
In the end, returns a hash with each correspondent mark found in the group and the clock.

The gem will not perform deskew in your documents. If the document have skew, then you should apply your own
deskew method on the file before.


Usage
-----

Unfortunatelly, this gem will require a bit more configuration to work, since the implementation depends 
a lot of your document sizes, positions, brightness, etc...

That said, lets describe it's basic structure. The example will assume a directory with some png images like this one:

[![Document Example](https://raw.github.com/andrerpbts/ruby_marks/master/assets/sheet_demo2.png)](https://github.com/andrerpbts/ruby_marks/blob/master/assets/sheet_demo2.png)

Then, we write a basic code to scan it and print result on console:

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

Dir["./*.png"].each do |file|
  recognizer.file = file
  puts recognizer.scan
end
```

This should puts each scan in a hash, like this:

```
{
  :clock_1 => {
    :group_one   => ['A'],
    :group_two   => ['E'],
    :group_three => ['B'],
    :group_four  => ['B'],
    :group_five  => ['B']
  },
  :clock_2 => {
    :group_one   => ['C'],
    :group_two   => ['A'],
    :group_three => ['B'],
    :group_four  => ['E'],
    :group_five  => ['A']
  },
  :clock_3 => {
    :group_one   => ['B'],
    :group_two   => ['B'],
    :group_three => ['D'],
    :group_four  => ['A'],
    :group_five  => ['A']
  },
  :clock_4 => {
    :group_one   => ['B'],
    :group_two   => ['A'],
    :group_three => ['B'],
    :group_four  => ['C'],
    :group_five  => ['C']
  },
  :clock_5 => {
    :group_one   => ['D'],
    :group_two   => ['B'],
    :group_three => ['B'],
    :group_four  => ['D'],
    :group_five  => ['D']
  }
}
```


General Configuration Options
=============================

As you may see, it's necessary configure some document aspects to make this work properly. So, lets describe
each general configuration option available:

### Threshold level 

```ruby
# Applies the given percentual in the image in order to get it back with only black and white pixels. 
# Low percentuals will result in a bright image, as High percentuals will result in a more darken image.
# The default value is 60

config.threshold_level = 60  
```

### Distance in axis X from margin to scan the clock marks

```ruby
# Defines the X distance from the left margin (in pixels) to look for the valids (black) pixels
# of the clock marks in this column. This configuration is very important because each type of document may
# have the clock marks in a specific and different column, and this configuration that will indicate 
# a X pixel column that cross all the clocks.
# The default value is 62 but only for tests purposes. You SHOULD calculate this value and set
# a new one.

config.clock_marks_scan_x = 62
```

### Clock sizes

```ruby
# Defines the expected width and height of clock marks (in pixels). With the tolerance, if the first recognized clock exceeds
# or stricts those values, it will be ignored...
# The default values is 26 to width and 12 to height. Since the clock marks can be different, you SHOULD
# calculate those sizes for your documents. 

config.clock_width = 26
config.clock_height = 12
```

### Tolerance on the size of clock mark

```ruby
# Indicates the actual tolerance (in pixels) for the clock mark found. That means the clock can be smaller or 
# larger than expected, by the number of pixels set in this option.
# The default value is 2

config.clock_mark_size_tolerance = 2
```

### Expected clocks count

```ruby
# If this value is defined (above 0), the scan will perform a check if the clocks found on document
# is identical with this expected number. If different, the scan will be stopped.
# This config is mandatory if you want to raise the Clock Mark Difference Watcher.
# The default value is 0

config.expected_clocks_count = 0
```

### Default mark sizes

```ruby
# Defines the expected width and height of the marks (in pixels). With the tolerance, if the first recognized mark exceeds
# or stricts those values, it will be ignored.
# The default values is 20 to width and 20 to height. Since the marks can be different, you SHOULD
# calculate those sizes for your documents. 

config.default_mark_width = 20
config.default_mark_height = 20
```

### Intensity percentual

```ruby
# Set the intensity sensitivity (in percentual) expected to recognize a mark as a marked one. 
# When the scan find some potential marked area, then it will analyse if the count of valid pixels (black pixels)
# have this minimun percentage.
# Increasing this value, the recognition becomes more sensitive and can ignore valid weaker markings. 
# Decreasing this value, recognition becomes less sensitive and can recognize false markings.
# The default value is 50. 

config.intensity_percentual = 50
```

### Default marks options

```ruby
# Set the marks options that the groups represents. When the scan recognizes a mark in some position,
# it will return they value in the result hash.
# The default value is the [A, B, C, D, E] array.

config.default_marks_options = %w{A B C D E}
```

### Default distance between each mark in group

```ruby
# Defines the distance (in pixel) between the middle of a mark and the middle of the next mark in the same group.
# The scan will begin in the first mark, by the value in pixels it have from the right corner of the clock.
# After it, each mark option in the group will be checked based in this distance.
# The default value is 25

config.default_distance_between_marks = 25
```


Group Configuration Options
===========================

The General Configuration Options is more generic for the entire document. So, you can have some particularities
when defining a group. So:

### Mark sizes

```ruby
# It overwrites the default_mark_width and default_mark_height values for the group you configure it. 

group.mark_width  = RubyMarks.default_mark_width
group.mark_height = RubyMarks.default_mark_height
```

### Marks options

```ruby
# It overwrites the default_marks_options values for the group you configure it. 

group.marks_options = RubyMarks.default_marks_options
```

### Distance in axis X from clock

```ruby
# Defines the distance from the right corner of the clock mark to the middle of the first mark in the group
# It don't have a default value, you MUST set this value for each group in your document

group.x_distance_from_clock = 89
```

### Distance Between Marks

```ruby
# It overwrites the default_distance_between_marks values for the group you configure it. 

group.distance_between_marks = RubyMarks.default_distance_between_marks
```

### Clocks range

```ruby
# Defines the clock ranges this group belongs to. This range that will consider what clock mark
# should be returned in the result of the scan.

group.clocks_range = 1..5   
```


Watchers
========

Sometimes, due some image flaws, the scan can't recognize some clock mark, or a mark, or even recognize 
more than one mark in a clock row in the same group when it is not expected. Then, you can place some 
watchers, that will perform some custom code made by yourself in those cases. The available watchers are:
In the watchers you can, for example, apply a deskew in image and re-run the scan. But, be advised, if you 
call the scan method again inside the watcher, you should make sure that you have a way to leave the watcher
to avoid a endless loop. You always can check how many times the watcher got raised by checking in 
`recognizer.raised_watchers[:watcher_name]` hash.


### Scan Mark Watcher

```ruby
# Will execute your custom code if didn't recognizes some mark or recognizes more than one mark in a clock
# row and the same group.  
# It returns the recognizer object, the result of scan hash, a boolean value if this watcher was raised by unmarked
# options and a boolean value if the watcher was raised by a multiple marks options

recognizer.add_watcher :scan_mark_watcher do |recognizer, result, unmarked_group_found, multiple_marked_found|
  # place your custom code 
end
```

### Scan Unmarked Watcher

```ruby
# Will execute your custom code if didn't recognizes some mark.
# It returns the recognizer object, the result of scan hash.

recognizer.add_watcher :scan_unmarked_watcher do |recognizer, result|
  # place your custom code 
end
```

### Scan Multiple Makerd Watcher

```ruby
# Will execute your custom code if recognizes more than one mark in a clock row and the same group.
# It returns the recognizer object, the result of scan hash.

recognizer.add_watcher :scan_multiple_marked_watcher do |recognizer, result|
  # place your custom code 
end
```

### Clock Mark Difference Watcher

```ruby
# Will execute your custom code if didn't recognizes your expected clock marks count.
# In order to raise this watcher you must define the `config.expected_clocks_count`.
# It returns the recognizer object.

recognizer.add_watcher :clock_mark_difference_watcher do |recognizer|
  # place your custom code 
end
```

Contributing
------------

* Fork it
* Make your implementations
* Send me a pull request


License
-------

Copyright © 2012 André Rodrigues, Ronaldo Araújo, Rodrigo Virgilio, Lucas Correa. See MIT-LICENSE for further details.