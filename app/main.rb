require '/lib/trigo.rb'
require '/lib/section.rb'
require '/lib/curve.rb'





### Constants :
GRAB_DISTANCE     = 10.0
RENDERING_STEPS   = 24
TRAVERSING_SPEED  = 0.01





### Setup :
def setup(args)
  args.state.curve      = nil
  args.state.mode       = :draw
  args.state.grabed     = nil

  args.state.t          = 0.5

  args.state.setup_done = true
end





### Main Loop :
def tick(args)
  trace! $game

  ## Setup :
  setup(args) unless args.state.setup_done


  ## User input :
  case args.state.mode

  ## DRAW MODE :
  when :draw
    # Clicking adds an anchor :
    if args.inputs.mouse.click then
      new_anchor  = [ args.inputs.mouse.click.point.x,
                      args.inputs.mouse.click.point.y ]
      if args.state.curve.nil? then
        args.state.curve  = Bezier::Curve.new [ new_anchor ]
      else
        args.state.curve << new_anchor
      end
    end

    # Space bar switches to EDIT mode :
    if args.inputs.keyboard.key_down.space then
      args.state.grabed = nil
      args.state.mode   = :edit
    end

    # Pressing 't' switches to TRAVERSING mode:
    if args.inputs.keyboard.key_down.t then
      args.state.grabed = nil
      args.state.mode   = :traversing
      args.state.t      = 0.5
    end

    args.outputs.labels << [20, 700, "mouse: #{args.inputs.mouse.x.to_i};#{args.inputs.mouse.y.to_i} - mode: #{args.state.mode.to_s}"]


  ## EDIT MODE :
  when :edit
    # Clicking grabs the closest point or control ( if it is close enough ) and ...
    # ... cliking + control will straighten the curve at the clicked point.
    if args.inputs.mouse.click
      if args.state.grabed.nil? then
        anchors_distances   = args.state.curve.anchors.map.with_index do |anchor,index|
                                {  distance: Bezier::Trigo::magnitude(anchor, [args.inputs.mouse.x, args.inputs.mouse.y]),
                                   index:    index }
                              end
        closest_anchor      = anchors_distances.sort! { |pd1,pd2| pd1[:distance] <=> pd2[:distance] }.first

        controls_distances  = args.state.curve.controls.map.with_index do |control,index|
                                {  distance: Bezier::Trigo::magnitude(control, [args.inputs.mouse.x, args.inputs.mouse.y]),
                                   index:    index }
                              end
        closest_control     = controls_distances.sort! { |cd1,cd2| cd1[:distance] <=> cd2[:distance] }.first

        if closest_anchor[:distance] <= closest_control[:distance] && closest_anchor[:distance] < GRAB_DISTANCE
          if args.inputs.keyboard.b then    # Control held down will balance the ...
                                            # ... curve at the clicked anchor.
            args.state.curve.balance_at closest_anchor[:index]
          
          else                              # Simple click will grab the anchor and its ...
                                            # ... local controls or just a control.
            anchor_index    = closest_anchor[:index]
            args.state.grabed = { type:             :anchor,
                                  index:            closest_anchor[:index] }

            if anchor_index > 0 then  # because the first anchor of the curve ...
                                      # ... doesn't have a control1.
              args.state.grabed[:control1_index]  = 2 * anchor_index - 1
              args.state.grabed[:control1_offset] = [ args.state.curve.controls[2*anchor_index-1][0] -
                                                      args.state.curve.anchors[anchor_index][0],
                                                      args.state.curve.controls[2*anchor_index-1][1] -
                                                      args.state.curve.anchors[anchor_index][1] ]
            end

            if anchor_index < args.state.curve.anchors.length - 1 then  # because the last anchor ...
                                                                        # ... doesn't have a control2
              args.state.grabed[:control2_index]  = 2 * anchor_index
              args.state.grabed[:control2_offset] = [ args.state.curve.controls[2*anchor_index][0] -
                                                      args.state.curve.anchors[anchor_index][0],
                                                      args.state.curve.controls[2*anchor_index][1] -
                                                      args.state.curve.anchors[anchor_index][1] ]
            end
          end

        elsif closest_anchor[:distance] > closest_control[:distance] && closest_control[:distance] < GRAB_DISTANCE
          args.state.grabed = { type:   :control,
                                index:  closest_control[:index] }

        end

      else
        args.state.grabed = nil
        args.state.curve.compute_length

      end
    end

    unless args.state.grabed.nil? then
      if args.state.grabed[:type] == :anchor then
        args.state.curve.anchors[args.state.grabed[:index]][0] = args.inputs.mouse.x
        args.state.curve.anchors[args.state.grabed[:index]][1] = args.inputs.mouse.y

        if args.state.grabed.has_key? :control1_index then
          control_index = args.state.grabed[:control1_index]
          args.state.curve.controls[control_index][0] = args.inputs.mouse.x + args.state.grabed[:control1_offset][0]
          args.state.curve.controls[control_index][1] = args.inputs.mouse.y + args.state.grabed[:control1_offset][1]
        end

        if args.state.grabed.has_key? :control2_index then
          control_index = args.state.grabed[:control2_index]
          args.state.curve.controls[control_index][0] = args.inputs.mouse.x + args.state.grabed[:control2_offset][0]
          args.state.curve.controls[control_index][1] = args.inputs.mouse.y + args.state.grabed[:control2_offset][1]
        end

      elsif args.state.grabed[:type] == :control then
        args.state.curve.controls[args.state.grabed[:index]][0] = args.inputs.mouse.x
        args.state.curve.controls[args.state.grabed[:index]][1] = args.inputs.mouse.y
      
      end

      args.outputs.labels << [20, 680, "grabed #{args.state.grabed[:type].to_s} #{args.state.grabed[:index]}" ]
    end

    # Space bar switches to DRAW mode :
    if args.inputs.keyboard.key_down.space then
      args.state.grabed = nil
      args.state.mode   = :draw
    end

    # Pressing 't' switches to TRAVERSING mode:
    if args.inputs.keyboard.key_down.t then
      args.state.grabed = nil
      args.state.mode   = :traversing
      args.state.t      = 0.5
    end

    args.outputs.labels << [20, 700, "mouse: #{args.inputs.mouse.x.to_i};#{args.inputs.mouse.y.to_i} - mode: #{args.state.mode.to_s} (click to grab a point or control; click+b on anchor to straigthen curve)"]


  ## TRAVERSING MODE :
  when :traversing
    # User input :
    if args.inputs.keyboard.key_held.up || args.inputs.keyboard.key_held.right then
      args.state.t += TRAVERSING_SPEED
      args.state.t  = 1.0 if args.state.t > 1.0
    elsif args.inputs.keyboard.key_held.down || args.inputs.keyboard.key_held.left then
      args.state.t -= TRAVERSING_SPEED
      args.state.t  = 0.0 if args.state.t < 0.0
    end

    # Drawing :
    point = args.state.curve.at args.state.t
    draw_cross args, point, [255, 0, 0, 255]

    args.outputs.labels << [20, 700, "mouse: #{args.inputs.mouse.x.to_i};#{args.inputs.mouse.y.to_i} - mode: #{args.state.mode.to_s} t = #{args.state.t} -> (#{point[0].to_i},#{point[1].to_i})"]

  end


  # Render :
  unless args.state.curve.nil? then
    draw_curve args, args.state.curve, [150, 150, 150, 255]
  end

end





### Drawing :
def draw_curve(args,curve,color)
  ## Anchors and segments :
  curve.anchors.each { |anchor| draw_handle args, anchor, [0, 0, 0, 255] }

  if curve.anchors.length > 1 then
    curve.anchors.each_cons(2) do |anchors|
      args.outputs.lines << [ anchors[0][0], anchors[0][1], anchors[1][0], anchors[1][1] ] + color
    end

    ## Controls :
    curve.controls.each.with_index do |control,index|
      #color = index.even? ? [0, 0, 255, 255] : [255, 0, 0, 255]
      color = index % 2 == 0 ? [0, 0, 255, 255] : [255, 0, 0, 255]
      draw_handle(args, control, color)
    end

    curve.controls.length.times do |index|
      #point_index = index.even? ? index / 2 : ( index + 1 ) / 2
      anchor_index = index % 2 == 0 ? index / 2 : ( index + 1 ) / 2
      args.outputs.lines << curve.controls[index] + curve.anchors[anchor_index] + [ 200, 200, 255, 255 ]
    end

    ## Sections :
    curve.sections.each { |section| draw_section(args, section, [0, 0, 255, 255]) }
  end
end

def draw_section(args,section,color)
  t0          = 1.0 / RENDERING_STEPS
  key_points  = RENDERING_STEPS.times.inject([]) { |p,i| p << section.at(t0 * i) }
  key_points.each_cons(2) { |points| args.outputs.lines << points[0] + points[1] + color }
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

