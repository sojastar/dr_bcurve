module Bezier
  class Curve
    attr_accessor :sections
  end

  def initialize(points)
    raise 'wrong number of points' if points.length < 2
    @sections = []
    points.each_cons(2).do |p| do
      
    end
  end

  def balance
    
  end
end

