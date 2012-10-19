#encoding: utf-8
module RubyMarks
  
  class Recognizer
    
    attr_reader   :file

    attr_accessor :current_position, :clock_marks, :config, :groups

    def initialize
      @current_position = {x: 0, y: 0}
      @clock_marks = []
      @groups = {}       
      self.create_config
    end

    def file=(file)
      @current_position = {x: 0, y: 0}
      @clock_marks = []

      @file = nil
      @file = Magick::Image.read(file).first
      @file = @file.threshold(@config.calculated_threshold_level)
    end

    def create_config
      @config ||= RubyMarks::Config.new(self)
    end

    def filename
      @file && @file.filename
    end

    def configure(&block)
      self.create_config
      @config.configure(&block) 
    end

    def add_group(group)
      @groups[group.label] = group if group
    end

    def move_to(x, y)
      @current_position = {x: @current_position[:x] + x, y: @current_position[:y] + y}
    end

    def marked?(expected_width, expected_height)
      raise IOError, "There's a invalid or missing file" if @file.nil?
      
      if self.current_position

        neighborhood_x = current_position[:x]-2..current_position[:x]+2
        neighborhood_y = current_position[:y]-2..current_position[:y]+2

        neighborhood_y.each do |current_y|
          neighborhood_x.each do |current_x|

            color = @file.pixel_color(current_x, current_y)
            color = RubyMarks::ImageUtils.to_hex(color.red, color.green, color.blue)            

            if @config.recognition_colors.include?(color)
              stack = flood_scan(current_x, current_y)

              x_elements = []
              y_elements = []
              stack.each do |k,v|
                stack[k].inject(x_elements, :<<)
                y_elements << k
              end

              x_elements.sort!.uniq!
              y_elements.sort!.uniq!

              x1 = x_elements.first || 0
              x2 = x_elements.last  || 0
              y1 = y_elements.first || 0
              y2 = y_elements.last  || 0 

              current_width  = RubyMarks::ImageUtils.calc_width(x1, x2)
              current_height = RubyMarks::ImageUtils.calc_height(y1, y2)

              if current_width >= expected_width + 2
                distance_x1 = current_x - x1
                distance_x2 = x2 - current_x

                if distance_x1 <= distance_x2
                  x2 = x1 + expected_width 
                else
                  x1 = x2 - expected_width 
                end
                current_width  = RubyMarks::ImageUtils.calc_width(x1, x2)
              end


              if current_height >= expected_height + 2
                distance_y1 = current_y - y1
                distance_y2 = y2 - current_y

                if distance_y1 <= distance_y2
                  y2 = y1 + expected_height 
                else
                  y1 = y2 - expected_height  
                end
                current_height = RubyMarks::ImageUtils.calc_height(y1, y2)                
              end

              if (current_width  >= expected_width  - 4 && current_width  <= expected_width  + 4) &&
                 (current_height >= expected_height - 4 && current_height <= expected_height + 4) 

                colors = []

                x_pos = x1..x2
                y_pos = y1..y2

                y_pos.each do |y|
                  x_pos.each do |x|
                    color = @file.pixel_color(x, y)
                    color = RubyMarks::ImageUtils.to_hex(color.red, color.green, color.blue)
                    color = @config.recognition_colors.include?(color) ? "." : " "
                    colors << color
                  end
                end

                intensity = colors.count(".") * 100 / colors.size
                return true if intensity >= @config.intensity_percentual
              end
            end
         
          end
        end
      end

      return false
    end

    def unmarked?(x_pos, y_pos)
      !marked?(x_pos, y_pos)
    end

    def scan
      raise IOError, "There's a invalid or missing file" if @file.nil?

      result = {}
      result.tap do |result|
        position_before = @current_position
        scan_clock_marks unless clock_marks.any?
    
        clock_marks.each_with_index do |clock_mark, index|
          group_hash = {}
          @groups.each do |key, group|
            if group.belongs_to_clock?(index + 1)
              @current_position = {x: clock_mark.coordinates[:x2], y: clock_mark.vertical_middle_position}
              move_to(group.x_distance_from_clock, 0)
              markeds = []
              group.marks_options.each do |mark|
                markeds << mark if marked?(group.mark_width, group.mark_height)
                move_to(group.distance_between_marks, 0)
              end
              group_hash["group_#{key}".to_sym] = markeds if markeds.any?
            end
          end
          result["clock_#{index+1}".to_sym] = group_hash if group_hash.any?
        end
        @current_position = position_before
      end
    end

    def flag_position

      raise IOError, "There's a invalid or missing file" if @file.nil?

      file = @file.dup

      file.tap do |file|
        if current_position
          add_mark file
        end
      end
    end

    def flag_all_marks

      raise IOError, "There's a invalid or missing file" if @file.nil?

      file = @file.dup

      file.tap do |file|
        position_before = @current_position
    
        scan_clock_marks unless clock_marks.any?
        clock_marks.each_with_index do |clock, index|
          dr = Magick::Draw.new
          dr.fill(RubyMarks::COLORS[5])
          dr.rectangle(clock.coordinates[:x1], clock.coordinates[:y1], clock.coordinates[:x2], clock.coordinates[:y2])
          dr.draw(file)
        end

        clock_marks.each_with_index do |clock_mark, index|
          @groups.each do |key, group|
            if group.belongs_to_clock?(index + 1)            
              @current_position = {x: clock_mark.coordinates[:x2], y: clock_mark.vertical_middle_position}
              move_to(group.x_distance_from_clock, 0)
              group.marks_options.each do |mark|
                add_mark file
                move_to(group.distance_between_marks, 0)
              end
            end
          end
        end

        @current_position = position_before
      end
    end

    def scan_clock_marks

      raise IOError, "There's a invalid or missing file" if @file.nil?

      @clock_marks = []
      x = @config.clock_marks_scan_x
      total_height = @file && @file.page.height || 0
      @clock_marks.tap do |clock_marks|
        current_y = 0
        loop do 

          break if current_y > total_height

          color = @file.pixel_color(x, current_y)
          color = RubyMarks::ImageUtils.to_hex(color.red, color.green, color.blue)
          
          if @config.recognition_colors.include?(color)
            stack = flood_scan(x, current_y)

            x_elements = []
            y_elements = []
            stack.each do |k,v|
              stack[k].inject(x_elements, :<<)
              y_elements << k
            end

            x_elements.sort!.uniq!
            y_elements.sort!.uniq!
            last_y = y_elements.last

            loop do
              stack_modified = false


              x_elements.each do |col|
                element_count = 0
                y_elements.each do |row|
                  element_count += 1 if stack[row].include?(col)
                end

                if element_count > 0 && element_count < self.config.clock_height_with_down_tolerance
                  current_width = RubyMarks::ImageUtils.calc_width(x_elements.first, x_elements.last)                
                  middle = RubyMarks::ImageUtils.calc_middle_horizontal(x_elements.first, current_width)      

                  x_elements.delete_if do |el|
                    col <= middle && el <= col || col >= middle && el >= col
                  end

                  stack_modified = true
                end
              end

              y_elements.each do |row|
                if stack[row].count < self.config.clock_width_with_down_tolerance
                  current_height = RubyMarks::ImageUtils.calc_height(y_elements.first, y_elements.last)
                  middle = RubyMarks::ImageUtils.calc_middle_vertical(y_elements.first, current_height)

                  y_elements.delete_if do |ln|
                    row <= middle  && ln <= row || row >= middle && ln >= row 
                  end   

                  stack_modified = true
                end
              end

              break unless stack_modified
            end

            x1 = x_elements.first || 0
            x2 = x_elements.last  || 0
            y1 = y_elements.first || 0
            y2 = y_elements.last  || 0 
          end

          clock = RubyMarks::ClockMark.new(recognizer: self, coordinates: {x1: x1, x2: x2, y1: y1, y2: y2})

          if clock.valid?
            clock_marks << clock
            current_y = last_y
          end

          current_y += 1
        end
      end
    end

    def flood_scan(x, y)
      result_mask =  Hash.new { |hash, key| hash[key] = [] }
      result_mask.tap do |result_mask|
        process_queue =  Hash.new { |hash, key| hash[key] = [] }
        process_line = true
        
        loop do
          reset_process = false

          if process_line
            current_x = x.to_i
            loop do
              color = self.file.pixel_color(current_x, y)
              color = RubyMarks::ImageUtils.to_hex(color.red, color.green, color.blue)

              break if !self.config.recognition_colors.include?(color) || current_x - 1 <= 0            
              process_queue[y] << current_x unless process_queue[y].include?(current_x) || result_mask[y].include?(current_x) 
              result_mask[y] << current_x unless result_mask[y].include?(current_x)            
              current_x = current_x - 1
            end

            current_x = x.to_i
            loop do
              color = self.file.pixel_color(current_x, y)
              color = RubyMarks::ImageUtils.to_hex(color.red, color.green, color.blue)

              break if !self.config.recognition_colors.include?(color) || current_x + 1 >= self.file.page.width            
              process_queue[y] << current_x unless process_queue[y].include?(current_x) || result_mask[y].include?(current_x)              
              result_mask[y] << current_x unless result_mask[y].include?(current_x)
              current_x = current_x + 1
            end

            result_mask[y] = result_mask[y].sort
            process_queue[y] = process_queue[y].sort
          end

          process_line = true

          process_queue[y].each do |element|
            if y - 1 >= 0
              color = self.file.pixel_color(element.to_i, y-1)
              color = RubyMarks::ImageUtils.to_hex(color.red, color.green, color.blue)     
              if self.config.recognition_colors.include?(color) && !result_mask[y-1].include?(element)
                x = element
                y = y - 1
                reset_process = true
                break
              end
            end
          end

          next if reset_process

          process_queue[y].each do |element|         
            if y + 1 <= self.file.page.height
              color = self.file.pixel_color(element.to_i, y+1)
              color = RubyMarks::ImageUtils.to_hex(color.red, color.green, color.blue)
              if self.config.recognition_colors.include?(color) && !result_mask[y+1].include?(element)
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

    private
    def add_mark(file)
      dr = Magick::Draw.new
      dr.annotate(file, 0, 0, current_position[:x]-9, current_position[:y]+11, "+") do
        self.pointsize = 30
        self.fill = '#900000'
      end
      
      dr = Magick::Draw.new
      dr.fill = '#FF0000'
      dr.point(current_position[:x], current_position[:y])
      dr.point(current_position[:x] + 1, current_position[:y])  
      dr.point(current_position[:x], current_position[:y] + 1)   
      dr.point(current_position[:x] + 1, current_position[:y] + 1)             
      dr.draw(file)
    end

 

  end

end