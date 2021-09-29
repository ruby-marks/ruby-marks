require 'forwardable'

module RubyMarks
  module Default
    class FindMarks
      extend Forwardable

      def initialize(group, image)
        @group = group
        @image = image
        @blocks = []
        @bubbles_adjusted = []
        @incorrect_bubble_line_found = Hash.new { |hash, key| hash[key] = [] }
      end

      def self.call(group, image, &blk)
        instance = new(group, image)
        instance.call(&blk)
      end

      def call(&blk)
        find_marks

        find_map_lines

        delete_conflicts

        verify_bubbles_adjust

        verify_incorrect_bubble_line
        
        if incorrect_bubble_line_found.any? || bubbles_adjusted.any? || incorrect_expected_lines
          yield incorrect_bubble_line_found, bubbles_adjusted
        end

        blocks
      end

      private
      
      def find_marks
        block = group.coordinates
        y = block.y1
        while y < block.y2
          x = block.x1
          while x < block.x2
            if image[y][x] == ' '
              x += 1
              next
            end

            result = find_in_blocks(x, y)
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

              blocks << result unless blocks.any? { |b| b == result }
            end
            x += 1
          end
          y += 1
        end
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

      def find_in_blocks(x, y)
        blocks.find do |result|
          result[:x1] <= x && result[:x2] >= x &&
            result[:y1] <= y && result[:y2] >= y
        end
      end

      def find_map_lines
        line = 0
        mark_ant = nil
        blocks.sort! { |a, b| a[:y1] <=> b[:y1] }

        blocks.each do |mark|
          mark_width  = ImageUtils.calc_width(mark[:x1], mark[:x2])
          mark_height = ImageUtils.calc_height(mark[:y1], mark[:y2])

          next unless mark_width >= group.mark_width_with_down_tolerance &&
                      mark_height >= group.mark_height_with_down_tolerance

          mark_positions = mark[:y1] - 10..mark[:y1] + 10
          line += 1 unless mark_ant && mark_positions.include?(mark_ant[:y1])
          mark[:line] = line
          mark_ant = mark
        end
        
        # remove marks not mapped
        blocks.delete_if { |m| m[:line].nil? }
        # sort by lines
        blocks.sort_by! { |a| [a[:line], a[:x1]] }
      end

      def delete_conflicts
        mark_ant = nil
        blocks.each do |mark|
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
        blocks.delete_if { |m| m[:conflict] }
      end

      def verify_bubbles_adjust
        first_position = 0
        elements_position_count = 0
        blocks.map { |m| m[:line] }.each do |dash|
          marks = blocks.select { |m| m[:line] == dash }
          if marks.count == group.marks_options.count
            first_position += marks.first[:x1]
            elements_position_count += 1
          end
        end

        if elements_position_count.positive?
          first_position /= elements_position_count
          distance = group.distance_between_marks * (group.marks_options.count - 1)
          last_position = first_position + distance
          blocks.delete_if do |mark|
            mark[:x1] < first_position - 10 ||
              mark[:x1] > last_position + 10
          end

          blocks.map { |m| m[:line] }.each do |dash|
            loop do
              reprocess = false
              marks = blocks.select { |m| m[:line] == dash }
              marks.each_with_index do |current_mark, index|
                if index.zero?
                  first_mark_position = first_position - 5..first_position + 5
                  unless first_mark_position.include?(current_mark[:x1])
                    new_mark = { x1: first_position,
                                x2: first_position + group.mark_width,
                                y1: current_mark[:y1],
                                y2: current_mark[:y1] + group.mark_height,
                                line: dash }
                    blocks << new_mark
                    blocks.sort_by! { |a| [a[:line], a[:x1]] }
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
                blocks << new_mark
                blocks.sort_by! { |a| [a[:line], a[:x1]] }
                bubbles_adjusted << new_mark
                reprocess = true
                break
              end
              break unless reprocess
            end
          end
        end
      end

      def verify_incorrect_bubble_line
        group.marks.each_pair do |dash, marks|
          if marks.count != group.marks_options.count
            incorrect_bubble_line_found[group.label.to_sym] << dash
          end
        end
      end

      attr_reader :group, :image
      attr_accessor :blocks, :bubbles_adjusted, :incorrect_bubble_line_found

      def_delegator :@group, :incorrect_expected_lines, :incorrect_expected_lines
    end
  end
end

