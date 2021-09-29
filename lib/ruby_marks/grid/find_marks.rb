require 'forwardable'

module RubyMarks
  module Grid
    class FindMarks
      extend Forwardable

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
        lines.times.map do |lin|
          columns.times.map do |col|
            {
              x1: block.x1 + (col * distance_col),
              y1: block.y1 + (lin * distance_lin),
              x2: block.x1 + (col * distance_col) + distance_col,
              y2: block.y1 + (lin * distance_lin) + distance_lin,
              line: lin + 1
            }
          end
        end.flatten
      end

      attr_reader :group

      def_delegator :@group, :coordinates, :block
      def_delegator :@group, :expected_lines, :lines
      def_delegator :@group, :expected_columns, :columns
      def_delegator :@group, :mark_height, :distance_lin
      def_delegator :@group, :mark_width, :distance_col
      def_delegator :@group, :marks_options, :marks_options
    end
  end
end
