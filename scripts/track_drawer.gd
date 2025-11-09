extends Node

var root

func init(r):
	root = r

func draw_track(input_str: String):
	var track_static = root.track
	var line2d = root.line2d
	for child in track_static.get_children():
		if child is CollisionShape2D:
			child.queue_free()

	var expr = Expression.new()
	if expr.parse(input_str, ["x"]) != OK:
		return

	var points = []
	var step = (root.utils.x_max - root.utils.x_min) / 100.0
	for i in range(101):
		var x = root.utils.x_min + i * step
		var y = expr.execute([x])
		points.append(Vector2(root.utils.fx_to_screen(x), root.utils.fy_to_screen(y)))

	line2d.points = points

	for i in range(points.size() - 1):
		var seg = SegmentShape2D.new()
		seg.a = points[i]
		seg.b = points[i + 1]
		var col = CollisionShape2D.new()
		col.shape = seg
		track_static.add_child(col)
