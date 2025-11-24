extends Node

var root

func init(r):
	root = r

func draw_track(input_str: String):
	if root == null or root.track == null or root.line2d == null:
		return
	if root.utils == null:
		push_warning("TrackDrawer: utils not initialized; cannot draw track")
		return
	if not root.utils.ensure_coordinate_bounds():
		push_warning("TrackDrawer: coordinate bounds are not ready; skipping track draw")
		return

	var track_static = root.track
	var line2d = root.line2d
	for child in track_static.get_children():
		if child is CollisionShape2D:
			child.queue_free()

	var expr = Expression.new()
	if expr.parse(input_str, ["x"]) != OK:
		return

	var points = []
	var span = root.utils.x_max - root.utils.x_min
	if is_equal_approx(span, 0.0):
		span = 20.0
	var step = span / 100.0
	for i in range(101):
		var x = root.utils.x_min + i * step
		var y = expr.execute([x])
		var y_type = typeof(y)
		if y_type == TYPE_INT:
			y = float(y)
		elif y_type != TYPE_FLOAT:
			push_warning("TrackDrawer: expression returned unsupported type (%s) for x=%s, using fallback 0." % [y_type, x])
			y = 0.0
		points.append(Vector2(root.utils.fx_to_screen(x), root.utils.fy_to_screen(y)))

	if points.is_empty():
		push_warning("TrackDrawer: no valid points generated for '%s'" % input_str)
		return

	line2d.points = points

	for i in range(points.size() - 1):
		var seg = SegmentShape2D.new()
		seg.a = points[i]
		seg.b = points[i + 1]
		var col = CollisionShape2D.new()
		col.shape = seg
		track_static.add_child(col)
