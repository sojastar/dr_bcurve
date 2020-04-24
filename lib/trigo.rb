module Bezier
  module Trigo
    def self.magnitude(point1,point2)
      Math::sqrt((point1[0] - point2[0]) ** 2 + (point1[1] - point2[1]) ** 2)
    end

    def self.angle_of(p1,p2)
      angle_offset  = case
                      when p2[0] >= p1[0] &&
                           p2[1] >= p1[1] then  0.0
                      when p2[0] <  p1[0] then  Math::PI
                      when p2[0] >= p1[0] &&
                           p2[1] <  p1[1] then  2.0 * Math::PI
                      end
      angle_offset + Math.atan( ( p2[1] - p1[1] ).to_f / ( p2[0] - p1[0] ).to_f )
    end
  end
end
