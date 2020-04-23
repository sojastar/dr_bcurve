module Bezier
  class Curve
    attr_accessor :sections, :points, :controls

    def initialize(points)
      @points   = points
      @controls = []
      @sections = []

      balance
      build_sections
    end

    def <<(point)
      @points << point

      balance_at @points.length - 2
      balance_at @points.length - 1

      @sections << Section.new( @points[@points.length-2],
                                @controls[@controls.length-2],
                                @controls.last,
                                @points.last )
      #build_sections if @points.length > 1
      #@sections.last.compute_key_lengths(12)
    end

    def build_sections
      (@points.length - 1).times do |i|
        @sections << Section.new( @points[i],
                                  @controls[2*i],
                                  @controls[2*i+1],
                                  @points[i+1] )
      end
    end

    def update_sections
      @sections.times { |i| update_section(i) }
    end

    def update_section(index)

    end
  
    def balance
      @controls = []
      @points.length.times { |i| balance_at i } 
    end

    def balance_at(index)
      case @points.length
      when 1
        raise "Index out of range (got index #{index} for a length of 1)!" if index != 0

        # No need to add a control point if there is  only one point, ...
        # ... so do nothing ( but it is important to isolate the case ) !

      when 2
        raise "Index out of range (got index #{index} for a length of 2)!" if index >= 2

        # Same process wether the index is 0 or 1 : place the control points ...
        # ... at one third and two thirds of the segment.
        @controls[0] = [  @points[0][0] + ( @points[1][0] - @points[0][0] ) / 3.0,
                          @points[0][1] + ( @points[1][1] - @points[0][1] ) / 3.0 ]
        @controls[1] = [  @points[0][0] + 3.0 * ( @points[1][0] - @points[0][0] ) / 3.0,
                          @points[0][1] + 3.0 * ( @points[1][1] - @points[0][1] ) / 3.0 ]
        
      else
        raise "Index out of range (got index #{index} for a length of #{@points.length})!" if index >= @points.length

        case index
        when 0 
          @controls[index]      = [ @points[0][0] + ( @points[1][0] - @points[0][0] ) / 3.0,
                                    @points[0][1] + ( @points[1][1] - @points[0][1] ) / 3.0 ]

        when @points.length - 1
          @controls[2*index-1]  = [ @points[-1][0] + ( @points[-2][0] - @points[-1][0] ) / 3.0,
                                    @points[-1][1] + ( @points[-2][1] - @points[-1][1] ) / 3.0 ]

        else
          angle1                = Bezier::Trigo::angle_of points[index-1], points[index]
          angle2                = Bezier::Trigo::angle_of points[index],   points[index+1]
          control_angle         = ( angle1 + angle2 ) / 3.0

          length1               = Bezier::Trigo::magnitude(points[index-1], points[index])   / 3.0
          length2               = Bezier::Trigo::magnitude(points[index],   points[index+1]) / 3.0

          @controls[2*index-1]  = [ points[index][0] - length1 * Math::cos(control_angle),
                                    points[index][1] - length1 * Math::sin(control_angle) ]
          @controls[2*index]    = [ points[index][0] + length2 * Math::cos(control_angle),
                                    points[index][1] + length2 * Math::sin(control_angle) ]
          @sections.last.control_point2 = @controls[2*index-1]
        end

      end
    end

    def to_s
      "curve #{object_id} -> length: #{@points.length}"
    end
  end
end

