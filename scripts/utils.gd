extends Node

var root
var top_margin = 50
var bottom_margin = 50
var vertical_offset_pixels = 15

var x_min: float = -10.0
var x_max: float = 10.0
var y_min: float = -5.0
var y_max: float = 5.0

func init(r):
	root = r
	calc_base_unit()

func calc_base_unit():
	if root == null:
		push_warning("Utils.calc_base_unit called before utils.init; skipping")
		return

	var screen_size_val = root.screen_size
	if screen_size_val == null:
		if root.has_method("get_viewport_rect"):
			screen_size_val = root.get_viewport_rect().size
		else:
			screen_size_val = Vector2(800, 600)

	var screen_w = float(screen_size_val.x)
	var screen_h = float(screen_size_val.y)

	if screen_w <= 0.0:
		screen_w = 800.0

	root.base_unit = screen_w / 20.0 
	if root.base_unit == 0.0:
		root.base_unit = 1.0

	x_min = -10.0
	x_max = 10.0

	var vertical_span = screen_h - top_margin - bottom_margin
	if vertical_span <= 0.0:
		vertical_span = 100.0

	y_min = -vertical_span / (2.0 * root.base_unit)
	y_max = vertical_span / (2.0 * root.base_unit)


func ensure_coordinate_bounds() -> bool:
	if root == null:
		push_warning("Utils not initialized yet; coordinate conversion skipped")
		return false

	if root.base_unit == null or root.base_unit == 0.0 or y_min == null or y_max == null:
		calc_base_unit()
	return root.base_unit != null and root.base_unit != 0.0 and y_min != null and y_max != null


func fx_to_screen(x):
	if not ensure_coordinate_bounds():
		return 0.0
	return root.screen_center.x + x * root.base_unit

func fy_to_screen(y):
	if not ensure_coordinate_bounds():
		return 0.0
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

	var ball_spawn_y_px = top_margin + vertical_offset_pixels
	var ball_radius_px = 0.0

	if root.ball.has_node("CollisionShape2D"):
		var col_shape = root.ball.get_node("CollisionShape2D")
		if col_shape.shape is CircleShape2D:
			ball_radius_px = col_shape.shape.radius

	var safe_gap_px = ball_radius_px
	print("ball_radius_px =", ball_radius_px)
	print("safe_gap_px =", safe_gap_px)
	if desired_side == Side.RIGHT:
		if y_right_px < ball_spawn_y_px + safe_gap_px:
			return false
	elif desired_side == Side.LEFT:
		if y_left_px < ball_spawn_y_px + safe_gap_px:
			return false

	return true

func setup_level_positions(expr: Expression):
	if root == null:
		push_warning("Utils.setup_level_positions called before utils.init; skipping")
		return

	if not ensure_coordinate_bounds():
		push_warning("Cannot setup level positions without coordinate bounds")
		return

	var num_stars = root.stars.size()
	var margin_px = 40.0
	var min_star_spacing_px = 60.0

	var x_start_screen = margin_px
	var x_end_screen = root.screen_size.x - margin_px

	var fx_start = (x_start_screen - root.screen_center.x) / root.base_unit
	var fx_end = (x_end_screen - root.screen_center.x) / root.base_unit

	var ball_x: float
	if root.ball_side == root.level_gen.Side.RIGHT:
		ball_x = fx_end
	else:
		ball_x = fx_start

	root.ball.position = Vector2(fx_to_screen(ball_x), top_margin + vertical_offset_pixels)

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
		var fy_raw = expr.execute([fx_val])
		var fy_val: float
		var fy_type = typeof(fy_raw)
		if fy_type == TYPE_FLOAT:
			fy_val = clamp(fy_raw, y_min, y_max)
		elif fy_type == TYPE_INT:
			fy_val = clamp(float(fy_raw), y_min, y_max)
		else:
			push_warning("Expression evaluation returned unsupported type (%s); falling back to center line for star %s" % [fy_type, i])
			fy_val = 0.0

		root.stars[i].visible = true
		root.stars[i].position = Vector2(x_screen, fy_to_screen(fy_val) - vertical_offset_pixels)

func setup_double_level_positions(expr_a: Expression, expr_b: Expression):
	if root == null:
		push_warning("Utils.setup_double_level_positions called before utils.init; skipping")
		return
	if not ensure_coordinate_bounds():
		push_warning("Cannot setup double level positions without coordinate bounds")
		return
	var num_stars = root.stars.size()
	if num_stars == 0:
		return
	if num_stars == 1:
		setup_level_positions(expr_a)
		return
	var margin_px = 40.0
	var min_star_spacing_px = 60.0
	var x_start_screen = margin_px
	var x_end_screen = root.screen_size.x - margin_px
	var fx_start = (x_start_screen - root.screen_center.x) / root.base_unit
	var fx_end = (x_end_screen - root.screen_center.x) / root.base_unit
	var ball_x: float = fx_end if root.ball_side == root.level_gen.Side.RIGHT else fx_start
	root.ball.position = Vector2(fx_to_screen(ball_x), top_margin + vertical_offset_pixels)
	if root.double_linear_module == null:
		setup_level_positions(expr_a)
		return
	var range_a = root.double_linear_module.get_segment_range(0)
	var range_b = root.double_linear_module.get_segment_range(1)
	var counts = _split_star_counts(num_stars)
	var star_index = 0
	var prev_x = null
	var result_a = _place_segment_stars(expr_a, counts[0], range_a.x, range_a.y, star_index, prev_x)
	star_index = result_a["index"]
	prev_x = result_a["prev_x"]
	var result_b = _place_segment_stars(expr_b, counts[1], range_b.x, range_b.y, star_index, prev_x)
	star_index = result_b["index"]
	prev_x = result_b["prev_x"]
	while star_index < num_stars:
		root.stars[star_index].visible = false
		star_index += 1

func _split_star_counts(total: int) -> Array:
	if total <= 1:
		return [total, 0]
	var left = int(ceil(total / 2.0))
	var right = total - left
	if right == 0:
		right = 1
		left = max(0, left - 1)
	return [left, right]

func _place_segment_stars(expr: Expression, count: int, fx_start: float, fx_end: float, start_index: int, prev_screen_x) -> Dictionary:
	var current_index = start_index
	var last_x = prev_screen_x
	if count <= 0:
		return {"index": current_index, "prev_x": last_x}
	var screen_start = fx_to_screen(fx_start)
	var screen_end = fx_to_screen(fx_end)
	if screen_start > screen_end:
		var tmp = screen_start
		screen_start = screen_end
		screen_end = tmp
	var span_px = max(1.0, abs(screen_end - screen_start))
	var step_px = span_px / float(count + 1)
	var margin_px = 40.0
	var min_star_spacing_px = 60.0
	for i in range(count):
		if current_index >= root.stars.size():
			break
		var base_px = screen_start + (i + 1) * step_px
		var offset_px = randf_range(-step_px * 0.3, step_px * 0.3)
		var x_screen = clamp(base_px + offset_px, screen_start + margin_px * 0.1, screen_end - margin_px * 0.1)
		if last_x != null and abs(x_screen - last_x) < min_star_spacing_px:
			if x_screen >= last_x:
				x_screen = last_x + min_star_spacing_px
			else:
				x_screen = last_x - min_star_spacing_px
		x_screen = clamp(x_screen, min(screen_start, screen_end), max(screen_start, screen_end))
		last_x = x_screen
		var fx_val = (x_screen - root.screen_center.x) / root.base_unit
		var fy_raw = expr.execute([fx_val])
		var fy_val: float = 0.0
		var fy_type = typeof(fy_raw)
		if fy_type == TYPE_FLOAT:
			fy_val = clamp(fy_raw, y_min, y_max)
		elif fy_type == TYPE_INT:
			fy_val = clamp(float(fy_raw), y_min, y_max)
		else:
			fy_val = 0.0
		root.stars[current_index].visible = true
		root.stars[current_index].position = Vector2(x_screen, fy_to_screen(fy_val) - vertical_offset_pixels)
		current_index += 1
	return {"index": current_index, "prev_x": last_x}

func on_forward_pressed(root, forward_button, option_buttons):
	if root.first_selection_done:
		return
	root.first_selection_done = true
	root.ball.freeze = false
	root.ball.apply_impulse(Vector2.ZERO, Vector2(0, 50))

	var lvl_type = root.level_gen.get_level_type(root.level)
	if lvl_type == root.level_gen.LevelType.INPUT_LINEAR or lvl_type == root.level_gen.LevelType.INPUT_SLIDER:
		if root.build_button:
			root.build_button.disabled = true

func enable_option_buttons(root):
	# Включить CheckButton для обычных уровней
	for cb in root.option_check_buttons:
		if cb:
			cb.disabled = false
	# Включить старые кнопки для DOUBLE_LINEAR
	for btn in root.option_buttons:
		if btn:
			btn.disabled = false
	if root.option_buttons2:
		for btn in root.option_buttons2:
			if btn:
				btn.disabled = false
			
func format_function_from_string(func_str: String) -> String:
	var s = func_str.replace(" ", "")

	if s.find("*x*x") != -1:
		var x2_pos = s.find("*x*x")
		var a_str = s.substr(0, x2_pos)
		var rest = s.substr(x2_pos + 4, s.length() - (x2_pos + 4))

		var a = float(a_str)
		var b = 0.0
		var c = 0.0

		if rest != "":
			rest = rest.replace("+-", "-")
			rest = rest.replace("-+", "-")
			rest = rest.replace("--", "+")

			var regex = RegEx.new()
			regex.compile("([+-]?[0-9.]+)\\*x")
			var b_match = regex.search(rest)
			if b_match != null:
				b = float(b_match.get_string(1))
				rest = rest.replace(b_match.get_string(0), "")

			if rest != "":
				c = float(rest)

		return format_quadratic(a, b, c)

	elif s.find("*sin(") != -1:
		var mult_pos = s.find("*sin(")
		var A = float(s.substr(0, mult_pos))
		var inner = s.substr(mult_pos + 5, s.length() - (mult_pos + 5 - 1))
		return format_sin(A, inner)

	elif s.find("*cos(") != -1:
		var mult_pos = s.find("*cos(")
		var A = float(s.substr(0, mult_pos))
		var inner = s.substr(mult_pos + 5, s.length() - (mult_pos + 5 - 1))
		return format_cos(A, inner)

	elif s.find("*x") != -1:
		var x_pos = s.find("*x")
		var k_str = s.substr(0, x_pos)
		var b_str = s.substr(x_pos + 2, s.length() - (x_pos + 2))

		var k = float(k_str)
		var b = 0.0

		if b_str.begins_with("+"):
			b = float(b_str.substr(1, b_str.length() - 1))
		elif b_str.begins_with("-"):
			b = -float(b_str.substr(1, b_str.length() - 1))
		elif b_str != "":
			b = float(b_str)

		return format_linear(k, b)

	else:
		return func_str

func format_number(n: float) -> String:
	if is_equal_approx(n, int(n)):
		return str(int(n))
	return str(round(n * 100) / 100.0)

func format_linear(k: float, b: float) -> String:
	var k_str = format_number(k) + "x"
	var b_str = ""
	if b > 0:
		b_str = " + " + format_number(b)
	elif b < 0:
		b_str = " - " + format_number(abs(b))
	return "y = " + k_str + b_str

func format_quadratic(a: float, b: float, c: float) -> String:
	var a_str = format_number(a) + "x²"
	var b_str = ""
	if b > 0:
		b_str = " + " + format_number(b) + "x"
	elif b < 0:
		b_str = " - " + format_number(abs(b)) + "x"

	var c_str = ""
	if c > 0:
		c_str = " + " + format_number(c)
	elif c < 0:
		c_str = " - " + format_number(abs(c))

	return "y = " + a_str + b_str + c_str

func format_sin(A: float, inner: String) -> String:
	var A_str = format_number(A)
	return "y = " + A_str + "*sin(" + inner + ")"

func format_cos(A: float, inner: String) -> String:
	var A_str = format_number(A)
	return "y = " + A_str + "*cos(" + inner + ")"


func on_build_button_pressed(root, k_input, b_input, track_drawer, track, forward_button_input, level_gen):
	var lvl_type = level_gen.get_level_type(root.level)
	var k_val: float
	var b_val: float
	
	if lvl_type == level_gen.LevelType.INPUT_SLIDER:
		if not root.k_slider or not root.b_slider:
			if root.error_label:
				root.error_label.text = "Слайдеры не найдены"
				root.error_label.show()
			return
		k_val = root.k_slider.value
		b_val = root.b_slider.value
		var func_str = str(k_val) + "*x + " + str(b_val)
		_build_function(root, func_str, track_drawer, track, forward_button_input)
	else:
		var k_text = k_input.text.strip_edges()
		var b_text = b_input.text.strip_edges()

		if k_text == "" or b_text == "":
			if root.error_label:
				root.error_label.text = "Введите значения k и b"
				root.error_label.show()
			print("Введите значения k и b")
			return

		var k_val_input = float(k_text)
		var b_val_input = float(b_text)
		var func_str = str(k_val_input) + "*x + " + str(b_val_input)
		_build_function(root, func_str, track_drawer, track, forward_button_input)

func _build_function(root, func_str: String, track_drawer, track, forward_button_input):
	print("Построена функция:", func_str)
	if root.error_label:
		root.error_label.hide()
	
	var expr = Expression.new()
	if expr.parse(func_str, ["x"]) == OK:
		track_drawer.draw_track(func_str)
		track.visible = true
		forward_button_input.show()
		
		if not root.first_selection_done:
			if root.timer and root.timer.is_stopped():
				root.timer.wait_time = root.timer_duration
				root.timer.start()
				if root.timer_label:
					root.timer_label.text = "Таймер: " + str(root.timer_duration)
	else:
		if root.error_label:
			root.error_label.text = "Ошибка: не удалось разобрать выражение"
			root.error_label.show()
		print("Ошибка: не удалось разобрать выражение")
		
		
func clear_ui_before_level_load():

	if root.k_slider:
		root.k_slider.visible = false
	if root.b_slider:
		root.b_slider.visible = false
	if root.k_slider_label:
		root.k_slider_label.visible = false
	if root.b_slider_label:
		root.b_slider_label.visible = false
	if root.k_value_label:
		root.k_value_label.visible = false
		root.k_value_label.text = ""
	if root.b_value_label:
		root.b_value_label.visible = false
		root.b_value_label.text = ""
	if root.k_input:
		root.k_input.visible = false
	if root.b_input:
		root.b_input.visible = false

	if root.has_node("UI/Slider"):
		root.get_node("UI/Slider").visible = false

	# прячем/сбрасываем чекбоксы
	for cb in root.option_check_buttons:
		if cb:
			cb.button_pressed = false
			cb.disabled = true
	# прячем контейнеры кнопок
	var buttons1_node = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/Buttons1")
	if buttons1_node:
		buttons1_node.hide()
	var buttons2_node = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/Buttons2")
	if buttons2_node:
		buttons2_node.hide()

	if root.has_node("UI/Buttons2"):
		root.get_node("UI/Buttons2").hide()

	if root.has_node("UI/BottomLayout/Panel/Items/ForwardButton"):
		root.get_node("UI/BottomLayout/Panel/Items/ForwardButton").disabled = false
		root.get_node("UI/BottomLayout/Panel/Items/ForwardButton").show()

	if root.forward_button_input:
		root.forward_button_input.hide()
