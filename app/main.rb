require '/lib/trigo.rb'
require '/lib/anchor.rb'
require '/lib/section.rb'
require '/lib/curve.rb'





### Constants :
GRAB_DISTANCE     = 10.0
RENDERING_STEPS   = 25
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

  ## Setup :
  setup(args) unless args.state.setup_done


  ## User input :
  case args.state.mode

  ## DRAW MODE :
  when :draw
    # Clicking adds an anchor :
    if args.inputs.mouse.click then
      new_anchor  = Bezier::Anchor.new( args.inputs.mouse.click.point.x,
                                        args.inputs.mouse.click.point.y )
      if args.state.curve.nil? then
        args.state.curve  = Bezier::Curve.new [ new_anchor ]
      else
        args.state.curve << new_anchor
      end
    end

    # Pressing 'e' bar switches to EDIT mode :
    if args.inputs.keyboard.key_down.e then
      args.state.grabed = nil
      args.state.mode   = :edit
    end

    # Pressing 'c' will CLOSE the Bézier patch :
    args.state.curve.close if args.inputs.keyboard.key_down.c

    # Pressing 'o' will OPEN the Bézier patch :
    args.state.curve.open if args.inputs.keyboard.key_down.o

    # Pressing 't' switches to TRAVERSING mode:
    if args.inputs.keyboard.key_down.t then
      args.state.curve.prepare_traversing RENDERING_STEPS

      args.state.grabed = nil
      args.state.mode   = :traversing
      args.state.t      = 0.5
    end

    args.outputs.labels << [20, 670, "mouse: #{args.inputs.mouse.x.to_i};#{args.inputs.mouse.y.to_i} - mode: #{args.state.mode.to_s}"]


  ## EDIT MODE :
  when :edit
    # Clicking grabs the closest point or control ( if it is close enough ) and ...
    # ... cliking + control will straighten the curve at the clicked point.
    if args.inputs.mouse.click
      if args.state.grabed.nil? then
        anchors_distances   = args.state.curve.anchors.map.with_index do |anchor,index|
                                {  distance: Bezier::Trigo::magnitude(anchor.coords, [args.inputs.mouse.x, args.inputs.mouse.y]),
                                   index:    index }
                              end
        closest_anchor      = anchors_distances.sort! { |pd1,pd2| pd1[:distance] <=> pd2[:distance] }.first

        handle_distances    = args.state.curve.anchors.map.with_index do |anchor,index|
                                [ { distance: Bezier::Trigo::magnitude(anchor.left_handle.coords, [args.inputs.mouse.x, args.inputs.mouse.y]),
                                    index:    index,
                                    side:     :left },
                                  { distance: Bezier::Trigo::magnitude(anchor.right_handle.coords, [args.inputs.mouse.x, args.inputs.mouse.y]),
                                    index:    index,
                                    side:     :right } ]
                              end
        closest_handle      = handle_distances.flatten.sort! { |cd1,cd2| cd1[:distance] <=> cd2[:distance] }.first

        if closest_anchor[:distance] <= closest_handle[:distance] && closest_anchor[:distance] < GRAB_DISTANCE then
          if args.inputs.keyboard.key_held.b then   # the 'b' key held down will balance the ...
                                                    # ... curve at the clicked anchor.
            args.state.curve.balance_at closest_anchor[:index]
          
          else                                      # Simple click will grab the anchor and its ...
                                                    # ... local handles or just a handle.
            args.state.grabed = { type:   :anchor,
                                  index:  closest_anchor[:index] }

            anchor  = args.state.curve.anchors[closest_anchor[:index]]
            args.state.grabed[:left_handle_offset]  = [ anchor.left_handle.x - anchor.x,
                                                        anchor.left_handle.y - anchor.y ]
            args.state.grabed[:right_handle_offset] = [ anchor.right_handle.x - anchor.x,
                                                        anchor.right_handle.y - anchor.y ]
          end

        elsif closest_anchor[:distance] > closest_handle[:distance] && closest_handle[:distance] < GRAB_DISTANCE
          args.state.grabed = { type:   :handle,
                                index:  closest_handle[:index],
                                side:   closest_handle[:side] }

        end

      else
        args.state.grabed = nil
        args.state.curve.compute_length

      end
    end

    unless args.state.grabed.nil? then
      if args.state.grabed[:type] == :anchor then
        anchor    = args.state.curve.anchors[args.state.grabed[:index]]

        anchor.x  = args.inputs.mouse.x
        anchor.y  = args.inputs.mouse.y

        anchor.left_handle.x  = args.inputs.mouse.x + args.state.grabed[:left_handle_offset][0]
        anchor.left_handle.y  = args.inputs.mouse.y + args.state.grabed[:left_handle_offset][1]

        anchor.right_handle.x = args.inputs.mouse.x + args.state.grabed[:right_handle_offset][0]
        anchor.right_handle.y = args.inputs.mouse.y + args.state.grabed[:right_handle_offset][1]

      elsif args.state.grabed[:type] == :handle then
        handle =  if args.state.grabed[:side] == :left then
                    args.state.curve.anchors[args.state.grabed[:index]].left_handle
                  else
                    args.state.curve.anchors[args.state.grabed[:index]].right_handle
                  end

        handle.x = args.inputs.mouse.x
        handle.y = args.inputs.mouse.y
      
      end

      args.outputs.labels << [20, 640, "grabed #{args.state.grabed[:type].to_s} #{args.state.grabed[:index]}" ]
    end

    # Pressing 'd' switches to DRAW mode :
    if args.inputs.keyboard.key_down.d then
      args.state.grabed = nil
      args.state.mode   = :draw
    end

    # Pressing 't' witches to TRAVERSING mode:
    if args.inputs.keyboard.key_down.t then
      args.state.curve.prepare_traversing RENDERING_STEPS

      args.state.grabed = nil
      args.state.mode   = :traversing
      args.state.t      = 0.5
    end


    args.outputs.labels << [20, 670, "mouse: #{args.inputs.mouse.x.to_i};#{args.inputs.mouse.y.to_i} - mode: #{args.state.mode.to_s} (click to grab a point or control; click+b on anchor to straigthen curve)"]


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

    args.state.mode = :draw if args.inputs.keyboard.key_down.d
    args.state.mode = :edit if args.inputs.keyboard.key_down.e

    # Drawing :
    point = args.state.curve.coords_at args.state.t
    draw_cross args, point, [255, 0, 0, 255]

    args.outputs.labels << [20, 670, "mouse: #{args.inputs.mouse.x.to_i};#{args.inputs.mouse.y.to_i} - mode: #{args.state.mode.to_s} t = #{args.state.t} -> (#{point[0].to_i},#{point[1].to_i}) (use left and right or up and down arrows to move)"]

  end


  # Render :
  unless args.state.curve.nil? then
    draw_curve args, args.state.curve, [150, 150, 150, 255]
  end

  args.outputs.labels << [20, 700, "Press 'd': draw the curve - Press 'e': edit the curve - Press 't': traverse the curve"]

end





### Drawing :
def draw_curve(args,curve,color)
  ## Anchors :
  curve.anchors.each { |anchor| draw_square args, anchor.center, [0, 0, 0, 255] }

  if curve.anchors.length > 1 then
    ## Segments :
    curve.anchors.each_cons(2) do |anchors|
      args.outputs.lines << [ anchors[0].x, anchors[0].y, anchors[1].x, anchors[1].y ] + color
    end

    ## Controls :
    curve.anchors.each.with_index do |anchor,index|
      # Left handle :
      if curve.is_closed || index > 0 then
        draw_square args, anchor.left_handle, [0, 0, 255, 255]
        args.outputs.lines << [ anchor.x, anchor.y, anchor.left_handle.x, anchor.left_handle.y, 200, 200, 255, 255 ]
      end

      # Right handle :
      if curve.is_closed || index < curve.anchors.length - 1 then
        draw_square args, anchor.right_handle, [255, 0, 0, 255]
        args.outputs.lines << [ anchor.x, anchor.y, anchor.right_handle.x, anchor.right_handle.y, 200, 200, 255, 255 ]
      end
    end

    ## Sections :
    curve.sections.each { |section| draw_section(args, section, [0, 0, 255, 255]) }
  end
end

def draw_section(args,section,color)
  t0          = 1.0 / RENDERING_STEPS
  key_points  = RENDERING_STEPS.times.inject([]) { |p,i| p << section.coords_at(t0 * i) }
  key_points.each_cons(2) { |points| args.outputs.lines << points[0] + points[1] + color }
end





### Tools :
def draw_cross(args,coords,color)
  args.outputs.lines << [coords[0]-10, coords[1]+10, coords[0]+11, coords[1]-11] + color
  args.outputs.lines << [coords[0]-10, coords[1]-10, coords[0]+11, coords[1]+11] + color
end

def draw_small_cross(args,coords,color)
  args.outputs.lines << [coords[0]-1, coords[1], coords[0]+2, coords[1]] + color
  args.outputs.lines << [coords[0], coords[1]-1, coords[0], coords[1]+2] + color
end

def draw_square(args,point,color)
  args.outputs.solids << [ point.x - 2, point.y - 2, 5, 5 ] + color
end

