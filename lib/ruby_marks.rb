require 'rubygems'
require 'RMagick'
require 'timeout'
require 'ruby_marks/version'
require 'ruby_marks/support'


module RubyMarks
  mattr_accessor :edge_level
  @@edge_level = 4

  mattr_accessor :threshold_level
  @@threshold_level = 60

  mattr_accessor :scan_timeout
  @@scan_timeout = 0

  mattr_accessor :default_block_width_tolerance
  @@default_block_width_tolerance = 100

  mattr_accessor :default_block_height_tolerance
  @@default_block_height_tolerance = 100

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

class Array
  def to_ranges
    compact.sort.uniq.inject([]) do |r,x|
      r.empty? || r.last.last.succ != x ? r << [x,x] : r[0..-2] << [r.last.first, x]
    end
  end

  def max_frequency
    group_by{ |w| w }
    .map{ |w, v| [w, v.size] }
    .max { |a, b| a[1] <=> b[1] }
  end
end

class Hash
  def find_mesure(measure, tolerance)
    ax = []
    each do |k, v|
      max = v.max { |a, b| a <=> b }
      min = v.min { |a, b| a <=> b }
      ax << [min, max] if max - min >= measure - tolerance && max - min <= measure + tolerance 
    end
    ax  
  end
end

require 'ruby_marks/config'
require 'ruby_marks/group'
require 'ruby_marks/image_utils'
require 'ruby_marks/mark'
require 'ruby_marks/recognizer'
require 'ruby_marks/watcher'
require 'ruby_marks/flood_scan'