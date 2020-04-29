module Bezier
  class Curve
    DEFAULT_STEPS = 24 

    attr_accessor :sections, :anchors, :controls, :length, :is_closed

    ### INITIALIZATION :
    def initialize(anchors,steps=DEFAULT_STEPS)
      raise "A curve must have at least one point (anchors argument nil or empty)." if anchors.nil? || anchors.empty?

      @anchors    = anchors
      @controls   = []
      @sections   = []

      @steps      = steps

      @length     = 0.0

      @is_closed  = false

      balance
      build_sections
    end


    ### ADDING ANCHOR POINTS :
    def <<(point)
      @anchors << point

      @controls += [ [0, 0], [0, 0] ] # add some dummy controls ...
      # ... that will be properly set by the 2 balance_at calls.

      @sections << Section.new( @anchors[@anchors.length-2],
                                @controls[@controls.length-2],
                                @controls.last,
                                @anchors.last )

      balance_at @anchors.length - 2
      balance_at @anchors.length - 1

      @length += @sections.last.compute_length(@steps)
      @sections.last.compute_key_lengths(@steps)
    end

    def build_sections
      (@anchors.length - 1).times do |i|
        @sections << Section.new( @anchors[i],
                                  @controls[2*i],
                                  @controls[2*i+1],
                                  @anchors[i+1] )
        end
    end


    ### Closing and opening :
    def close
      unless @is_closed || @anchors.length <= 2 then
        @controls += [ [0, 0], [0, 0] ]

        @sections << Section.new( @anchors.last,
                                  @controls[-2],
                                  @controls[-1],
                                  @anchors.first )

        @is_closed  = true

        balance_last
        balance_first

        @length += @sections.last.compute_length(@steps)
        @sections.last.compute_key_lengths(@steps)
      end
    end

    def open
      if @is_closed then
        @sections.pop
        #@controls.pop(2)
        @controls.pop # workaround for the pop bug
        @controls.pop

        @is_closed  = false

        balance_last
        balance_first
      end
    end
  

    ### AUTOMATIC BALANCING AT ANCHOR POINTS :
    def balance
      @controls = []
      @anchors.length.times { |i| balance_at i } 
    end

    def balance_first
      if @is_closed then
        control_before, control_after = balance_point @anchors[-1], @anchors[0], @anchors[1]
        @controls[-1][0]  = control_before[0]
        @controls[-1][1]  = control_before[1]
        @controls[0][0]   = control_after[0]
        @controls[0][1]   = control_after[1]

      else
        @controls[0][0]   = @anchors[0][0] + ( @anchors[1][0] - @anchors[0][0] ) / 3.0
        @controls[0][1]   = @anchors[0][1] + ( @anchors[1][1] - @anchors[0][1] ) / 3.0

      end
    end

    def balance_last
      if @is_closed then
        control_before, control_after = balance_point @anchors[-2], @anchors[-1], @anchors[0]
        @controls[-3][0]  = control_before[0]
        @controls[-3][1]  = control_before[1]
        @controls[-2][0]  = control_after[0]
        @controls[-2][1]  = control_after[1]

      else
        @controls[-1][0]  = @anchors[-1][0] + ( @anchors[-2][0] - @anchors[-1][0] ) / 3.0
        @controls[-1][1]  = @anchors[-1][1] + ( @anchors[-2][1] - @anchors[-1][1] ) / 3.0

      end
    end

    def balance_point(before,point,after)
      angle1              = Bezier::Trigo::angle_of before, point
      angle2              = Bezier::Trigo::angle_of point, after
      control_angle       = ( angle1 + angle2 ) / 2.0
      control_angle      += Math::PI if ( angle1 - angle2 ).abs > Math::PI

      length1             = Bezier::Trigo::magnitude(point, before) / 3.0
      length2             = Bezier::Trigo::magnitude(point, after)  / 3.0

      control_before      = [ point[0] - length1 * Math::cos(control_angle),
                              point[1] - length1 * Math::sin(control_angle) ]
      control_after       = [ point[0] + length2 * Math::cos(control_angle),
                              point[1] + length2 * Math::sin(control_angle) ]

      [control_before, control_after]
    end

    def balance_at(index)
      case @anchors.length
      when 1
        raise "Index out of range (got index #{index} for a length of 1)!" if index != 0

        # No need to add a control point if there is only one anchor, ...
        # ... so do nothing ( but it is important to isolate the case ) !

      when 2
        raise "Index out of range (got index #{index} for a length of 2)!" if index >= 2

        # Same process wether the index is 0 or 1 : place the control anchors ...
        # ... at one third and two thirds of the segment.
        @controls[0][0] = @anchors[0][0] +       ( @anchors[1][0] - @anchors[0][0] ) / 3.0
        @controls[0][1] = @anchors[0][1] +       ( @anchors[1][1] - @anchors[0][1] ) / 3.0
        @controls[1][0] = @anchors[0][0] + 2.0 * ( @anchors[1][0] - @anchors[0][0] ) / 3.0
        @controls[1][1] = @anchors[0][1] + 2.0 * ( @anchors[1][1] - @anchors[0][1] ) / 3.0
        
      else
        raise "Index out of range (got index #{index} for a length of #{@anchors.length})!" if index >= @anchors.length

        case index
        when 0                    then balance_first
        when @anchors.length - 1  then balance_last
        else
          control_before, control_after = balance_point @anchors[index-1], @anchors[index], @anchors[index+1]

          @controls[2*index-1][0] = control_before[0]
          @controls[2*index-1][1] = control_before[1]
          @controls[2*index][0]   = control_after[0]
          @controls[2*index][1]   = control_after[1]

        end

      end

      update_sections_length_at_anchor(index)
    end

    def update_sections_length_at_anchor(index)
      if @sections.length > 0 then
        case index
        when 0
          @sections.first.compute_length(@steps)
          @sections.first.compute_key_lengths(@steps)

        when @anchors.length - 1
          @sections.last.compute_length(@steps)
          @sections.last.compute_key_lengths(@steps)

        else
          @sections[index-1].compute_length(@steps)
          @sections[index-1].compute_key_lengths(@steps)


          @sections[index].compute_length(@steps)
          @sections[index].compute_key_lengths(@steps)
        end
      end

      compute_length
    end


    ### TRAVERSING :
    def compute_length
      @length = @sections.inject(0.0) { |sum,section| sum += section.length }
    end

    def find_section_length_at(t)
      u                 = t * @length
      section_index     = 0
      length_to_section = 0.0
      while section_index < @sections.length && length_to_section + @sections[section_index].length < u do
        length_to_section += @sections[section_index].length
        section_index     += 1
      end

      [section_index, length_to_section]
    end

    def prepare_traversing(steps)
      @sections.each do |section|
        section.compute_length      steps
        section.compute_key_lengths steps
      end

      compute_length
    end

    def at(t)
      section_index, length_to_section  = find_section_length_at t

      if section_index >= @sections.length then
        section_index = @sections.length - 1
        mapped_t      = 1.0
      else
        mapped_t      = ( t * @length - length_to_section ) / @sections[section_index].length
      end

      @sections[section_index].at_linear(mapped_t) 
    end


    ### INSPECTION :
    def to_s
      "curve #{object_id} -> #{@anchors.length} anchors"
    end

    def detailed_inspect
      inspect_string  = ''
      @sections.length.times do |i|
        # by section :
        
        # 1. first anchor :
        inspect_string += "@anchors[#{i}] -> (#{@anchors[i][0].to_i};#{@anchors[i][1].to_i}) - #{@anchors[i].object_id}" + " | " +
        "@section[#{i}].anchor1 -> (#{@sections[i].anchor1[0].to_i};#{@sections[i].anchor1[1].to_i}) - #{@sections[i].anchor1.object_id}"

        # 2. first control :
        inspect_string += "@controls[#{2*i}] -> (#{@controls[2*i][0].to_i};#{@controls[2*i][1].to_i}) - #{@controls[2*i].object_id}" + " | " + 
        "@section[#{i}].control1 -> (#{@sections[i].control1[0].to_i};#{@sections[i].control1[1].to_i}) - #{@sections[i].control1.object_255}"

        # 3. second control :
        inspect_string += "@controls[#{2*i+1}] -> (#{@controls[2*i+1][0].to_i};#{@controls[2*i+1][1].to_i}) - #{@controls[2*i+1].object_id}" + " | " +
        "@section[#{i}].control2 -> (#{@sections[i].control2[0].to_i};#{@sections[i].control2[1].to_i}) - #{@sections[i].control2.object_255}"

        # 4. second anchor :
        inspect_string += "@anchors[#{i+1}] -> (#{@anchors[i+1][0].to_i};#{@anchors[i+1][1].to_i}) - #{@anchors[i+1].object_id}" + " | " + 
        "@section[#{i}].anchor2 -> (#{@sections[i].anchor2[0].to_i};#{@sections[i].anchor2[1].to_i}) - #{@sections[i].anchor2.object_id}"
      end
    end
  end
end

