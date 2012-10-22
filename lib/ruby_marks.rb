require 'rubygems'
require 'RMagick'
require 'ruby_marks/version'
require 'ruby_marks/support'


module RubyMarks
  mattr_accessor :threshold_level
  @@threshold_level = 60

  mattr_accessor :clock_mark_size_tolerance
  @@clock_mark_size_tolerance = 2

  mattr_accessor :expected_clocks_count
  @@expected_clocks_count = 0

  mattr_accessor :clock_marks_scan_x
  @@clock_marks_scan_x = 62

  mattr_accessor :clock_width
  @@clock_width = 26

  mattr_accessor :recognition_colors
  @@recognition_colors = ["#000000"]

  mattr_accessor :clock_height
  @@clock_height = 12

  mattr_accessor :default_mark_width
  @@default_mark_width = 20

  mattr_accessor :default_mark_height
  @@default_mark_height = 20

  mattr_accessor :intensity_percentual
  @@intensity_percentual = 50

  mattr_accessor :default_marks_options
  @@default_marks_options = %w{A B C D E}

  mattr_accessor :default_distance_between_marks
  @@default_distance_between_marks = 25

  COLORS = %w{ #d80000 #00d8d8 #d8006c #d86c00 #006cd8 #00d86c #d8d800 #00d86c #6c00d8 #a5a500
               #a27b18 #18a236 #df4f27 }

  AVAILABLE_WATCHERS = [
    :scan_mark_watcher,
    :scan_unmarked_watcher,
    :scan_multiple_marked_watcher,
    :clock_mark_difference_watcher
  ]
end

require 'ruby_marks/clock_mark'
require 'ruby_marks/config'
require 'ruby_marks/group'
require 'ruby_marks/image_utils'
require 'ruby_marks/recognizer'
require 'ruby_marks/watcher'