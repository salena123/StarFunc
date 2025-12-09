extends Node

var root
var LevelScript = preload("res://scripts/level_generator.gd")
var intersection_x: float = NAN
var primary_func_cached: String = ""
var secondary_func_cached: String = ""

func init(r):
	root = r


func set_intersection(x: float):
	intersection_x = x


func prepare_new_level(primary_func: String) -> Dictionary:
	return _build_state(primary_func, "", NAN, [], [], false)


func prepare_from_saved(primary_func: String, secondary_func: String, options_a: Array, options_b: Array, intersection_hint: float) -> Dictionary:
	return _build_state(primary_func, secondary_func, intersection_hint, options_a, options_b, true)


func apply_ui(options_a: Array, options_b: Array):
	print("[DOUBLE_LINEAR] apply_ui: options_a.size() = ", options_a.size(), ", options_b.size() = ", options_b.size())
	# if root.input_panel:
	#	root.input_panel.visible = false
	if root.build_button:
		root.build_button.disabled = false
	
	# Сначала скрыть все OptionX в обоих столбцах
	var buttons1_node = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons1")
	var buttons2_node = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons2")
	
	# Скрыть все в Buttons1
	if buttons1_node:
		buttons1_node.show()
		for i in range(3):
			var option_node = buttons1_node.get_node_or_null("Option" + str(i))
			if option_node:
				option_node.visible = false
	
	# Скрыть все в Buttons2
	if buttons2_node:
		buttons2_node.show()
		for i in range(3):
			var option_node = buttons2_node.get_node_or_null("Option" + str(i))
			if option_node:
				option_node.visible = false
	
	# Показать только нужные варианты в Buttons1
	if buttons1_node:
		for i in range(min(3, options_a.size())):
			var option_node = buttons1_node.get_node_or_null("Option" + str(i))
			if option_node:
				option_node.visible = true
				# Показать дочерние элементы
				for child in option_node.get_children():
					if child is CanvasItem:
						child.visible = true
				# Обновить текст и сбросить чекбокс
				var label = option_node.get_node_or_null("FormulaLabel")
				if label:
					label.text = root.utils.format_function_from_string(options_a[i])
				var cb = option_node.get_node_or_null("CheckButton")
				if cb:
					cb.button_pressed = false
					cb.disabled = false
	
	# Показать только нужные варианты в Buttons2
	if buttons2_node:
		for i in range(min(3, options_b.size())):
			var option_node = buttons2_node.get_node_or_null("Option" + str(i))
			if option_node:
				option_node.visible = true
				# Показать дочерние элементы
				for child in option_node.get_children():
					if child is CanvasItem:
						child.visible = true
				# Обновить текст и сбросить чекбокс
				var label = option_node.get_node_or_null("FormulaLabel")
				if label:
					label.text = root.utils.format_function_from_string(options_b[i])
				var cb = option_node.get_node_or_null("CheckButton")
				if cb:
					cb.button_pressed = false
					cb.disabled = false
	
	if root.has_node("UI/BottomLayout/Panel/Items/Answers"):
		root.get_node("UI/BottomLayout/Panel/Items/Answers").show()


func draw_tracks(primary_func: String, secondary_func: String):
	if root == null or root.track_drawer == null or root.utils == null:
		return
	primary_func_cached = primary_func
	secondary_func_cached = secondary_func
	var expr_a = Expression.new()
	var expr_b = Expression.new()
	if expr_a.parse(primary_func, ["x"]) == OK and expr_b.parse(secondary_func, ["x"]) == OK:
		root.utils.setup_double_level_positions(expr_a, expr_b)
	var range_a = get_segment_range(0)
	var range_b = get_segment_range(1)
	root.track_drawer.draw_track_with_bounds(primary_func, range_a.x, range_a.y)
	root.track_drawer.draw_track_secondary_with_bounds(secondary_func, range_b.x, range_b.y)
	if root.track:
		root.track.visible = false
	if root.track2:
		root.track2.visible = false


func get_segment_range(group: int) -> Vector2:
	var x_pos = _ensure_intersection_available()
	if root == null or root.utils == null:
		return Vector2.ZERO
	var start = root.utils.x_min
	var end = x_pos
	if group == 1:
		start = x_pos
		end = root.utils.x_max
	start = clamp(start, root.utils.x_min, root.utils.x_max)
	end = clamp(end, root.utils.x_min, root.utils.x_max)
	if start > end:
		var tmp = start
		start = end
		end = tmp
	if is_equal_approx(start, end):
		if group == 0:
			end += 0.01
		else:
			start -= 0.01
		start = clamp(start, root.utils.x_min, root.utils.x_max)
		end = clamp(end, root.utils.x_min, root.utils.x_max)
	return Vector2(start, end)


func get_intersection() -> float:
	return _ensure_intersection_available()


func _build_state(primary_func: String, secondary_func: String, intersection_hint: float, options_a: Array, options_b: Array, preserve_options: bool) -> Dictionary:
	if primary_func == "":
		primary_func = "0.5*x"
	var ensured = _ensure_functions(primary_func, secondary_func, intersection_hint)
	primary_func_cached = ensured.primary
	secondary_func_cached = ensured.secondary
	intersection_x = ensured.intersection
	var opts_a = options_a.duplicate()
	var opts_b = options_b.duplicate()
	if opts_a.is_empty():
		opts_a = root.level_gen.generate_options_for_type(LevelScript.LevelType.SIMPLE, primary_func_cached)
	if opts_b.is_empty():
		opts_b = root.level_gen.generate_options_for_type(LevelScript.LevelType.SIMPLE, secondary_func_cached)
	_ensure_three_options(opts_a)
	_ensure_three_options(opts_b)
	if not preserve_options:
		opts_a.shuffle()
		opts_b.shuffle()
	return {
		"primary": primary_func_cached,
		"secondary": secondary_func_cached,
		"intersection": intersection_x,
		"options_primary": opts_a,
		"options_secondary": opts_b
	}


func _ensure_functions(primary_func: String, secondary_func: String, intersection_hint: float) -> Dictionary:
	var secondary = secondary_func
	var intersection = intersection_hint
	if secondary == "":
		var generated = _generate_second_linear_function(primary_func)
		secondary = generated.func
		intersection = generated.intersection
	else:
		intersection = _calculate_intersection_x(primary_func, secondary)
		if intersection == null or not _is_intersection_valid(intersection):
			var regen = _generate_second_linear_function(primary_func)
			secondary = regen.func
			intersection = regen.intersection
	if not _is_intersection_valid(intersection):
		intersection = _fallback_intersection()
	return {
		"primary": primary_func,
		"secondary": secondary,
		"intersection": intersection
	}


func _generate_second_linear_function(base_func: String) -> Dictionary:
	var fallback = {
		"func": _generate_valid_linear_function([base_func]),
		"intersection": _fallback_intersection()
	}
	var base_params = _extract_linear_params(base_func)
	if base_params == null or root == null or root.utils == null:
		return fallback
	var attempts = 0
	var max_attempts = 5000
	while attempts < max_attempts:
		attempts += 1
		var cand = _generate_valid_linear_function([base_func])
		var cand_params = _extract_linear_params(cand)
		if cand_params == null:
			continue
		if abs(cand_params.k - base_params.k) < 0.05:
			continue
		var intersection = (base_params.b - cand_params.b) / (cand_params.k - base_params.k)
		if not _is_intersection_valid(intersection):
			continue
		var margin = 0.5
		if intersection <= root.utils.x_min + margin or intersection >= root.utils.x_max - margin:
			continue
		var y_val = base_params.k * intersection + base_params.b
		if y_val < root.utils.y_min or y_val > root.utils.y_max:
			continue
		return {
			"func": cand,
			"intersection": intersection
		}
	return fallback


func _generate_valid_linear_function(exclusions: Array = []) -> String:
	var max_attempts = 5000
	var attempts = 0
	while attempts < max_attempts:
		attempts += 1
		var candidate = _random_linear()
		if exclusions.has(candidate):
			continue
		if root.utils and root.utils.is_level_valid_for_edges(candidate, root.ball_side):
			return candidate
	var fallback = "0.5*x"
	if exclusions.has(fallback):
		fallback = "-0.5*x"
	return fallback


func _random_linear() -> String:
	var k = 0.0
	while abs(k) < 0.3:
		k = round(randf_range(-2, 2) * 10) / 10.0
	var b = round(randf_range(-5.0, 5.0) * 10) / 10.0
	return str(k) + "*x + " + str(b)


func _calculate_intersection_x(func_a: String, func_b: String):
	if func_a == "" or func_b == "":
		return null
	var params_a = _extract_linear_params(func_a)
	var params_b = _extract_linear_params(func_b)
	if params_a == null or params_b == null:
		return null
	var denom = params_b.k - params_a.k
	if abs(denom) < 0.0001:
		return null
	return (params_a.b - params_b.b) / denom


func _extract_linear_params(func_str: String):
	var expr = Expression.new()
	if expr.parse(func_str, ["x"]) != OK:
		return null
	var b_val = expr.execute([0.0])
	var y_at_one = expr.execute([1.0])
	if typeof(b_val) == TYPE_INT:
		b_val = float(b_val)
	if typeof(y_at_one) == TYPE_INT:
		y_at_one = float(y_at_one)
	if typeof(b_val) != TYPE_FLOAT or typeof(y_at_one) != TYPE_FLOAT:
		return null
	return {
		"k": y_at_one - b_val,
		"b": b_val
	}


func _ensure_intersection_available() -> float:
	if _is_intersection_valid(intersection_x):
		return intersection_x
	if primary_func_cached != "" and secondary_func_cached != "":
		var recalculated = _calculate_intersection_x(primary_func_cached, secondary_func_cached)
		if _is_intersection_valid(recalculated):
			intersection_x = recalculated
			return intersection_x
	intersection_x = _fallback_intersection()
	return intersection_x


func _fallback_intersection() -> float:
	if root == null or root.utils == null:
		return 0.0
	return (root.utils.x_min + root.utils.x_max) * 0.5


func _is_intersection_valid(value) -> bool:
	if value == null:
		return false
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return false
	var x_val = float(value)
	if is_nan(x_val):
		return false
	if root == null or root.utils == null:
		return true
	return x_val > root.utils.x_min and x_val < root.utils.x_max


func _ensure_three_options(opts: Array):
	while opts.size() < 3:
		var fallback = _random_linear()
		if not opts.has(fallback):
			opts.append(fallback)


func _show_buttons(buttons: Array, visible: bool):
	if buttons == null:
		return
	for btn in buttons:
		if btn:
			btn.visible = visible
			if visible:
				btn.disabled = false


func _set_button_texts(buttons: Array, values: Array):
	if buttons == null:
		return
	for i in range(min(buttons.size(), values.size())):
		if buttons[i]:
			# Determine path based on which group we're setting
			var path = ""
			var parent_name = buttons[i].get_parent().name  # Option0, Option1, Option2
			var grandparent_name = ""
			if buttons[i].get_parent() and buttons[i].get_parent().get_parent():
				grandparent_name = buttons[i].get_parent().get_parent().name  # Buttons1 or Buttons2
			if grandparent_name == "Buttons1":
				path = "UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons1/Option" + str(i) + "/FormulaLabel"
			else:
				path = "UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons2/Option" + str(i) + "/FormulaLabel"
			var label = root.get_node_or_null(path)
			if label:
				label.text = root.utils.format_function_from_string(values[i])
