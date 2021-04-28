module Bezier
  class Point
    attr_accessor :x, :y

    def initialize(x,y)
      @x, @y = x, y
    end

    def coords() [@x, @y] end

    def to_s
      "(#{@x.round(2)});#{@y.round(2)})"
    end
    alias inspect to_s
  end

  class Anchor
    attr_reader :center,
                :left_handle, :right_handle

    def initialize(x,y)
      @center       = Point.new(x,y)
      @left_handle  = Point.new(x - 30, y)
      @right_handle = Point.new(x + 30, y)
    end

    def x() @center.x end
    def y() @center.y end
    def coords() [ @center.x, @center.y ] end

    def x=(new_x) @center.x = new_x end
    def y=(new_y) @center.y = new_y end
  end
end
