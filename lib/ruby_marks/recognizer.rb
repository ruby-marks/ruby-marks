#encoding: utf-8
module RubyMarks
  
  class Recognizer
    
    attr_reader   :file, :raised_watchers, :groups, :watchers, :file_str, :original_file_str
    attr_accessor :config, :groups_detected


    def initialize
      self.reset_document
      @groups = {}     
      self.create_config
    end


    def file=(file)
      self.reset_document
      @file = nil
      @file_str = nil
      @file = Magick::Image.read(file).first
      @file = @file.quantize(256, Magick::GRAYColorspace)     
      @file = @file.threshold(@config.calculated_threshold_level) 
      @original_file = @file
      @file = @file.edge(@config.edge_level)
      @groups_detected = false

      @groups.each_pair do |label, group|
        group.marks = Hash.new { |hash, key| hash[key] = [] }
      end        
    end


    def reset_document
      @current_position = {x: 0, y: 0}
      @clock_marks = []
      @raised_watchers = {}
      @watchers = {} 
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


    def add_watcher(watcher_name, &block)
      watcher = RubyMarks::Watcher.new(watcher_name, self, &block)
      @watchers[watcher.name] = watcher if watcher
    end


    def raise_watcher(name, *args)
      watcher = @watchers[name]
      if watcher
        @raised_watchers[watcher.name] ||= 0
        @raised_watchers[watcher.name]  += 1 
        watcher.run(*args)
      end
    end


    def scan
      raise IOError, "There's a invalid or missing file" if @file.nil?
      
      unmarked_group_found  = false
      multiple_marked_found = false

      result = Hash.new { |hash, key| hash[key] = [] }
      result.tap do |result|
 
        begin 
          Timeout.timeout(@config.scan_timeout) do
            self.detect_groups unless @groups_detected 
          end        
        rescue Timeout::Error
          raise_watcher :timed_out_watcher
        end       

        @groups.each_pair do |label, group|        
          marks = Hash.new { |hash, key| hash[key] = [] }
          group.marks.each_pair do |line, value|
            value.each do |mark|
              marks[line] << mark.value if mark.marked?
            end

            multiple_marked_found = true if marks[line].size > 1            
            unmarked_group_found  = true if marks[line].empty?
          end

          result[group.label.to_sym] = marks 
        end

        raise_watcher :scan_unmarked_watcher, result if unmarked_group_found
        raise_watcher :scan_multiple_marked_watcher, result if multiple_marked_found    
        raise_watcher :scan_mark_watcher, result, unmarked_group_found, multiple_marked_found if unmarked_group_found || multiple_marked_found    
      end
    end


    def detect_groups    
      file_str = RubyMarks::ImageUtils.export_file_to_str(@file)
      original_file_str = RubyMarks::ImageUtils.export_file_to_str(@original_file)
      incorrect_bubble_line_found = Hash.new { |hash, key| hash[key] = [] }
      bubbles_adjusted = []
      incorrect_expected_lines = false

      @groups.each_pair do |label, group|
        next unless group.expected_coordinates.any?

        group_center = RubyMarks::ImageUtils.image_center(group.expected_coordinates)

        block = find_block_marks(file_str, group_center[:x], group_center[:y], group.expected_coordinates)

        if block
          group.coordinates = {x1: block[:x1], x2: block[:x2], y1: block[:y1], y2: block[:y2]}

          marks_blocks = find_marks(original_file_str, group)
          positions = []
          marks_blocks.each do |mark|
            line = 0
            mark_width  = RubyMarks::ImageUtils.calc_width(mark[:x1], mark[:x2])
            mark_height = RubyMarks::ImageUtils.calc_height(mark[:y1], mark[:y2])
            
            if mark_width  >= group.mark_width_with_down_tolerance  && 
               mark_width  <= group.mark_width_with_up_tolerance    &&
               mark_height >= group.mark_height_with_down_tolerance && 
               mark_height <= group.mark_height_with_up_tolerance

              group.marks.each_pair do |key, marks_array|
                mark_positions = mark[:y1]-10..mark[:y1]+10

                marks_array.each do |m|
                  if mark_positions.include?(m.coordinates[:y1])
                    line = key
                    break
                  end
                end 

                break if line > 0
              end

              line = group.marks.size + 1 if line == 0

              conflict_marks = group.marks[line].select do |el|
                el.coordinates[:x2] >= mark[:x1] && el.coordinates[:x2] <= mark[:x2]  ||
                el.coordinates[:x1] >= mark[:x1] && el.coordinates[:x1] <= mark[:x2]
              end

              if conflict_marks.any?
                conflict_marks.each do |conflict_mark|
                  group.marks[line].delete(conflict_mark)
                end
              else
                mark_file = @original_file.crop(mark[:x1], mark[:y1], mark_width, mark_height)

                mark = RubyMarks::Mark.new group: group, 
                                           coordinates: {x1: mark[:x1], y1: mark[:y1], x2: mark[:x2], y2: mark[:y2]},
                                           image_str: RubyMarks::ImageUtils.export_file_to_str(mark_file),
                                           line: line

                group.marks[line] << mark
                group.marks[line].sort! { |a, b| a.coordinates[:x1] <=> b.coordinates[:x1] }
              end
            end
          end
          
          first_position  = 0
          elements_position_count = 0
          group.marks.each_pair do |line, marks|

            if marks.count == group.marks_options.count && 
               marks.first && marks.first.coordinates

              first_position += marks.first.coordinates[:x1]

              elements_position_count += 1
            end
          end

          if @config.adjust_inconsistent_bubbles && elements_position_count > 0
            first_position = first_position / elements_position_count
            distance = group.distance_between_marks * (group.marks_options.count - 1)
            last_position  = first_position + distance

            group.marks.each_pair do |line, marks|
              loop do
                reprocess = false
                marks.each_with_index do |current_mark, index|
                  if current_mark.coordinates[:x1] < first_position - 10 ||
                     current_mark.coordinates[:x1] > last_position  + 10

                    group.marks[line].delete(current_mark)
                    reprocess = true
                    bubbles_adjusted << current_mark.coordinates
                    break 

                  else

                    if index == 0 
                      first_mark_position = first_position-5..first_position+5
                      unless first_mark_position.include?(current_mark.coordinates[:x1])
                        new_mark_x1 = first_position
                        new_mark_x2 = new_mark_x1 + group.mark_width
                        new_mark_y1 = current_mark.coordinates[:y1]
                        new_mark_y2 = new_mark_y1 + group.mark_height
                        reprocess = true
                      end                      
                    end

                    unless reprocess
                      next_mark = marks[index + 1]
                      distance = 0
                      distance = next_mark.coordinates[:x1] - current_mark.coordinates[:x1] if next_mark

                      if distance > group.distance_between_marks + 10 || 
                         next_mark.nil? && index + 1 < group.marks_options.count 
                        new_mark_x1 = current_mark.coordinates[:x1] + group.distance_between_marks
                        new_mark_x2 = new_mark_x1 + group.mark_width
                        new_mark_y1 = current_mark.coordinates[:y1]
                        new_mark_y2 = new_mark_y1 + group.mark_height
                      end
                    end

                    if new_mark_x1 && new_mark_x2 && new_mark_y1 && new_mark_y2
                      mark_width  = RubyMarks::ImageUtils.calc_width(new_mark_x1, new_mark_x2)
                      mark_height = RubyMarks::ImageUtils.calc_height(new_mark_y1, new_mark_y2)

                      mark_file = @original_file.crop(new_mark_x1, new_mark_y1, mark_width, mark_height)

                      current_mark = RubyMarks::Mark.new group: group, 
                                                         coordinates: {x1: new_mark_x1, y1: new_mark_y1, x2: new_mark_x2, y2: new_mark_y2},
                                                         image_str: RubyMarks::ImageUtils.export_file_to_str(mark_file),
                                                         line: line

                      group.marks[line] << current_mark
                      group.marks[line].sort! { |a, b| a.coordinates[:x1] <=> b.coordinates[:x1] }
                      reprocess = true
                      bubbles_adjusted << current_mark.coordinates
                      break
                    end
                  end
                  break if reprocess
                end
                break unless reprocess
              end

              incorrect_expected_lines = true if group.incorrect_expected_lines
            end
          end

          group.marks.each_pair do |line, marks|
            if marks.count != group.marks_options.count 
              incorrect_bubble_line_found[group.label.to_sym] << line
            end
          end
        end
      end  
      @groups_detected = true
      if incorrect_bubble_line_found.any? || bubbles_adjusted.any? || incorrect_expected_lines 
        raise_watcher :incorrect_group_watcher, incorrect_expected_lines, incorrect_bubble_line_found, bubbles_adjusted.flatten 
      end
    end


    def find_block_marks(image, x, y, expected_coordinates)
      found_blocks = []
      expected_width  = RubyMarks::ImageUtils.calc_width(expected_coordinates[:x1], expected_coordinates[:x2])
      expected_height = RubyMarks::ImageUtils.calc_height(expected_coordinates[:y1], expected_coordinates[:y2]) 
      block = nil
      while x <= expected_coordinates[:x2] && y <= expected_coordinates[:y2]
        if image[y] && image[y][x] == " "
          block = find_in_blocks(found_blocks, x, y)
          unless block       
            block = find_block(image, x, y)
            found_blocks << block
            
            block[:width]  = RubyMarks::ImageUtils.calc_width(block[:x1], block[:x2]) 
            block[:height] = RubyMarks::ImageUtils.calc_height(block[:y1], block[:y2])                       

            block_width_with_tolerance  = block[:width]  + 100
            block_height_with_tolerance = block[:height] + 100


            return block if block_width_with_tolerance >= expected_width && 
                            block_height_with_tolerance >= expected_height

          end
        end

        x += 1 
        y += 1
      end
    end


    def find_marks(image, group)
      block = group.coordinates
      y = block[:y1]
      blocks = []
      blocks.tap do |blocks|
        while y < block[:y2]
          x = block[:x1]
          while x < block[:x2] do          
            if image[y][x] == " "
              x += 1
              next 
            end

            result = find_in_blocks(blocks, x, y)
            unless result
              result = find_block(image, x, y, ".", block)

              mark_width  = RubyMarks::ImageUtils.calc_width(result[:x1], result[:x2])
              mark_height = RubyMarks::ImageUtils.calc_height(result[:y1], result[:y2])


              if mark_width > group.mark_width_with_up_tolerance  
                distance_x1 = x - result[:x1]
                distance_x2 = result[:x2] - x
                if distance_x1 <= distance_x2
                  result[:x2] = result[:x1] + group.mark_width_with_up_tolerance - 2
                else
                  result[:x1] = result[:x2] - group.mark_width_with_up_tolerance + 2
                end
              end            

              if mark_height > group.mark_height_with_up_tolerance  
                distance_y1 = y - result[:y1]
                distance_y2 = result[:y2] - y
                if distance_y1 <= distance_y2
                  result[:y2] = result[:y1] + group.mark_height_with_up_tolerance - 2
                else
                  result[:y1] = result[:y2] - group.mark_height_with_up_tolerance + 2 
                end           
              end

              blocks << result
            end
            x += 1
          end
          y += 1
        end
      end
    end


    def flag_position(position)
      raise IOError, "There's a invalid or missing file" if @file.nil?

      file = @original_file.dup

      file.tap do |file|
        add_mark file, position
      end
    end


    def flag_all_marks
      raise IOError, "There's a invalid or missing file" if @file.nil?
      
      file = @original_file.dup

      file.tap do |file|

        begin 
          Timeout.timeout(@config.scan_timeout) do
            self.detect_groups unless @groups_detected 
          end        
        rescue Timeout::Error
          raise_watcher :timed_out_watcher
        end  

        @groups.each_pair do |label, group|  

          dr = Magick::Draw.new
          dr.stroke_width = 5
          dr.stroke(RubyMarks::COLORS[3])
          dr.line(group.expected_coordinates[:x1], group.expected_coordinates[:y1], group.expected_coordinates[:x2], group.expected_coordinates[:y1])
          dr.line(group.expected_coordinates[:x2], group.expected_coordinates[:y1], group.expected_coordinates[:x2], group.expected_coordinates[:y2])
          dr.line(group.expected_coordinates[:x2], group.expected_coordinates[:y2], group.expected_coordinates[:x1], group.expected_coordinates[:y2])  
          dr.line(group.expected_coordinates[:x1], group.expected_coordinates[:y2], group.expected_coordinates[:x1], group.expected_coordinates[:y1])                  
          dr.draw(file)

          if group.coordinates 
            dr = Magick::Draw.new
            dr.stroke_width = 5
            dr.stroke(RubyMarks::COLORS[5])         
            dr.line(group.coordinates[:x1], group.coordinates[:y1], group.coordinates[:x2], group.coordinates[:y1])
            dr.line(group.coordinates[:x2], group.coordinates[:y1], group.coordinates[:x2], group.coordinates[:y2])
            dr.line(group.coordinates[:x2], group.coordinates[:y2], group.coordinates[:x1], group.coordinates[:y2])  
            dr.line(group.coordinates[:x1], group.coordinates[:y2], group.coordinates[:x1], group.coordinates[:y1])                  
            dr.draw(file)
          end

          marks = Hash.new { |hash, key| hash[key] = [] }
          group.marks.each_pair do |line, value|
            value.each do |mark|
              add_mark file, RubyMarks::ImageUtils.image_center(mark.coordinates)
            end
          end
        end 
      end
    end


    private
    def find_block(image, x, y, character=" ", coordinates={})
      stack = RubyMarks::ImageUtils.flood_scan(image, x, y, character, coordinates)

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

      {x1: x1, x2: x2, y1: y1, y2: y2}
    end


    def find_in_blocks(blocks, x, y)
      blocks.find do |result|
        result[:x1] <= x && result[:x2] >= x && 
        result[:y1] <= y && result[:y2] >= y   
      end
    end

    def add_mark(file, position)
      dr = Magick::Draw.new
      dr.annotate(file, 0, 0, position[:x]-9, position[:y]+11, "+") do
        self.pointsize = 30
        self.fill = '#900000'
      end
      
      dr = Magick::Draw.new
      dr.fill = '#FF0000'
      dr.point(position[:x], position[:y])
      dr.point(position[:x], position[:y] + 1)   
      dr.point(position[:x] + 1, position[:y])  
      dr.point(position[:x] + 1, position[:y] + 1)             
      dr.draw(file)
    end

  end

end