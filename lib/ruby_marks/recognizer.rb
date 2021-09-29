require 'forwardable'

module RubyMarks
  # rubocop:disable Metrics/ClassLength
  class Recognizer
    extend Forwardable

    def_delegator :config, :configure
    attr_reader   :file, :raised_watchers, :groups, :watchers, :file_str, :original_file_str
    attr_accessor :config, :groups_detected, :groups_not_detected

    def initialize
      reset_document
      @groups = {}
      @groups_not_detected = []
      @config ||= Config.new(self)
    end

    def file=(file)
      reset_document
      @file = nil
      @file_str = nil
      @original_file = nil
      @original_file_str = nil

      @file = Magick::Image.read(file).first
      @file = @file.quantize(256, Magick::GRAYColorspace)
      @file = @file.threshold(@config.calculated_threshold_level)
      @original_file = @file
      @file = @file.edge(@config.edge_level)
      @groups_detected = false

      @groups.each_pair do |_label, group|
        group.marks = nil
        group.marks = Hash.new { |hash, key| hash[key] = [] }
      end
    end

    def reset_document
      @current_position = { x: 0, y: 0 }
      @clock_marks = []
      @raised_watchers = {}
      @watchers = {}
    end

    def filename
      @file&.filename
    end

    def add_group(group)
      @groups[group.label] = group if group
    end

    def add_watcher(watcher_name, &block)
      watcher = Watcher.new(watcher_name, self, &block)
      @watchers[watcher.name] = watcher if watcher
    end

    def raise_watcher(name, *args)
      watcher = @watchers[name]
      return unless watcher

      @raised_watchers[watcher.name] ||= 0
      @raised_watchers[watcher.name]  += 1
      watcher.run(*args)
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def scan
      raise IOError, "There's a invalid or missing file" if @file.nil?

      unmarked_group_found  = false
      multiple_marked_found = false

      result = Hash.new { |hash, key| hash[key] = [] }
      result.tap do |effect|
        begin
          Timeout.timeout(@config.scan_timeout) do
            detect_groups unless @groups_detected
            detect_mark_blocks
          end
        rescue Timeout::Error
          raise_watcher :timed_out_watcher
          return effect
        end

        @groups.each_pair do |_label, group|
          marks = Hash.new { |hash, key| hash[key] = [] }
          group.marks.each_pair do |line, value|
            value.each do |mark|
              marks[line] << mark.value if mark.marked?(config.intensity_percentual) && mark.value
            end

            multiple_marked_found = true if marks[line].size > 1
            unmarked_group_found  = true if marks[line].empty?
          end

          effect[group.label.to_sym] = marks
        end

        raise_watcher :scan_unmarked_watcher, effect if unmarked_group_found

        raise_watcher :scan_multiple_marked_watcher, effect if multiple_marked_found

        if unmarked_group_found || multiple_marked_found
          raise_watcher :scan_mark_watcher, effect, unmarked_group_found, multiple_marked_found
        end
      end
    end

    def detect_mark_blocks
      original_file_str = ImageUtils.export_file_to_str(@original_file) unless config.scan_mode == :grid

      groups.each_pair do |label, group|
         marks_blocks = if config.scan_mode == :grid
            Grid::FindMarks.call(group)
          else
            Default::FindMarks.call(group, original_file_str) do |incorrect_bubble_line_found, bubbles_adjusted|
              raise_watcher :incorrect_group_watcher,
                group.incorrect_expected_lines, incorrect_bubble_line_found, bubbles_adjusted.flatten
            end
          end
          
        marks_blocks.each do |mark|
          mark_width  = ImageUtils.calc_width(mark[:x1], mark[:x2])
          mark_height = ImageUtils.calc_height(mark[:y1], mark[:y2])
          mark_file = @original_file.crop(mark[:x1], mark[:y1], mark_width, mark_height)
          o_mark = Mark.new group: group,
                            coordinates: coordinate(mark),
                            image_str: ImageUtils.export_file_to_str(mark_file),
                            line: mark[:line]

          group.marks[mark[:line]] << o_mark
        end
      end
    end

    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/BlockNesting


    def detect_groups
      scanner = FloodScan.new(@file.dup)
      @groups.each_pair do |_label, group|
        group_center = group.expected_coordinates.center
        x = group_center[:x]
        y = group_center[:y]
        width = group.expected_coordinates.width
        height = group.expected_coordinates.height
        block = scanner.scan(Magick::Point.new(x, y), width, height)

        if block.any?
          group.coordinates = Coordinates.new(block)
        else
          @groups_not_detected << group.label
        end
      end
      @groups_detected = true
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/BlockNesting

    def flag_position(position)
      raise IOError, "There's a invalid or missing file" if @file.nil?

      files = @original_file.dup

      files.tap do |file|
        add_mark(file, position)
      end
    end

    # rubocop:disable Metrics/MethodLength
    def flag_all_marks
      raise IOError, "There's a invalid or missing file" if @file.nil?

      @original_file.dup.tap do |file|
        begin
          Timeout.timeout(@config.scan_timeout) do
            detect_groups unless @groups_detected
          end
        rescue Timeout::Error
          raise_watcher :timed_out_watcher
          return file
        end

        @groups.each_pair do |_label, group|
          dr = Magick::Draw.new
          dr.stroke_width = 5
          dr.stroke(COLORS[3])
          dr.line(*group.expected_coordinates.values_at(:x1, :y1, :x2, :y1))
          dr.line(*group.expected_coordinates.values_at(:x2, :y1, :x2, :y2))
          dr.line(*group.expected_coordinates.values_at(:x2, :y2, :x1, :y2))
          dr.line(*group.expected_coordinates.values_at(:x1, :y2, :x1, :y1))
          dr.draw(file)

          next unless group.coordinates

          dr = Magick::Draw.new
          dr.stroke_width = 5
          dr.stroke(COLORS[5])
          dr.line(*group.coordinates.values_at(:x1, :y1, :x2, :y1))
          dr.line(*group.coordinates.values_at(:x2, :y1, :x2, :y2))
          dr.line(*group.coordinates.values_at(:x2, :y2, :x1, :y2))
          dr.line(*group.coordinates.values_at(:x1, :y2, :x1, :y1))
          dr.draw(file)
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    private

    def coordinate(mark)
      {
        x1: mark[:x1],
        y1: mark[:y1],
        x2: mark[:x2],
        y2: mark[:y2]
      }
    end

    # rubocop:disable Metrics/MethodLength
    def add_mark(file, position, mark = nil)
      dr = Magick::Draw.new
      if @config.scan_mode == :grid
        x = position[:x] - 9
        y = position[:y] + 5
        intensity = mark.intensity ? mark.intensity.ceil.to_s : '+'

        dr.annotate(file, 0, 0, x, y, intensity) do
          self.pointsize = 15
          self.fill = COLORS[2]
        end

        dr = Magick::Draw.new
        dr.stroke_width = 2
        dr.stroke(COLORS[1])

        dr.line(*mark.coordinates.values_at(:x1, :y1, :x2, :y1))
        dr.line(*mark.coordinates.values_at(:x2, :y1, :x2, :y2))
        dr.line(*mark.coordinates.values_at(:x2, :y2, :x1, :y2))
        dr.line(*mark.coordinates.values_at(:x1, :y2, :x1, :y1))
      else
        dr.annotate(file, 0, 0, position[:x] - 9, position[:y] + 11, '+') do
          self.pointsize = 30
          self.fill = '#900000'
        end

        dr = Magick::Draw.new
        dr.fill = '#FF0000'
        dr.point(position[:x], position[:y])
        dr.point(position[:x], position[:y] + 1)
        dr.point(position[:x] + 1, position[:y])
        dr.point(position[:x] + 1, position[:y] + 1)
      end

      dr.draw(file)
    end
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Metrics/ClassLength
end
