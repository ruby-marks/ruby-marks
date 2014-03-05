module RubyMarks

  class FloodScan

    def scan(image, node, width, height)
      target = Magick::Pixel.new(65535, 65535, 65535, 0) 
      replacement = Magick::Pixel.new(0, 0, 0, 0)
      queue = Array.new
      queue.push(node) 
      vx = Hash.new { |hash, key| hash[key] = [] }
      vy = Hash.new { |hash, key| hash[key] = [] }
      steps = 0
      until queue.empty?
        node = queue.shift
        x = node.x
        y = node.y
        span_up = false;
        span_down = false;
        while x > 0 && image.get_pixels(x - 1, y, 1, 1)[0] == target
          x -= 1
        end
        while x < image.columns && image.get_pixels(x, y, 1, 1)[0] == target
          image.store_pixels(x, y, 1, 1, [replacement]) 
          if !span_up && y > 0 && image.get_pixels(x, y - 1, 1, 1)[0] == target
            queue.push(Magick::Point.new(x, y - 1))
            span_up = true
          elsif span_up && y > 0 && image.get_pixels(x, y - 1, 1, 1)[0] != target
            span_up = false
          end
          if !span_down && y < image.rows - 1 && image.get_pixels(x, y + 1, 1, 1)[0] == target
            queue.push(Magick::Point.new(x, y + 1))
            span_down = true
          elsif span_down && y < image.rows - 1 && image.get_pixels(x, y + 1, 1, 1)[0] != target
            span_down = false
          end
          vx[y] << x 
          vy[x] << y
          x += 1
          steps += 1
        end
        queue.push(Magick::Point.new(x, y - 1)) if queue.empty? && steps < 100 
      end
      vx = vx.find_mesure(width, 5).max_frequency
      vy = vy.find_mesure(height, 5).max_frequency
      if vx && vy
        {x1: vx[0][0], y1: vy[0][0], x2: vx[0][1], y2: vy[0][1]}
      else
        {}
      end
    end
  end

end