module Bezier
  class Curve
    attr_accessor :sections, :points, :controls

    def initialize(points)
      @points   = points
      @controls = []
      @sections = []

      balance
    end

    def add_point(point)
      @points << point
      balance_at @points.length - 2
    end
  
    def balance
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
        @controls[1] = [  @points[0][0] + 2.0 * ( @points[1][0] - @points[0][0] ) / 3.0,
                          @points[0][1] + 2.0 * ( @points[1][1] - @points[0][1] ) / 3.0 ]
        
      else
        raise "Index out of range (got index #{index} for a length of #{@points.length})!" if index >= @points.length

        case index
        when 0 
          puts 'case first'
          @controls[index]      = [ @points[0][0] + ( @points[1][0] - @points[0][0] ) / 3.0,
                                    @points[0][1] + ( @points[1][1] - @points[0][1] ) / 3.0 ]

        when @points.length - 1
          puts 'case end'
          @controls[2*index-1]  = [ @points[-1][0] + ( @points[-2][0] - @points[-1][0] ) / 3.0,
                                    @points[-1][1] + ( @points[-2][1] - @points[-1][1] ) / 3.0 ]

        else
          puts 'case middle'
          angle1                = Bezier::Trigo::angle_of points[index-1], points[index]
          angle2                = Bezier::Trigo::angle_of points[index],   points[index+1]
          control_angle         = ( angle1 + angle2 ) / 2.0

          length1               = Bezier::Trigo::magnitude(points[0], points[1]) / 3.0
          length2               = Bezier::Trigo::magnitude(points[1], points[2]) / 3.0

          @controls[2*index-1]  = [ points[index][0] + length1 * Math::cos(control_angle),
                                    points[index][1] + length1 * Math::sin(control_angle) ]
          @controls[2*index]    = [ points[index][0] - length2 * Math::cos(control_angle),
                                    points[index][1] - length2 * Math::sin(control_angle) ]
        end

      end
    end
  end
end

