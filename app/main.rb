require 'app/trigo.rb'
require 'app/section.rb'
require 'app/curve.rb'

### Setup :
def setup(args)
  args.state.curve      = nil#Bezier::Curve.new [ [520,100], [640,360], [850,500] ]

  args.state.setup_done = true
end


### Main Loop :
def tick(args)
  # Setup :
  setup(args) unless args.state.setup_done

  # User input :
  if args.inputs.mouse.click then
    if args.state.curve.nil? then
      first_point = [ args.inputs.mouse.click.point.x,
                      args.inputs.mouse.click.point.y ]
      args.state.curve  = Bezier::Curve.new [ first_point ]
    else
      args.state.curve << [ args.inputs.mouse.click.point.x,
                            args.inputs.mouse.click.point.y ]
    end
  end

  # Render :
  unless args.state.curve.nil? then
    draw_curve args, args.state.curve, [150, 150, 150, 255]
  end
end


### Tools :
def draw_cross(args,coords,color)
  args.outputs.lines << [coords[0]-5, coords[1]+5, coords[0]+6, coords[1]-6] + color
  args.outputs.lines << [coords[0]-5, coords[1]-5, coords[0]+6, coords[1]+6] + color
end

def draw_small_cross(args,coords,color)
  args.outputs.lines << [coords[0]-1, coords[1], coords[0]+2, coords[1]] + color
  args.outputs.lines << [coords[0], coords[1]-1, coords[0], coords[1]+2] + color
end

def draw_handle(args,coords,color)
  args.outputs.solids << [ coords[0] - 2, coords[1] - 2, 5, 5 ] + color
end

def draw_curve(args,curve,color)
  ## Points and segments :
  curve.points.each { |point| draw_handle args, point, [0, 0, 0, 255] }

  if curve.points.length > 1 then
    curve.points.each_cons(2) do |points|
      args.outputs.lines << [ points[0][0], points[0][1], points[1][0], points[1][1] ] + color
    end

    ## Controls :
    #curve.controls.each { |control| draw_handle(args, control, [0, 0, 255, 255]) }
    curve.controls.each.with_index do |control,i|
      color = ( i % 2 == 0 ? [0, 0, 255, 255] : [255, 0, 0, 255] )
      draw_handle(args, control, color)
      args.outputs.labels << [ control[0], control[1],  i.to_s ]
    end

    args.state.curve.controls.slice(1, curve.controls.length-2).each_slice(2) do |controls|
      args.outputs.lines << [ controls[0][0], controls[0][1], controls[1][0], controls[1][1], 200, 200, 255, 255 ]
    end
  end
end

def random_color
  [ 100 + ( 155 * rand ).to_i,
    100 + ( 155 * rand ).to_i,
    100 + ( 155 * rand ).to_i,
    255 ]
end

def rad_to_deg(angle)
  180.0 * angle / Math::PI
end
