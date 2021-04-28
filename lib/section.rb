module Bezier
  class Section
    include Trigo

    MIN_STEPS     = 12
    MAX_PRECISION = 2
    MAX_LENGTH    = 1000000000
  
    attr_accessor :anchor1, :anchor2,
                  :length, :key_lengths
  

    ### Initialization :
    def initialize(anchor1,anchor2)
      @anchor1  = anchor1
      @anchor2  = anchor2
    end
  

    ### Traversing :
    def coords_at(t)
      [ x_at(t), y_at(t) ]
    end

    def x_at(t)
        @anchor1.x * (1 -t) ** 3 +
        3 * @anchor1.right_handle.x * t * (1 - t) ** 2 +
        3 * @anchor2.left_handle.x * (1 - t) * t ** 2 +
        @anchor2.x * t ** 3
    end

    def y_at(t)
        @anchor1.y * (1 -t) ** 3 +
        3 * @anchor1.right_handle.y * t * (1 - t) ** 2 +
        3 * @anchor2.left_handle.y * (1 - t) * t ** 2 +
        @anchor2.y * t ** 3
    end


    ### Length :
    def compute_precise_length(min_steps=MIN_STEPS,precision=MAX_PRECISION)
      # Compute the minimal t0 to have decent precision :
      steps       = min_steps
      step_length = MAX_LENGTH # impossibly big !
      while step_length > precision do
        t0          = 1.0 / steps
        step_length = Bezier::Trigo::magnitude @anchor1.coords, coords_at(t0)
        steps      += 1
      end

      # Actually computes the length of the section :
      points  = steps.times.inject([]) { |a,i| a << coords_at(i * t0) }
      @length = points.each_cons(2).inject(0.0) { |length,p| length += Bezier::Trigo::magnitude(p[0],p[1]) } 
    end

    def compute_length(steps)
      t0      = 1.0 / steps
      points  = (steps + 1).times.inject([]) { |a,i| a << coords_at(i * t0) }
      @length = points.each_cons(2).inject(0.0) { |length,p| length += Bezier::Trigo::magnitude(p[0],p[1]) } 
    end


    ### Traversing linearly :
    def compute_key_points(steps)
      t0 = 1.0 / steps
      (steps + 1).times.inject([]) { |points,i| points << coords_at(i * t0) }
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

    def coords_at_linear(t)
      coords_at(map_linear(t))
    end


    ### Inspect :
    def to_s
      "x- first anchor  : #{@anchor1.center} - #{@anchor1.object_id}\n" +
      "<- first handle  : #{@anchor1.right_handle} - #{@anchor1.right_handle.object_id}\n" +
      "-> second handle : #{@anchor2.left_handle} - #{@anchor1.left_handle.object_id}\n" +
      "-x second anchor : #{@anchor2.center} - #{@anchor1.object_id}\n"
    end
    alias inspect to_s
  end
end

