module RubyMarks
  module Grid
    class FindMarks

      def initialize(group)
        @group = group
      end

      def self.call(group)
        new(group).call
      end

      def call
        find_marks
      end

      private

      def find_marks
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
      
      attr_reader :group
    end
  end
end
