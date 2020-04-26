module Bezier
  class Section
    include Trigo

    MIN_STEPS     = 12
    MAX_PRECISION = 2
    MAX_LENGTH    = 1000000000
  
    attr_accessor :anchor1, :anchor2,
                  :control1, :control2,
                  :length, :key_lengths
  

    ### Initialization :
    def initialize(anchor1,control1,control2,anchor2)
      @anchor1  = anchor1
      @control1 = control1
      @anchor2  = anchor2
      @control2 = control2
    end
  

    ### Traversing :
    def at(t)
      [ coord_at(0,t), coord_at(1,t) ]
    end

    def coord_at(coord,t)
        @anchor1[coord] * (1 -t) ** 3 +
        3 * @control1[coord] * t * (1 - t) ** 2 +
        3 * @control2[coord] * (1 - t) * t ** 2 +
        @anchor2[coord] * t ** 3
    end


    ### Length :
    def compute_precise_length(min_steps=MIN_STEPS,precision=MAX_PRECISION)
      # Compute the minimal t0 to have decent precision :
      steps       = min_steps
      step_length = MAX_LENGTH # impossibly big !
      while step_length > precision do
        t0          = 1.0 / steps
        step_length = Bezier::Trigo::magnitude @anchor1, at(t0)
        steps      += 1
      end

      # Actually computes the length of the section :
      points  = steps.times.inject([]) { |a,i| a << at(i * t0) }
      #points.each_cons(2).sum { |p| Bezier::Trigo::magnitude(p[0],p[1]) }    # for future versions
      @length = points.each_cons(2).inject(0.0) { |length,p| length += Bezier::Trigo::magnitude(p[0],p[1]) } 
    end

    def compute_length(steps)
      t0      = 1.0 / steps
      points  = (steps + 1).times.inject([]) { |a,i| a << at(i * t0) }
      @length = points.each_cons(2).inject(0.0) { |length,p| length += Bezier::Trigo::magnitude(p[0],p[1]) } 
    end


    ### Traversing linearly :
    def compute_key_points(steps)
      t0 = 1.0 / steps
      (steps + 1).times.inject([]) { |points,i| points << at(i * t0) }
    end

    def compute_key_lengths(steps)
      last_length = 0.0
      @key_lengths  = compute_key_points(steps).each_cons(2).inject([0.0]) do |lengths,points|
                        last_length += Bezier::Trigo::magnitude(points[0],points[1])
                        lengths << last_length
                      end
    end

    def map_linear(t)
      # Finding the index for the closest length to t :
      u             = @length * t
      bottom_index  = 0
      top_index     = @key_lengths.length - 1
      index         = 0
      while bottom_index < top_index do
        index = bottom_index + ( ( top_index - bottom_index ) >> 1 )
        if @key_lengths[index] < u then bottom_index  = index + 1
        else                            top_index     = index
        end
      end

      index -= 1 if @key_lengths[index] > u

      # Return the mapped t :
      if u == @key_lengths[index] then
        index / @key_lengths.length
      else
        ( index + ( u - @key_lengths[index] ) / ( @key_lengths[index+1] - @key_lengths[index] ) ) / ( @key_lengths.length - 1 )
      end
    end

    def at_linear(t)
      at(map_linear(t))
    end


    ### Inspect :
    def to_s
      "end point 1: #{@anchor1}\ncontrol point 1: #{@control1}\nend point 2: #{@anchor2}\ncontrol point 2: #{@control2}"
    end
  end
end

