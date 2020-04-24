module Bezier
  class Curve
    attr_accessor :sections, :anchors, :controls

    def initialize(anchors)
      @anchors  = anchors
      @controls = []
      @sections = []

      balance
      build_sections
    end

    def <<(point)
      @anchors << point

      balance_at @anchors.length - 2
      balance_at @anchors.length - 1

      @sections << Section.new( @anchors[@anchors.length-2],
                                @controls[@controls.length-2],
                                @controls.last,
                                @anchors.last )
      #@sections.last.compute_key_lengths(12)
    end

    def build_sections
      (@anchors.length - 1).times do |i|
        @sections << Section.new( @anchors[i],
                                  @controls[2*i],
                                  @controls[2*i+1],
                                  @anchors[i+1] )
        end
    end

    #def update_sections
    #  @sections.times { |i| update_section(i) }
    #end

    #def update_section(index)

    #end
  
    def balance
      @controls = []
      @anchors.length.times { |i| balance_at i } 
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
        @controls[0] = [  @anchors[0][0] + ( @anchors[1][0] - @anchors[0][0] ) / 3.0,
                          @anchors[0][1] + ( @anchors[1][1] - @anchors[0][1] ) / 3.0 ]
        @controls[1] = [  @anchors[0][0] + 3.0 * ( @anchors[1][0] - @anchors[0][0] ) / 3.0,
                          @anchors[0][1] + 3.0 * ( @anchors[1][1] - @anchors[0][1] ) / 3.0 ]
        
      else
        raise "Index out of range (got index #{index} for a length of #{@anchors.length})!" if index >= @anchors.length

        case index
        when 0 
          @controls[index]      = [ @anchors[0][0] + ( @anchors[1][0] - @anchors[0][0] ) / 3.0,
                                    @anchors[0][1] + ( @anchors[1][1] - @anchors[0][1] ) / 3.0 ]

        when @anchors.length - 1
          @controls[2*index-1]  = [ @anchors[-1][0] + ( @anchors[-2][0] - @anchors[-1][0] ) / 3.0,
                                    @anchors[-1][1] + ( @anchors[-2][1] - @anchors[-1][1] ) / 3.0 ]

        else
          angle1                = Bezier::Trigo::angle_of @anchors[index-1], @anchors[index]
          angle2                = Bezier::Trigo::angle_of @anchors[index],   @anchors[index+1]
          control_angle         = ( angle1 + angle2 ) / 2.0
          control_angle        += Math::PI if ( angle1 - angle2 ).abs > Math::PI

          length1               = Bezier::Trigo::magnitude(@anchors[index-1], @anchors[index])   / 3.0
          length2               = Bezier::Trigo::magnitude(@anchors[index],   @anchors[index+1]) / 3.0

          @controls[2*index-1]  = [ @anchors[index][0] - length1 * Math::cos(control_angle),
                                    @anchors[index][1] - length1 * Math::sin(control_angle) ]
          @controls[2*index]    = [ @anchors[index][0] + length2 * Math::cos(control_angle),
                                    @anchors[index][1] + length2 * Math::sin(control_angle) ]
          @sections.last.control2 = @controls[2*index-1]
        end

      end
    end

    def to_s
      "curve #{object_id} -> length: #{@anchors.length}"
    end
  end
end
