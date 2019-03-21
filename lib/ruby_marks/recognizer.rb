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
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/BlockNesting
    def detect_groups
      if @config.scan_mode == :grid
        scanner = FloodScan.new(@file.dup)
        @groups.each_pair do |_label, group|
          group_center = group.expected_coordinates.center
          x = group_center[:x]
          y = group_center[:y]
          width = group.expected_coordinates.width
          height = group.expected_coordinates.height
          block = scanner.scan(Magick::Point.new(x, y), width, height)
          if !block.empty?
            group.coordinates = Coordinates.new(block)
            marks_blocks = find_marks_grid(group)
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
          else
            @groups_not_detected << group.label
          end
        end
      else
        file_str = ImageUtils.export_file_to_str(@file)
        original_file_str = ImageUtils.export_file_to_str(@original_file)
        incorrect_bubble_line_found = Hash.new { |hash, key| hash[key] = [] }
        bubbles_adjusted = []
        incorrect_expected_lines = false

        @groups.each_pair do |_label, group|
          next unless group.expected_coordinates.any?

          line = 0
          group_center = group.expected_coordinates.center

          block = find_block_marks(file_str, group_center[:x], group_center[:y], group)
          next unless block

          group.coordinates = Coordinates.new(block)
          marks_blocks = find_marks(original_file_str, group)
          marks_blocks.sort! { |a, b| a[:y1] <=> b[:y1] }
          mark_ant = nil
          marks_blocks.each do |mark|
            mark_width  = ImageUtils.calc_width(mark[:x1], mark[:x2])
            mark_height = ImageUtils.calc_height(mark[:y1], mark[:y2])

            next unless mark_width >= group.mark_width_with_down_tolerance &&
                        mark_height >= group.mark_height_with_down_tolerance

            mark_positions = mark[:y1] - 10..mark[:y1] + 10
            line += 1 unless mark_ant && mark_positions.include?(mark_ant[:y1])
            mark[:line] = line
            mark_ant = mark
          end

          marks_blocks.delete_if { |m| m[:line].nil? }
          marks_blocks.sort_by! { |a| [a[:line], a[:x1]] }

          mark_ant = nil
          marks_blocks.each do |mark|
            if mark_ant && mark_ant[:line] == mark[:line]
              mark_ant_center = ImageUtils.image_center(mark_ant)
              mark_center     = ImageUtils.image_center(mark)
              if (mark_ant_center[:x] - mark_center[:x]).abs < 10
                mark[:conflict] = true
                mark[:conflicting_mark] = mark_ant
              else
                mark_ant = mark
              end
            else
              mark_ant = mark
            end
          end
          marks_blocks.delete_if { |m| m[:conflict] }

          first_position = 0
          elements_position_count = 0
          marks_blocks.map { |m| m[:line] }.each do |dash|
            marks = marks_blocks.select { |m| m[:line] == dash }
            if marks.count == group.marks_options.count
              first_position += marks.first[:x1]
              elements_position_count += 1
            end
          end

          if elements_position_count.positive?
            first_position /= elements_position_count
            distance = group.distance_between_marks * (group.marks_options.count - 1)
            last_position = first_position + distance
            marks_blocks.delete_if do |mark|
              mark[:x1] < first_position - 10 ||
                mark[:x1] > last_position + 10
            end

            marks_blocks.map { |m| m[:line] }.each do |dash|
              loop do
                reprocess = false
                marks = marks_blocks.select { |m| m[:line] == dash }
                marks.each_with_index do |current_mark, index|
                  if index.zero?
                    first_mark_position = first_position - 5..first_position + 5
                    unless first_mark_position.include?(current_mark[:x1])
                      new_mark = { x1: first_position,
                                   x2: first_position + group.mark_width,
                                   y1: current_mark[:y1],
                                   y2: current_mark[:y1] + group.mark_height,
                                   line: dash }
                      marks_blocks << new_mark
                      marks_blocks.sort_by! { |a| [a[:line], a[:x1]] }
                      bubbles_adjusted << new_mark
                      reprocess = true
                      break
                    end
                  end
                  next_mark = marks[index + 1]
                  distance = 0
                  distance = next_mark[:x1] - current_mark[:x1] if next_mark
                  next unless distance > group.distance_between_marks + 10 ||
                              next_mark.nil? && index + 1 < group.marks_options.count

                  new_x1 = current_mark[:x1] + group.distance_between_marks
                  new_mark = { x1: new_x1,
                               x2: new_x1 + group.mark_width,
                               y1: current_mark[:y1],
                               y2: current_mark[:y1] + group.mark_height,
                               line: dash }
                  marks_blocks << new_mark
                  marks_blocks.sort_by! { |a| [a[:line], a[:x1]] }
                  bubbles_adjusted << new_mark
                  reprocess = true
                  break
                end
                break unless reprocess
              end
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
            group.marks[mark[:line]] << o_mark if mark[:line] <= group.expected_lines
          end

          incorrect_expected_lines = group.incorrect_expected_lines

          group.marks.each_pair do |dash, marks|
            if marks.count != group.marks_options.count
              incorrect_bubble_line_found[group.label.to_sym] << dash
            end
          end
        end
        @groups_detected = true
        if incorrect_bubble_line_found.any? || bubbles_adjusted.any? || incorrect_expected_lines
          raise_watcher :incorrect_group_watcher,
                    incorrect_expected_lines, incorrect_bubble_line_found, bubbles_adjusted.flatten
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/BlockNesting

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/BlockNesting
    def find_block_marks(image, x, y, group)
      expected_coordinates = group.expected_coordinates
      found_blocks = []
      expected_width  = expected_coordinates.width
      expected_height = expected_coordinates.height
      block = nil
      while x <= expected_coordinates.x2 && y <= expected_coordinates.y2
        if image[y] && image[y][x] == ' '
          block = find_in_blocks(found_blocks, x, y)
          unless block
            block = find_block(image, x, y)
            found_blocks << block

            block[:width]  = ImageUtils.calc_width(block[:x1], block[:x2])
            block[:height] = ImageUtils.calc_height(block[:y1], block[:y2])

            if @config.scan_mode == :grid
              unless block[:width] <= (expected_width + group.block_width_tolerance) &&
                     block[:width] >= (expected_width - group.block_width_tolerance)

                if block[:width] > expected_width + group.block_width_tolerance
                  ajust_width = block[:width] - expected_width
                  if @config.auto_ajust_block_width == :left
                    block[:x2] = (block[:x2] - ajust_width) + @config.edge_level
                    block[:width] = expected_width + @config.edge_level
                  elsif @config.auto_ajust_block_width == :right
                    block[:x1] = (block[:x1] + ajust_width) - @config.edge_level
                    block[:width] = expected_width + @config.edge_level
                  end
                else
                  block[:width] = 0
                end
              end
              unless block[:height] <= (expected_height + group.block_height_tolerance) &&
                     block[:height] >= (expected_height - group.block_height_tolerance)

                if block[:height] > expected_height + group.block_height_tolerance
                  ajust_width = block[:height] - expected_height
                  if @config.auto_ajust_block_height == :top
                    block[:y2] = (block[:y2] - ajust_height) + @config.edge_level
                    block[:height] = expected_height + @config.edge_level
                  elsif @config.auto_ajust_block_height == :bottom
                    block[:y1] = (block[:y1] + ajust_height) - @config.edge_level
                    block[:height] = expected_height + @config.edge_level
                  end
                else
                  block[:height] = 0
                end
              end
            end

            block_width_with_tolerance  = block[:width]  + group.block_width_tolerance
            block_height_with_tolerance = block[:height] + group.block_height_tolerance

            return block if block_width_with_tolerance >= expected_width &&
                            block_height_with_tolerance >= expected_height
          end
        end

        x += 1
        y += 1
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/BlockNesting

    def find_marks_grid(group)
      block = group.coordinates
      blocks = []
      blocks.tap do |chunks|
        lines   = group.expected_lines
        columns = group.marks_options.size
        distance_lin = group.mark_height
        distance_col = group.mark_width
        lines.times do |lin|
          columns.times do |col|
            chunks << { x1: block.x1 + (col * distance_col),
                        y1: block.y1 + (lin * distance_lin),
                        x2: block.x1 + (col * distance_col) + distance_col,
                        y2: block.y1 + (lin * distance_lin) + distance_lin,
                        line: lin + 1 }
          end
        end
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/BlockNesting
    def find_marks(image, group)
      block = group.coordinates
      y = block.y1
      blocks = []
      blocks.tap do |chunks|
        while y < block.y2
          x = block.x1
          while x < block.x2
            if image[y][x] == ' '
              x += 1
              next
            end

            result = find_in_blocks(chunks, x, y)
            unless result
              result = find_block(image, x, y, '.', block)

              mark_width  = ImageUtils.calc_width(*result.values_at(:x1, :x2))
              mark_height = ImageUtils.calc_height(*result.values_at(:y1, :y2))

              if mark_width > group.mark_width_with_up_tolerance
                distance_x1 = x - result[:x1]
                distance_x2 = result[:x2] - x
                if distance_x1 <= distance_x2
                  result[:x2] = result[:x1] + group.mark_width
                else
                  result[:x1] = result[:x2] - group.mark_width
                end
              end

              if mark_height > group.mark_height_with_up_tolerance
                distance_y1 = y - result[:y1]
                distance_y2 = result[:y2] - y
                if distance_y1 <= distance_y2
                  result[:y2] = result[:y1] + group.mark_height
                else
                  result[:y1] = result[:y2] - group.mark_height
                end
              end

              chunks << result unless chunks.any? { |b| b == result }

            end
            x += 1
          end
          y += 1
        end
      end
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

    def find_block(image, x, y, character = ' ', coordinates = {})
      stack = ImageUtils.flood_scan(image, x, y, character, coordinates)

      x_elements = []
      y_elements = []
      stack.each do |k, _v|
        stack[k].inject(x_elements, :<<)
        y_elements << k
      end

      x_elements.sort!.uniq!
      y_elements.sort!.uniq!

      x1 = x_elements.first || 0
      x2 = x_elements.last  || 0
      y1 = y_elements.first || 0
      y2 = y_elements.last  || 0

      { x1: x1, x2: x2, y1: y1, y2: y2 }
    end

    def find_in_blocks(blocks, x, y)
      blocks.find do |result|
        result[:x1] <= x && result[:x2] >= x &&
          result[:y1] <= y && result[:y2] >= y
      end
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
