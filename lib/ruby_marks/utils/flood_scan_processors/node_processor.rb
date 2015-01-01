module RubyMarks
  module FloodScanProcessors
    class NodeProcessor
      attr_reader :flood_scan, :span_up, :span_down, :x, :y

      def initialize(flood_scan)
        @flood_scan = flood_scan
      end

      def process(node)
        initialize_data(node)

        go_to_previous_line while target_is_previous_pixel?
        while target_is_current_pixel?
          flood_line
          yield x, y
          @x += 1
        end
      end

      private

      def initialize_data(node)
        @span_up = false;
        @span_down = false;
        @x = node.x
        @y = node.y
      end

      def go_to_previous_line
        @x -= 1
      end

      def flood_line
        image.store_pixels(x, y, 1, 1, [replacement])
        do_span_up
        do_span_down
      end

      def target_is_previous_pixel?
        x > 0 && image.get_pixels(x - 1, y, 1, 1)[0] == target
      end

      def target_is_current_pixel?
        x < image.columns && image.get_pixels(x, y, 1, 1)[0] == target
      end

      def do_span_up
        pixel = y > 0 && image.get_pixels(x, y - 1, 1, 1)[0]
        @span_up = do_span(span_up, pixel, y - 1)
      end

      def do_span_down
        pixel = y < image.rows - 1 && image.get_pixels(x, y + 1, 1, 1)[0]
        @span_down = do_span(span_down, pixel, y + 1)
      end

      def do_span(span, pixel, y)
        case
        when !span && pixel == target
          queue.push(Magick::Point.new(x, y))
          true
        when span && pixel != target
          false
        else
          span
        end
      end

      def image
        flood_scan.image
      end

      def queue
        flood_scan.queue
      end

      def target
        Magick::Pixel.new(65535, 65535, 65535, 0)
      end

      def replacement
        Magick::Pixel.new(0, 0, 0, 0)
      end
    end
  end
end
