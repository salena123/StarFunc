extends Node

var root
var top_margin = 50
var bottom_margin = 50
var vertical_offset_pixels = 35

var x_min
var x_max
var y_min
var y_max

func init(r):
	root = r
	calc_base_unit()

func calc_base_unit():
	var screen_w = root.screen_size.x
	var screen_h = root.screen_size.y

	root.base_unit = screen_w / 20.0 

	x_min = -10
	x_max = 10

	y_min = - (screen_h - top_margin - bottom_margin) / (2 * root.base_unit)
	y_max =   (screen_h - top_margin - bottom_margin) / (2 * root.base_unit)


func fx_to_screen(x):
	return root.screen_center.x + x * root.base_unit

func fy_to_screen(y):
	var track_height = root.screen_size.y - top_margin - bottom_margin
	var t = (y - y_min) / (y_max - y_min)
	return root.screen_size.y - bottom_margin - t * track_height

func fy_to_screen_track(y):
	return fy_to_screen(y)

func _fmt(v: float) -> String:
	return str(round(v * 10.0) / 10.0)


func make_variants_varying_b(k: float, b: float, side: int) -> Array:
	var opts = []

	if not is_level_valid_for_edges(_fmt(k) + "*x + " + _fmt(b), side):
		b = clamp(b, y_min*0.8, y_max*0.8)
	opts.append(_fmt(k) + "*x + " + _fmt(b))

	while opts.size() < 3:
		var delta = randf_range(-3.0, 3.0)
		if abs(delta) < 0.5:
			delta = -0.5 if delta < 0 else 0.5
		var cand = _fmt(k) + "*x + " + _fmt(b + delta)
		if not opts.has(cand):
			opts.append(cand)

	return opts

func make_variants_varying_k(k: float, b: float, side: int) -> Array:
	var opts = []

	if not is_level_valid_for_edges(_fmt(k) + "*x + " + _fmt(b), side):
		b = clamp(b, y_min*0.8, y_max*0.8)
	opts.append(_fmt(k) + "*x + " + _fmt(b))
	while opts.size() < 3:
		var delta = randf_range(-1.5, 1.5)
		if abs(delta) < 0.2:
			delta = -0.2 if delta < 0 else 0.2
		var new_k = k + delta
		var cand = _fmt(new_k) + "*x + " + _fmt(b)
		if not opts.has(cand):
			opts.append(cand)

	return opts

func is_level_valid_for_edges(func_str: String, desired_side: int) -> bool:
	var expr = Expression.new()
	if expr.parse(func_str, ["x"]) != OK:
		return false

	var margin_top = top_margin + vertical_offset_pixels
	var margin_bottom = bottom_margin + vertical_offset_pixels

	var y_left = expr.execute([x_min])
	var y_right = expr.execute([x_max])
	if typeof(y_left) != TYPE_FLOAT or typeof(y_right) != TYPE_FLOAT:
		return false

	var y_left_px = fy_to_screen(y_left)
	var y_right_px = fy_to_screen(y_right)

	if y_left_px < margin_top or y_left_px > root.screen_size.y - margin_bottom:
		return false
	if y_right_px < margin_top or y_right_px > root.screen_size.y - margin_bottom:
		return false

	var k = y_right - y_left
	var Side = preload("res://scripts/level_generator.gd").Side
	if abs(k) < 0.05:
		return false
	if desired_side == Side.RIGHT and k <= 0:
		return false
	if desired_side == Side.LEFT and k >= 0:
		return false

	return true

func setup_level_positions(expr: Expression):
	var num_stars = root.stars.size()
	var margin_px = 40.0
	var min_star_spacing_px = 60.0

	var x_start_screen = margin_px
	var x_end_screen = root.screen_size.x - margin_px

	var fx_start = (x_start_screen - root.screen_center.x) / root.base_unit
	var fx_end = (x_end_screen - root.screen_center.x) / root.base_unit

	var ball_x: float
	var exit_x: float
	if root.ball_side == root.level_gen.Side.RIGHT:
		ball_x = fx_end
		exit_x = fx_start
	else:
		ball_x = fx_start
		exit_x = fx_end

	var exit_y = clamp(expr.execute([exit_x]), y_min, y_max)

	root.ball.position = Vector2(fx_to_screen(ball_x), top_margin + vertical_offset_pixels)
	root.exit.position = Vector2(fx_to_screen(exit_x), fy_to_screen(exit_y) - vertical_offset_pixels)

	var star_positions = []
	var step_px = (x_end_screen - x_start_screen) / float(num_stars + 1)

	for i in range(num_stars):
		var base_px = x_start_screen + (i + 1) * step_px
		var offset_px = randf_range(-step_px * 0.3, step_px * 0.3)
		var x_screen = clamp(base_px + offset_px, x_start_screen, x_end_screen)

		if i > 0 and abs(x_screen - star_positions[-1]) < min_star_spacing_px:
			x_screen = star_positions[-1] + min_star_spacing_px
		star_positions.append(x_screen)

		var fx_val = (x_screen - root.screen_center.x) / root.base_unit
		var fy_val = clamp(expr.execute([fx_val]), y_min, y_max)

		root.stars[i].visible = true
		root.stars[i].position = Vector2(x_screen, fy_to_screen(fy_val) - vertical_offset_pixels)

	print("DEBUG stars: ball_x=", ball_x, " exit_x=", exit_x)
	print("DEBUG fx_start=", fx_start, " fx_end=", fx_end)
	print("DEBUG expr test: y(0)=", expr.execute([0]))


func on_forward_pressed(root, forward_button, option_buttons):
	if root.first_selection_done:
		return
	root.first_selection_done = true
	root.ball.freeze = false
	root.ball.apply_impulse(Vector2.ZERO, Vector2(0, 50))

	forward_button.hide()

	for btn in option_buttons:
		if btn:
			btn.disabled = true

func enable_option_buttons(root):
	for btn in root.option_buttons:
		if btn:
			btn.disabled = false
