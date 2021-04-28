module Bezier
  class Curve
    DEFAULT_STEPS = 24 

    attr_accessor :sections, :anchors, :length, :is_closed

    ### INITIALIZATION :
    def initialize(anchors,steps=DEFAULT_STEPS)
      raise "A curve must have at least one point (anchors argument nil or empty)." if anchors.nil? || anchors.empty?

      # Geometry data structures :
      @anchors    = anchors
      @sections   = []

      # State :
      @steps      = steps
      @length     = 0.0
      @is_closed  = false

      # Setup :
      balance
      build_sections
    end


    ### ADDING ANCHOR POINTS :
    def <<(anchor)
      @anchors << anchor

      @sections << Section.new( @anchors[@anchors.length-2], @anchors.last )

      balance_at @anchors.length - 2
      balance_at @anchors.length - 1

      @length += @sections.last.compute_length(@steps)
      @sections.last.compute_key_lengths(@steps)
    end

    def build_sections
      (@anchors.length - 1).times do |i|
        @sections << Section.new( @anchors[i], @anchors[i+1] )
        end
    end


    ### CLOSING AND OPENING :
    def close
      unless @is_closed || @anchors.length <= 2 then
        @sections << Section.new( @anchors.last,
                                  @anchors.first )

        @is_closed  = true

        balance_last_anchor
        balance_first_anchor

        @length += @sections.last.compute_length(@steps)
        @sections.last.compute_key_lengths(@steps)
      end
    end

    def open
      if @is_closed then
        @sections.pop

        @is_closed  = false

        balance_last_anchor
        balance_first_anchor
      end
    end

    def is_closed?()  @is_closed  end
    def is_open?()    !@is_closed end
  

    ### AUTOMATIC BALANCING AT ANCHOR POINTS :
    def balance
      @anchors.length.times { |i| balance_at i } 
    end

    def balance_first_anchor
      if @is_closed then
        balance_anchor @anchors[-1], @anchors[0], @anchors[1]

      else  
        @anchors[0].right_handle.x  = @anchors[0].x + ( @anchors[1].x - @anchors[0].x ) / 3.0
        @anchors[0].right_handle.y  = @anchors[0].y + ( @anchors[1].y - @anchors[0].y ) / 3.0

      end
    end

    def balance_last_anchor
      if @is_closed then
        balance_anchor @anchors[-2], @anchors[-1], @anchors[0]

      else  
        @anchors[-1].left_handle.x  = @anchors[-1].x + ( @anchors[-2].x - @anchors[-1].x ) / 3.0
        @anchors[-1].left_handle.y  = @anchors[-1].y + ( @anchors[-2].y - @anchors[-1].y ) / 3.0

      end
    end

    def balance_anchor(before,anchor,after)
      angle1        = Bezier::Trigo::angle_of before, anchor
      angle2        = Bezier::Trigo::angle_of         anchor, after
      handle_angle  = ( angle1 + angle2 ) / 2.0
      handle_angle += Math::PI if ( angle1 - angle2 ).abs > Math::PI

      length1       = Bezier::Trigo::magnitude(anchor.coords, before.coords) / 3.0
      length2       = Bezier::Trigo::magnitude(anchor.coords, after.coords)  / 3.0

      anchor.left_handle.x  = anchor.x - length1 * Math::cos(handle_angle)
      anchor.left_handle.y  = anchor.y - length1 * Math::sin(handle_angle)
      anchor.right_handle.x = anchor.x + length2 * Math::cos(handle_angle)
      anchor.right_handle.y = anchor.y + length2 * Math::sin(handle_angle)
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
        @anchors[0].right_handle.x  = @anchors[0].x +       ( @anchors[1].x - @anchors[0].x ) / 3.0
        @anchors[0].right_handle.y  = @anchors[0].y +       ( @anchors[1].y - @anchors[0].y ) / 3.0
        @anchors[1].left_handle.x   = @anchors[1].x + 2.0 * ( @anchors[1].x - @anchors[0].x ) / 3.0
        @anchors[1].left_handle.y   = @anchors[1].y + 2.0 * ( @anchors[1].y - @anchors[0].y ) / 3.0
        
      else
        raise "Index out of range (got index #{index} for a length of #{@anchors.length})!" if index >= @anchors.length

        case index
        when 0                    then  balance_first_anchor
        when @anchors.length - 1  then  balance_last_anchor
        else                            balance_anchor(@anchors[index-1], @anchors[index], @anchors[index+1])
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

    def coords_at(t)
      section_index, length_to_section  = find_section_length_at t

      if section_index >= @sections.length then
        section_index = @sections.length - 1
        mapped_t      = 1.0
      else
        mapped_t      = ( t * @length - length_to_section ) / @sections[section_index].length
      end

      @sections[section_index].coords_at_linear(mapped_t) 
    end


    ### LOADING FROM FILE :
    def load(filename)
    end


    ### INSPECTION :
    def to_s
      "curve #{object_id} -> #{@anchors.length} anchors"
    end

    def detailed_inspect
      inspect_string = ''
      @sections.each.with_index { |section,index| inspect_string += "- section #{index} :\n#{section}" }
    end
  end
end

