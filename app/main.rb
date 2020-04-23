require 'app/trigo.rb'
require 'app/section.rb'
require 'app/curve.rb'

### Setup :
def setup(args)
  args.state.curve      = nil
  #args.state.curve      = Bezier::Curve.new [ [520,100], [640,360], [850,500] ]
  args.state.mode       = :draw
  args.state.grabed     = nil
  args.state.setup_done = true
end


### Main Loop :
def tick(args)
  ## Setup :
  setup(args) unless args.state.setup_done

  ## User input :
  case args.state.mode
  ## DRAW MODE :
  when :draw
    # Clicking adds points :
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

    # Space bar switches to EDIT mode :
    if args.inputs.keyboard.key_down.space then
      args.state.grabed = nil
      args.state.mode   = :edit
    end

  ## EDIT MODE :
  when :edit
    # Clicking grabs the closest point or control ( if it is close enough ) and ...
    if args.inputs.mouse.click
      if args.state.grabed.nil? then
        points_distances    = args.state.curve.points.inject([]).with_index do |a,anchor,index|
                                a << {  distance: Bezier::Trigo::magnitude(anchor, [args.inputs.mouse.x, args.inputs.mouse.y]),
                                        index:    index }
                              end
        closest_point       = points_distances.sort! { |pd1,pd2| pd1[:distance] <=> pd2[:distance] }.first

        controls_distances  = args.state.curve.controls.inject([]).with_index do |a,control,index|
                                a << {  distance: Bezier::Trigo::magnitude(control, [args.inputs.mouse.x, args.inputs.mouse.y]),
                                        index:    index }
                              end
        closest_control     = controls_distances.sort! { |cd1,cd2| cd1[:distance] <=> cd2[:distance] }.first

        #args.state.grabed = controls_distances[0][:control] if controls_distances[0][:distance] < 10.0
        if closest_point[:distance] <= closest_control[:distance] && closest_point[:distance] < 10.0
          args.state.grabed = { type:   :anchor,
                                index:  closest_anchor[:index] }

        elsif closest_point[:distance] > closest_control[:distance] && closest_control[:distance] < 10.0
          args.state.grabed = { type:   :control,
                                index:  closest_anchor[:index] }

        end

      else
        args.state.grabed = nil

      end
    end

    unless args.state.grabed.nil? then
      args.state.grabed[0]  = args.inputs.mouse.x
      args.state.grabed[1]  = args.inputs.mouse.y
      args.outputs.labels << [20, 50, "grabed: #{args.state.grabed[0]},#{args.state.grabed[1]}" ]
    end

    # Space bar switches to DRAW mode :
    if args.inputs.keyboard.key_down.space then
      args.state.grabed = nil
      args.state.mode   = :draw
    end
  end

  # Render :
  unless args.state.curve.nil? then
    draw_curve args, args.state.curve, [150, 150, 150, 255]
    print_curve args, args.state.curve
  end

  args.outputs.labels << [20, 30, "mouse: #{args.inputs.mouse.x.to_i};#{args.inputs.mouse.y.to_i} - mode: #{args.state.mode.to_s}#{"(click to grab a point or control; ctrl-click point to straigthen controls)" if args.state.mode == :edit}"]
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
    curve.controls.each.with_index do |control,index|
      #color = index.even? ? [0, 0, 255, 255] : [255, 0, 0, 255]
      color = index % 2 == 0 ? [0, 0, 255, 255] : [255, 0, 0, 255]
      draw_handle(args, control, color)
    end

    curve.controls.length.times do |index|
      #point_index = index.even? ? index / 2 : ( index + 1 ) / 2
      point_index = index % 2 == 0 ? index / 2 : ( index + 1 ) / 2
      args.outputs.lines << curve.controls[index] + curve.points[point_index] + [ 200, 200, 255, 255 ]
    end

    ## Sections :
    curve.sections.each { |section| draw_section(args, section, [0, 0, 255, 255]) }
  end
end

def draw_section(args,section,color)
  t0 = 1.0 / 12
  12.times { |i| draw_small_cross(args, section.at(t0 * i), color) }
end

def print_curve(args,curve)
  curve.sections.length.times do |i|
    # Curve storage side :
    args.outputs.labels << [20, 720 - 15 * 5 * i,     "curve.points[#{i}]   -> (#{curve.points[i][0].to_i};#{curve.points[i][1].to_i}) - #{curve.points[i].object_id}", -4, 0, 255, 75, 75, 255]
    args.outputs.labels << [20, 720 - 15 * (5*i+1), "curve.controls[#{2*i}] -> (#{curve.controls[2*i][0].to_i};#{curve.controls[2*i][1].to_i}) - #{curve.controls[2*i].object_id}", -4, 0, 75, 75, 255, 255]
    args.outputs.labels << [20, 720 - 15 * (5*i+2), "curve.controls[#{2*i+1}] -> (#{curve.controls[2*i+1][0].to_i};#{curve.controls[2*i+1][1].to_i}) - #{curve.controls[2*i+1].object_id}", -4, 0, 75, 75, 255, 255]
    args.outputs.labels << [20, 720 - 15 * (5*i+3), "curve.points[#{i+1}]   -> (#{curve.points[i+1][0].to_i};#{curve.points[i+1][1].to_i}) - #{curve.points[i+1].object_id}", -4, 0, 255, 75, 75, 255]
    # Section storage side :
    args.outputs.labels << [350, 720 - 15 * 5 * i,   "curve.section[#{i}].end_point1     -> (#{curve.sections[i].end_point1[0].to_i};#{curve.sections[i].end_point1[1].to_i}) - #{curve.sections[i].end_point1.object_id}", -4, 0, 75, 255, 200, 255]
    args.outputs.labels << [350, 720 - 15 * (5*i+1),   "curve.section[#{i}].control_point1 -> (#{curve.sections[i].control_point1[0].to_i};#{curve.sections[i].control_point1[1].to_i}) - #{curve.sections[i].control_point1.object_id}", -4, 0, 0, 255, 0, 255]
    args.outputs.labels << [350, 720 - 15 * (5*i+2),   "curve.section[#{i}].control_point2 -> (#{curve.sections[i].control_point2[0].to_i};#{curve.sections[i].control_point2[1].to_i}) - #{curve.sections[i].control_point2.object_id}", -4, 0, 0, 255, 0, 255]
    args.outputs.labels << [350, 720 - 15 * (5*i+3),   "curve.section[#{i}].end_point2     -> (#{curve.sections[i].end_point2[0].to_i};#{curve.sections[i].end_point2[1].to_i}) - #{curve.sections[i].end_point2.object_id}", -4, 0, 75, 255, 200, 255]
  end
end

def rad_to_deg(angle)
  180.0 * angle / Math::PI
end
