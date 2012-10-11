require 'rubygems'
require 'RMagick'
require 'ruby_marks/version'
require 'ruby_marks/support'

magick_version = `convert -version`

if magick_version =~ /Q16/ 
  puts %{
    *** IMPORTANT: You are running the ImageMagick under 16bits quantum depth. This configuration is used
        in very specific cases and can cause RMagick work a bit slow. See more details in this forum post
        http://rubyforge.org/forum/forum.php?thread_id=10975&forum_id=1618 ***
  }
end

module RubyMarks
  mattr_accessor :clock_marks_scan_x
  @@clock_marks_scan_x = 62

  mattr_accessor :intensity_percentual
  @@intensity_percentual = 40

  mattr_accessor :recognition_colors
  @@recognition_colors = ["#000000"]

  mattr_accessor :default_marks_options
  @@default_marks_options = %w{A B C D E}

  mattr_accessor :default_distance_between_marks
  @@default_distance_between_marks = 25

  mattr_accessor :clock_width
  @@clock_width = 26

  mattr_accessor :clock_height
  @@clock_height = 12
end

require 'ruby_marks/document'
require 'ruby_marks/config'
require 'ruby_marks/clock_mark'
require 'ruby_marks/group'
require 'ruby_marks/rgb'
