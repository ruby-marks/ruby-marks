#encoding: utf-8
module RubyMarks
  
  # Represents a scanned document
  class Document

    attr_reader :file

    attr_accessor :current_position, :clock_marks, :config, :groups

    def initialize(file)
      @file = Magick::Image.read(file).first
      @file = @file.threshold(Magick::QuantumRange * 0.55)
      @current_position = {x: 0, y: 0}
      @clock_marks = []
      @groups = {} 
      self.create_config
      @gc = Magick::Draw.new
    end

    def create_config
      @config ||= RubyMarks::Config.new(self)
    end

    def filename
      @file.filename
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

    def marked?
      if self.current_position
        area_x = 8
        area_y = 8

        x_pos = current_position[:x]-area_x..current_position[:x]+area_x
        y_pos = current_position[:y]-area_y..current_position[:y]+area_y

        colors = []

        y_pos.each do |y|
          x_pos.each do |x|
            color = @file.pixel_color(x, y)
            color = RubyMarks::RGB.to_hex(color.red, color.green, color.blue)
            color = @config.recognition_colors.include?(color) ? "." : " "
            colors << color
          end
        end
        intensity = colors.count(".") * 100 / colors.size
        return intensity >= @config.intensity_percentual ? true : false
      end
    end

    def unmarked?
      !marked?
    end

    def scan
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
                markeds << mark if marked?
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
      file = @file.dup

      file.tap do |file|
        if current_position
          add_mark file
        end
      end
    end

    def flag_all_marks
      file = @file.dup

      file.tap do |file|
        position_before = @current_position
    
        scan_clock_marks unless clock_marks.any?
        clock_marks.each do |clock|
          @gc.fill('red')
          @gc.rectangle(clock.coordinates[:x1], clock.coordinates[:y1], clock.coordinates[:x2], clock.coordinates[:y2])
          @gc.draw(file)
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
      @clock_marks = []
      x = @config.clock_marks_scan_x
      in_clock = false
      total_height = @file && @file.page.height || 0
      @clock_marks.tap do |clock_marks| 
        total_height.times do |y|
          clock = {}
          color = @file.pixel_color(x, y)
          color = RubyMarks::RGB.to_hex(color.red, color.green, color.blue)
          if !in_clock && @config.recognition_colors.include?(color)
            clock = RubyMarks::ClockMark.new(document: self, position: {x: x, y: y})
            if clock.valid?
              in_clock = true
              clock_marks << clock
            end
          elsif in_clock && !@config.recognition_colors.include?(color)
            in_clock = false
          end        
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
            current_x = x
            loop do
              color = self.file.pixel_color(current_x, y)
              color = RubyMarks::RGB.to_hex(color.red, color.green, color.blue)

              break if !self.config.recognition_colors.include?(color) || current_x - 1 <= 0            
              process_queue[y] << current_x unless process_queue[y].include?(current_x) || result_mask[y].include?(current_x) 
              result_mask[y] << current_x unless result_mask[y].include?(current_x)            
              current_x = current_x - 1
            end

            current_x = x
            loop do
              color = self.file.pixel_color(current_x, y)
              color = RubyMarks::RGB.to_hex(color.red, color.green, color.blue)

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
              color = self.file.pixel_color(element, y-1)
              color = RubyMarks::RGB.to_hex(color.red, color.green, color.blue)     
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
              color = self.file.pixel_color(element, y+1)
              color = RubyMarks::RGB.to_hex(color.red, color.green, color.blue)
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
      @gc.annotate(file, 0, 0, current_position[:x]-9, current_position[:y]+11, "+") do
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