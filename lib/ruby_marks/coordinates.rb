require 'forwardable'

module RubyMarks
  class Coordinates
    extend Forwardable

    attr_accessor :x1, :y1, :x2, :y2

    def_delegators :to_h, :any?, :values_at

    def initialize(coords = {})
      @x1 = coords[:x1]
      @y1 = coords[:y1]
      @x2 = coords[:x2]
      @y2 = coords[:y2]
    end

    def width
      x2.to_i - x1.to_i + 1
    end

    def height
      y2.to_i - y1.to_i + 1
    end

    def middle_horizontal
      x1.to_i + width.to_i / 2
    end

    def middle_vertical
      y1.to_i + height.to_i / 2
    end

    def center
      { x: middle_horizontal, y: middle_vertical }
    end

    private

    def to_h
      {
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2
      }
    end
  end
end
