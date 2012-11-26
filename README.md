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
------------

Using a template document, you should especify the expected area where each group is. By applying an edge detect algorithm
it will discover where the groups are, and will check if they are near the expected position. 
After the groups being found, the gem will perform a scan in each group in order to recognize their marks. 
In the end, returns a hash with each correspondent mark found in the group.

The gem will not perform deskew in your documents. If the document have a huge skew, then you should apply your own
deskew method on the file before.

```
NOTE:
We changed the way it recognizes the marks. It's not based on clocks anymore. If you are updating the gem 
from 0.1.4 version, you should refactor your code to eliminate the clocks parameters and adjust 
some new configurations.
```

Usage
-----

Unfortunatelly, this gem will require a bit more configuration to work, since the implementation depends 
a lot of your document sizes, positions, brightness, etc...

That said, lets describe it's basic structure. The example will assume a directory with some png images like this one:

[![Document Example](https://raw.github.com/andrerpbts/ruby_marks/master/assets/sheet_demo2.png)](https://github.com/andrerpbts/ruby_marks/blob/master/assets/sheet_demo2.png)


First, we will need to get the pixels coordinates, using one document as template, of the areas 
where the expected groups are. This image can explain where to pick each position:

[![Document Example](https://raw.github.com/andrerpbts/ruby_marks/master/assets/sheet_demo2_group_coords.png)](https://github.com/andrerpbts/ruby_marks/blob/master/assets/sheet_demo2_group_coords.png)


The threshold level should be adjusted too, in order to don't get a too bright or too polluted marks. See:

[![Document Example](https://raw.github.com/andrerpbts/ruby_marks/master/assets/threshold_examples.png)](https://github.com/andrerpbts/ruby_marks/blob/master/assets/threshold_examples.png)


Then, we write a basic code to scan it and print result on console (each option available are described bellow):

```ruby
# Instantiate the Recognizer 
recognizer = RubyMarks::Recognizer.new

# Configuring the document aspects
recognizer.configure do |config|
  config.threshold_level = 90
  config.default_expected_lines = 5

  config.define_group :first  do |group|
    group.expected_coordinates = {x1: 34, y1: 6, x2: 160, y2: 134}
  end

  config.define_group :second do |group| 
    group.expected_coordinates = {x1: 258, y1: 6, x2: 388, y2: 134}
  end

  config.define_group :third  do |group| 
    group.expected_coordinates = {x1: 486, y1: 6, x2: 614, y2: 134}
  end

  config.define_group :fourth do |group| 
    group.expected_coordinates = {x1: 714, y1: 6, x2: 844, y2: 134}
  end

  config.define_group :fifth  do |group| 
    group.expected_coordinates = {x1: 942, y1: 6, x2: 1068, y2: 134}
  end
end
```


Then we need to adjust the edge level to make sure the groups are being highlighted enough to being recognized. 
You can see the image after the edge algorithm is applied if you write the file after submit it to Recognizer. Like this:

```ruby
recognizer.file = 'example.png'
file = @recognizer.file
filename = "temp_image.png"
file.write(filename)
```

The result image should be like this one (note that all the groups are separated from the rest of the document these white blocks):

[![Document Example](https://raw.github.com/andrerpbts/ruby_marks/master/assets/sheet_demo2_edge.png)](https://github.com/andrerpbts/ruby_marks/blob/master/assets/sheet_demo2_edge.png)


There's a method you can call to will help you to identify how the document is being recognized. This method return the image
with the showing where is the expected groups coordinates are, where are the actual groups coordinates, and where the marks 
is being recognized in each group.

Example:

```ruby
flagged_document = recognizer.flag_all_marks
flagged_document.write(temp_filename)
```  

Will return the image below with recognized clock marks in green, the clock_marks_scan_x line in blue and
each mark position in a red cross:

[![Flagged Document Example](https://raw.github.com/andrerpbts/ruby_marks/master/assets/sheet_demo2_flagged.png)](https://github.com/andrerpbts/ruby_marks/blob/master/assets/sheet_demo2_flagged.png)


With all this configured, we can submit our images to a scan:

```ruby
# Read all documents in directory thats in a png format
Dir["./*.png"].each do |file|
  recognizer.file = file
  puts recognizer.scan
end
```

And, this should puts each scan in a hash, like this:

```
{
  first: { 
    1 => ['A'],
    2 => ['C'],
    3 => ['B'],
    4 => ['B'],
    5 => ['D']
  },
  second: {
    1 => ['E'],
    2 => ['A'],
    3 => ['B'],
    4 => ['A'],
    5 => ['B']
  },
  three: {
    1 => ['B'],    
    2 => ['B'],
    3 => ['D'], 
    4 => ['B'],    
    5 => ['B']
  },
  four: {
    1 => ['B'],
    2 => ['E'],    
    3 => ['A'],    
    4 => ['C'],    
    5 => ['D']
  },
  five: {
    1 => ['B'],
    2 => ['A'],
    3 => ['A'],
    4 => ['C'],
    5 => ['D']
  }
}
```



General Configuration Options
-----------------------------

As you may see, it's necessary configure some document aspects to make this work properly. So, lets describe
each general configuration option available:

### Edge level

```ruby
# The size of the edge to apply in the edge detect algorithm. 
# The default value is 4, but is very important you verify the algorithm result and adjust it to work.
config.edge_level = 4
```

### Threshold level 

```ruby
# Applies the given percentual in the image in order to get it back with only black and white pixels. 
# Low percentuals will result in a bright image, as High percentuals will result in a more darken image.
# The default value is 60, but is very important you verify the algorithm result and adjust it to work.

config.threshold_level = 60  
```

### Expected lines

```ruby
# The scan will raise the incorrect group watcher if one or more group don't have the expected number of lines
# Here, this configuration becomes valid to all groups.
# The default value is 20, but is very 

config.default_expected_lines = 20
```

### Default mark sizes

```ruby
# Defines the expected width and height of the marks (in pixels). With the tolerance, if the recognized 
# mark exceeds or stricts those values, it will be ignored.
# The default values is 20 to width and 20 to height. Since the marks can be different, you SHOULD
# calculate those sizes for your documents. 

config.default_mark_width = 20
config.default_mark_height = 20
```

### Default mark sizes tolerances

```ruby
# Defines the tolerance in width and height of the marks (in pixels). With the the mark size, if the recognized 
# mark exceeds or stricts those values, it will be ignored.
# The default values is 4 for both width and height. 

config.default_mark_width_tolerance = 4
config.default_mark_height_tolerance = 4
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
# This option is used to try suppose not found marks.
# The default value is 25

config.default_distance_between_marks = 25
```

###  Adjust bnconsistent bubbles
  
```ruby
# If true, it will perform an analysis in each group in order to see if there's more or less than expected bubbles, 
# an will try to remove or add these inconsistent marks.
# The default value is true

config.adjust_inconsistent_bubbles = true
```


Group Configuration Options
---------------------------

The General Configuration Options is more generic for the entire document. So, you can have some particularities
when defining a group. So:

### Expected coordinates

```ruby
# This configuration defines the area coordinate where the group is expected to be. 

group.expected_coordinates = {x1: 145, y1: 780, x2: 270, y2: 1290}
```

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

### Distance Between Marks

```ruby
# It overwrites the default_distance_between_marks values for the group you configure it. 

group.distance_between_marks = RubyMarks.default_distance_between_marks
```

### Expected lines

```ruby
# It overwrites the default_expected_lines values for the group you configure it. 

group.expected_lines = @recognizer.config.default_expected_lines
```


Watchers
--------

Sometimes, due some image flaws, the scan can't recognize some group, or a mark, or even recognize 
more than one mark in a clock row in the same group when it is not expected. Then, you can place some 
watchers, that will perform some custom code made by yourself in those cases, such applies a deskew 
in image and re-run the scan, for example. 
But, be advised, if you call the scan method again inside the watcher, you should make sure that you 
have a way to leave the watcher to avoid a endless loop. You always can check how many times the watcher 
got raised by checking in `recognizer.raised_watchers[:watcher_name]` hash.


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

### Scan Multiple Marked Watcher

```ruby
# Will execute your custom code if recognizes more than one mark in a clock row and the same group.
# It returns the recognizer object, the result of scan hash.

recognizer.add_watcher :scan_multiple_marked_watcher do |recognizer, result|
  # place your custom code 
end
```

### Incorrect Group Watcher

```ruby
# Will execute your custom code if didn't a group isn't found, or it have a line count different than expected,
# or in one or more lines the options marks found are different of the specified in marks options.
# It returns the recognizer object, a boolean value to incorrect expected lines count, and a hash with the 
# incorrect bubble lines found, and a hash with the coordinates of bubbles adjusted.
# Pay attention on incorrect_expected_lines and incorrect_bubble_line_found, because if some of this variables
# becomes present, then your document may have an incorrect result scan...

recognizer.add_watcher :incorrect_group_watcher do |recognizer, incorrect_expected_lines, incorrect_bubble_line_found, bubbles_adjusted|
  # place your custom code 
end
```

Contributing
------------

* Fork it
* Make your implementations
* Send me a pull request

Thank you!


License
-------

Copyright © 2012 André Rodrigues, Ronaldo Araújo, Rodrigo Virgilio, Lucas Correa. See MIT-LICENSE for further details.