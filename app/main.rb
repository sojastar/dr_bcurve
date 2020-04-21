require 'app/section.rb'

def setup(args)
  args.state.section    = Bezier::Section.new([500,100], [900,350], [100,350], [500,600])
  args.state.section.compute_length(100)
  args.state.section.compute_key_lengths(100)

  args.state.points     = args.state.section.compute_key_points(100)

  args.state.t          = 0.5
  args.state.mapped_t   = 0.5

  args.state.setup_done ||= true
end

def tick(args)
  setup(args) unless args.state.setup_done

  draw_cross args, args.state.section.end_point1,     [255, 0, 0, 255] 
  draw_cross args, args.state.section.end_point2,     [255, 0, 0, 255] 
  draw_cross args, args.state.section.control_point1, [0, 255, 0, 255] 
  draw_cross args, args.state.section.control_point2, [0, 255, 0, 255] 
  1.upto(99) do |i|
    draw_small_cross args, args.state.points[i], [100, 100, 255, 255]
  end

  if args.inputs.keyboard.key_held.n then
    args.state.t += 0.001
    args.state.t  = 1.0 if args.state.t >= 1.0

    args.state.mapped_t = args.state.section.map_linear(args.state.t)
  end

  if args.inputs.keyboard.key_held.b then
    args.state.t -= 0.001
    args.state.t  = 0.0 if args.state.t <= 0.0

    args.state.mapped_t = args.state.section.map_linear(args.state.t)
  end

  args.outputs.labels << [20, 720, "t = #{args.state.t}"]
  args.outputs.labels << [20, 700, "mapped t: #{args.state.mapped_t}"]
  draw_cross args, args.state.section.at(args.state.mapped_t), [255, 153, 0]
end

def draw_cross(args,coords,color)
  args.outputs.lines << [coords[0]-5, coords[1]+5, coords[0]+6, coords[1]-6] + color
  args.outputs.lines << [coords[0]-5, coords[1]-5, coords[0]+6, coords[1]+6] + color
end

def draw_small_cross(args,coords,color)
  args.outputs.lines << [coords[0]-1, coords[1], coords[0]+2, coords[1]] + color
  args.outputs.lines << [coords[0], coords[1]-1, coords[0], coords[1]+2] + color
end

