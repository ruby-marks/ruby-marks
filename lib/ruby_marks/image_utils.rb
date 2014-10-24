#encoding: utf-8
module RubyMarks

  class ImageUtils

    def self.calc_width(x1, x2)
      x2.to_i - x1.to_i + 1
    end

    def self.calc_height(y1, y2)
      y2.to_i - y1.to_i + 1
    end

    def self.calc_middle_horizontal(x, width)
      x.to_i + width.to_i / 2
    end

    def self.calc_middle_vertical(y, height)
      y.to_i + height.to_i / 2
    end

    def self.image_center(coordinates)
      width  = self.calc_width(coordinates[:x1], coordinates[:x2])
      height = self.calc_height(coordinates[:y1], coordinates[:y2])

      x = self.calc_middle_horizontal(coordinates[:x1], width)
      y = self.calc_middle_vertical(coordinates[:y1], height)
      return {x: x, y: y}
    end


    def self.flood_scan(image, x, y, character=" ", coordinates={})
      coordinates = {x1: 0, y1: 0, x2: image[0].size, y2: image.size} unless coordinates.any?
      result_mask =  Hash.new { |hash, key| hash[key] = [] }
      result_mask.tap do |result_mask|
        process_queue =  Hash.new { |hash, key| hash[key] = [] }
        process_line = true

        loop do

          break if y > coordinates[:y2] - 1 || y < coordinates[:y1]
          reset_process = false

          if process_line
            current_x = x
            loop do
              position = image[y][current_x]

              break if position != character || current_x - 1 <= coordinates[:x1]
              process_queue[y] << current_x unless process_queue[y].include?(current_x) || result_mask[y].include?(current_x)
              result_mask[y] << current_x unless result_mask[y].include?(current_x)
              current_x = current_x - 1
            end

            current_x = x.to_i
            loop do
              position = image[y][current_x]

              break if position != character || current_x + 1 >= coordinates[:x2]
              process_queue[y] << current_x unless process_queue[y].include?(current_x) || result_mask[y].include?(current_x)
              result_mask[y] << current_x unless result_mask[y].include?(current_x)
              current_x = current_x + 1
            end

            result_mask[y] = result_mask[y].sort
            process_queue[y] = process_queue[y].sort
          end

          process_line = true

          process_queue[y].each do |element|
            if y - 1 >= coordinates[:y1]
              position = image[y-1][element]

              if position == character && !result_mask[y-1].include?(element)
                x = element
                y = y - 1
                reset_process = true
                break
              end
            end
          end

          next if reset_process

          process_queue[y].each do |element|
            if y + 1 <= coordinates[:y2]
              position = image[y+1] && image[y+1][element]

              if position && position == character && !result_mask[y+1].include?(element)
                x = element
                y = y + 1
                reset_process = true
                break
              else
                process_queue[y].delete(element)
              end

            end
          end

          next if reset_process

          process_queue.each do |k,v|
            process_queue.delete(k) if v.empty?
          end

          break if process_queue.empty?

          process_line = false
          y = process_queue.first[0] if process_queue.first.is_a?(Array)
        end
      end
    end


    def self.to_hex(red, green, blue)
      red = get_hex_from_color(red)
      green = get_hex_from_color(green)
      blue = get_hex_from_color(blue)
      "##{red}#{green}#{blue}".upcase
    end


    def self.export_file_to_str(file)
      image = file.export_pixels_to_str
      image = image.gsub!(Regexp.new('\xFF\xFF\xFF', nil, 'n'), " ,") if image
      image = image.gsub!(Regexp.new('\x00\x00\x00', nil, 'n'), ".,") if image
      image = image.split(',') if image
      image = image.each_slice(file.page.width).to_a  if image
    end


    private
    def self.get_hex_from_color(color)
      color = color.to_s(16)[0..1]
      color.size < 2 ? "0#{color}" : color
    end

  end

end
