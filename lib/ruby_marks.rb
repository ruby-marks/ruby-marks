require 'rubygems'
require 'RMagick'
require 'sane_timeout'
require 'ruby_marks/version'
require 'ruby_marks/support'


module RubyMarks
  mattr_accessor :edge_level
  @@edge_level = 4

  mattr_accessor :threshold_level
  @@threshold_level = 60

  mattr_accessor :scan_timeout
  @@scan_timeout = 0

  mattr_accessor :adjust_inconsistent_bubbles
  @@adjust_inconsistent_bubbles = true

  mattr_accessor :default_mark_width_tolerance
  @@default_mark_width_tolerance = 4

  mattr_accessor :default_mark_height_tolerance
  @@default_mark_height_tolerance = 4

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

  mattr_accessor :default_expected_lines
  @@default_expected_lines = 20

  COLORS = %w{ #d80000 
               #00d8d8 
               #d8006c 
               #d86c00 
               #006cd8 
               #00d86c 
               #d8d800 
               #00d86c 
               #6c00d8 
               #a5a500
               #a27b18 
               #18a236 
               #df4f27 }

  AVAILABLE_WATCHERS = [
    :scan_mark_watcher,
    :scan_unmarked_watcher,
    :scan_multiple_marked_watcher,
    :incorrect_group_watcher,
    :timed_out_watcher
  ]
end

require 'ruby_marks/config'
require 'ruby_marks/group'
require 'ruby_marks/image_utils'
require 'ruby_marks/mark'
require 'ruby_marks/recognizer'
require 'ruby_marks/scan_area'
require 'ruby_marks/watcher'