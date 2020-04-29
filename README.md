# dr_bcurve
## A Bézier curve drawing, manipulation and traversing tool for DragonRuby

![](dr_bcurve_demo.gif)

### Creating a curve :
A Bézier curve is an instance of the `Bezier::Curve` class. You can initialize it with with an array of points (called anchors in dr_bcurve terminology). An empty array works too.

```ruby
curve = Bezier::Curve.new [ [200, 200],   # first anchor
                            [300, 300] ]  # second anchor
```
![](start.png)

### Adding a point to a curve :
You can dinamically add points to curves.

```ruby
curve << [400, 200] # a third point
```
![](add.png)

### Closing and opening a curve :
You can close and open and curve.

```ruby
curve.close
curve.is_closed # => true
```
![](closed.png)

```ruby
curve.open
curve.is_closed # => false
```
![](add.png)

### Controls :
Upon instantiation of a new curve, adding a point or closing a curve, controls (red and blue) are created to manipulate the curve around each anchor. When created, those controls are automatically set to somewhat standard balanced position. You can manipulate those controls to reshape the curve.

![](unaligned.png)

You can rebalance the control points for an anchor.

```ruby
curve.balance 1  # balancing anchor 1
```
will bring you back to:\
![](add.png)

### Traversing a curve :
You can linearly traverse a curve. Traversing requires the curve to be split in smaller parts. For curves that roughly fit a 1280x720 screen, spliting each section in 25 is a good value.

```ruby
curve.prepare_traversing 25
first   = curve.at(0.0) # a point at the very beginning of the curve
middle  = curve.at(0.5) # a point at the middle of the curve
last    = curve.at(1.0) # a point at the very end of the curve
```
