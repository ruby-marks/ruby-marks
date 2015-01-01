module RubyMarks
  class FloodScan
    attr_reader :image, :node, :width, :height, :queue, :vector_x, :vector_y,
                :steps

    def initialize(image)
      @image = image
    end

    def scan(node, width, height)
      initialize_data(node, width, height)
      process_queue until queue.empty?
      define_max_frequencies

      if vector_x && vector_y
        {x1: vector_x[0][0], y1: vector_y[0][0], x2: vector_x[0][1], y2: vector_y[0][1]}
      else
        {}
      end
    end

    private

    def process_queue
      shift_node

      x = node.x
      y = node.y
      span_up = false;
      span_down = false;

      x -= 1 while target_is_previous_pixel?(x, y)

      while target_is_current_pixel?(x, y)
        image.store_pixels(x, y, 1, 1, [replacement])
        span_up = process_span_up(x, y, span_up)
        span_down = process_span_down(x, y, span_down)

        @vector_x[y] << x
        @vector_y[x] << y
        x += 1
        @steps += 1
      end

      queue.push(Magick::Point.new(x, y - 1)) if queue.empty? && steps < 100
    end

    def target_is_previous_pixel?(x, y)
      x > 0 && image.get_pixels(x - 1, y, 1, 1)[0] == target
    end

    def target_is_current_pixel?(x, y)
      x < image.columns && image.get_pixels(x, y, 1, 1)[0] == target
    end

    def process_span_up(x, y, span_up)
      pixel = y > 0 && image.get_pixels(x, y - 1, 1, 1)[0]
      if !span_up && pixel == target
        queue.push(Magick::Point.new(x, y - 1))
        span_up = true
      elsif span_up && pixel != target
        span_up = false
      end

      span_up
    end

    def process_span_down(x, y, span_down)
      pixel = y < image.rows - 1 && image.get_pixels(x, y + 1, 1, 1)[0]
      if !span_down && pixel == target
        queue.push(Magick::Point.new(x, y + 1))
        span_down = true
      elsif span_down && pixel != target
        span_down = false
      end

      span_down
    end

    def define_max_frequencies
      @vector_x = max_frequency_for(vector_x, width)
      @vector_y = max_frequency_for(vector_y, height)
    end

    def max_frequency_for(vector, measure)
      vector.find_mesure(measure, 5).max_frequency
    end

    def shift_node
      @node = queue.shift
    end

    def initialize_data(node, width, height)
      @node = node
      @width = width
      @height = height
      @steps = 0
      @vector_x = new_vector_hash
      @vector_y = new_vector_hash
      @queue = Array.new.push(node)
    end

    def new_vector_hash
      Hash.new { |hash, key| hash[key] = [] }
    end

    def target
      Magick::Pixel.new(65535, 65535, 65535, 0)
    end

    def replacement
      Magick::Pixel.new(0, 0, 0, 0)
    end
  end
end
