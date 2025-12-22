extends Node

var root
var options = []
var options_secondary = []
var current_correct_func = ""
var current_correct_func_b = ""
var double_intersection_x: float = NAN
var is_level_loaded_from_save: bool = false
var current_level_type: LevelType = LevelType.SIMPLE

enum FuncType { LINEAR, QUADRATIC, SIN, COS }
enum Side { LEFT, RIGHT }

enum LevelType {
	SIMPLE,         # просто случайные функции
	VARY_B,         # одинаковое k, разные b
	VARY_K,         # одинаковое b, разные k
	QUADRATIC,      # квадратичные функции
	TRIG,           # синусы и косинусы
	INPUT_LINEAR,   # линейные с пользовательским вводом (текстовые поля)
	INPUT_SLIDER,   # линейные с пользовательским вводом (слайдеры)
	DOUBLE_LINEAR   # два графика
}

func level_type_to_name(lvl_type: int) -> String:
	for k in LevelType.keys():
		if int(LevelType[k]) == int(lvl_type):
			return str(k)
	return str(lvl_type)

var TaskText = {
	"SIMPLE": "задание для увроня SIMPLE",
	"VARY_B": "задание для увроня VARY_B",
	"VARY_K": "задание для увроня VARY_K",
	"INPUT_LINEAR": "задание для увроня INPUT_LINEAR",
	"INPUT_SLIDER": "задание для увроня INPUT_SLIDER",
	"DOUBLE_LINEAR": "задание для увроня DOUBLE_LINEAR",
	"QUADRATIC": "задание для увроня QUADRATIC",
	"TRIG": "задание для увроня TRIG",
}

func _apply_task_text_for_level_type(lvl_type: int) -> void:
	if root == null:
		return
	var label = root.get_node_or_null("UI/BottomLayout/Items/Items/HBoxContainer/Label")
	if label == null:
		return
	var key := level_type_to_name(int(lvl_type))
	var text_val := ""
	if TaskText.has(key):
		text_val = str(TaskText[key])
	else:
		text_val = str(key)
	label.text = text_val

func init(r):
	root = r
	if root.utils:
		root.utils.calc_base_unit()

func get_level_type(level: int) -> LevelType:
	if level <= 3: 
		return LevelType.INPUT_SLIDER
	elif level <= 6: 
		return LevelType.VARY_B
	elif level <= 9:
		return LevelType.VARY_K
	elif level <= 12:
		return LevelType.INPUT_LINEAR
	elif level <= 15: 
		return LevelType.INPUT_SLIDER
	elif level <= 18:
		return LevelType.DOUBLE_LINEAR
	elif level <= 21:
		return LevelType.QUADRATIC
	elif level <= 35:
		return LevelType.TRIG
	else:
		var cycle = ((level - 1) % 25) + 1
		return get_level_type(cycle)

func load_saved_level(level_number: int) -> bool:
	if not root.level_saver:
		is_level_loaded_from_save = false
		return false
	root.utils.clear_ui_before_level_load()
	var LevelSaver = root.level_saver
	var level_data = LevelSaver.load_level(level_number)
	if level_data == null:
		is_level_loaded_from_save = false
		return false
	var saved_type_str := ""
	if "level_type_name" in level_data and str(level_data.level_type_name) != "":
		saved_type_str = str(level_data.level_type_name)
	else:
		saved_type_str = level_type_to_name(int(level_data.level_type))
	
	is_level_loaded_from_save = true
	current_correct_func = level_data.correct_func
	current_correct_func_b = level_data.correct_func_b
	options = level_data.options.duplicate() if level_data.options is Array else []
	options_secondary = level_data.options_b.duplicate() if level_data.options_b is Array else []
	root.ball_side = level_data.ball_side
	double_intersection_x = level_data.double_intersection_x
	current_level_type = level_data.level_type if "level_type" in level_data else get_level_type(level_number)
	
	seed(level_data.star_seed)
	
	var saved_lvl_type = level_data.level_type
	if saved_lvl_type == null:
		saved_lvl_type = get_level_type(level_number)

	if root.has_method("apply_bottom_ui_for_level_type"):
		root.apply_bottom_ui_for_level_type(saved_lvl_type)
	_apply_task_text_for_level_type(int(saved_lvl_type))
	var expr = Expression.new()
	if saved_lvl_type != LevelType.DOUBLE_LINEAR and expr.parse(current_correct_func, ["x"]) == OK:
		root.utils.clear_ui_before_level_load()
		root.utils.setup_level_positions(expr)
	
	if root.ui:
		root.ui.update_stars_count_label()
	
	if saved_lvl_type == LevelType.INPUT_LINEAR:
		
		if root.build_button:
			root.build_button.disabled = false
		if root.x_label:
			root.x_label.text = ""
		if root.y_label:
			root.y_label.text = ""
		if root.k_value_label:
			root.k_value_label.text = ""
		if root.b_value_label:
			root.b_value_label.text = ""
	elif saved_lvl_type == LevelType.INPUT_SLIDER:
		if root.input_slider_module:
			root.input_slider_module.setup_ui_with_function(current_correct_func)
			
			if root.has_method("refresh_input_slider_value_labels"):
				root.refresh_input_slider_value_labels()
		else:
			for cb in root.option_check_buttons:
				if cb and cb is CanvasItem:
					cb.disabled = true
			if root.build_button:
				root.build_button.disabled = false
			if root.k_slider:
				root.k_slider.value = 0.0
			if root.b_slider:
				root.b_slider.value = 0.0
			if root.k_slider_label:
				root.k_slider_label.text = "0.0"
			if root.b_slider_label:
				root.b_slider_label.text = "0.0"
			if root.has_method("refresh_input_slider_value_labels"):
				root.refresh_input_slider_value_labels()
	if saved_lvl_type == LevelType.DOUBLE_LINEAR:
		var double_module = root.double_linear_module
		if double_module:
			var state = double_module.prepare_from_saved(
				current_correct_func,
				current_correct_func_b,
				options,
				options_secondary,
				double_intersection_x
			)
			current_correct_func = state.primary
			current_correct_func_b = state.secondary
			options = state.options_primary
			options_secondary = state.options_secondary
			double_intersection_x = state.intersection
			double_module.set_intersection(double_intersection_x)
			double_module.apply_ui(options, options_secondary)
			double_module.draw_tracks(current_correct_func, current_correct_func_b)
			root.utils.enable_option_buttons(root)
			
			var expr_a = Expression.new()
			var expr_b = Expression.new()
			if expr_a.parse(current_correct_func, ["x"]) == OK and expr_b.parse(current_correct_func_b, ["x"]) == OK:
				root.utils.setup_double_level_positions(expr_a, expr_b)
		else:
			push_warning("DOUBLE_LINEAR: module not initialized; cannot restore saved state")
		return true
	else:
		if options.size() > 0:
			var button_node = root.get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option0/FormulaLabel")
			if button_node:
				button_node.text = root.utils.format_function_from_string(options[0])
		if options.size() > 1:
			var button2_node = root.get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option1/FormulaLabel")
			if button2_node:
				button2_node.text = root.utils.format_function_from_string(options[1])
		if options.size() > 2:
			var button3_node = root.get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option2/FormulaLabel")
			if button3_node:
				button3_node.text = root.utils.format_function_from_string(options[2])
	
	return true


func generate_new_level():
	root.utils.clear_ui_before_level_load()
	var lvl_type = get_level_type(root.level)
	current_level_type = lvl_type 
	_apply_task_text_for_level_type(int(lvl_type))
	root.apply_bottom_ui_for_level_type(lvl_type)
		
	
	if root.k_input:
		root.k_input.clear()
	if root.b_input:
		root.b_input.clear()
	if root.k_slider:
		root.k_slider.value = 0.0
	if root.b_slider:
		root.b_slider.value = 0.0
	
	if root.k_value_label:
		root.k_value_label.text = ""
	if root.b_value_label:
		root.b_value_label.text = ""
	_reset_slider_ui()
	
	if root.timer:
		root.timer.stop()
		root.timer.paused = false
	if root.timer_label:
		root.timer_label.text = root.format_time(root.timer_duration)
	
	if root.level_saver:
		var saved = load_saved_level(root.level)
		if saved:
			root.restart.disabled = false
			root.utils.enable_option_buttons(root)
			root.track.visible = false
			root.score = 0
			root.ui.update_score_label()
			root.first_selection_done = false
			for s in root.stars:
				s.visible = true
			if root.timer:
				root.timer.stop()
			if root.timer_label:
				root.timer_label.text = "Таймер: --"
			return
	
	is_level_loaded_from_save = false
	root.restart.disabled = false
	root.utils.enable_option_buttons(root)
	root.track.visible = false
	if root.track2:
		root.track2.visible = false
		for child in root.track2.get_children():
			if child is CollisionShape2D:
				child.queue_free()
	root.score = 0
	root.ui.update_score_label()
	root.first_selection_done = false
	for s in root.stars:
		s.visible = true
	if root.timer:
		root.timer.stop()
	if root.timer_label:
		root.timer_label.text = "Таймер: --"
	options_secondary = []
	double_intersection_x = NAN


	var level_seed = randi()
	seed(level_seed)
	root.ball_side = Side.RIGHT if randi() % 2 == 0 else Side.LEFT

	

	var valid_correct_func = ""
	var used_slider_generator = false
	if lvl_type == LevelType.INPUT_SLIDER and root.input_slider_module:
		valid_correct_func = root.input_slider_module.generate_function()
		used_slider_generator = true
	
	if not used_slider_generator:
		var max_attempts = 5000
		var attempts = 0

		while valid_correct_func == "" and attempts < max_attempts:
			attempts += 1
			var func_types = []
			match lvl_type:
				LevelType.SIMPLE, LevelType.VARY_B, LevelType.VARY_K:
					func_types = [FuncType.LINEAR]
				LevelType.QUADRATIC:
					func_types = [FuncType.QUADRATIC]
				LevelType.TRIG:
					func_types = [FuncType.SIN, FuncType.COS]
				LevelType.INPUT_LINEAR, LevelType.INPUT_SLIDER:
					func_types = [FuncType.LINEAR]
				_:
					func_types = [FuncType.LINEAR]

			var candidate = random_function(func_types)
			if root.utils.is_level_valid_for_edges(candidate, root.ball_side):
				valid_correct_func = candidate

	if valid_correct_func == "":
		valid_correct_func = "0.5*x"

	current_correct_func = valid_correct_func
	current_correct_func_b = ""

	if lvl_type == LevelType.DOUBLE_LINEAR:
		var double_module = root.double_linear_module
		if double_module:
			var state = double_module.prepare_new_level(valid_correct_func)
			current_correct_func = state.primary
			current_correct_func_b = state.secondary
			options = state.options_primary
			options_secondary = state.options_secondary
			double_intersection_x = state.intersection
			double_module.set_intersection(double_intersection_x)
			double_module.apply_ui(options, options_secondary)
			double_module.draw_tracks(current_correct_func, current_correct_func_b)
			
			var expr_a = Expression.new()
			var expr_b = Expression.new()
			if expr_a.parse(current_correct_func, ["x"]) == OK and expr_b.parse(current_correct_func_b, ["x"]) == OK:
				root.utils.clear_ui_before_level_load()
				root.utils.setup_double_level_positions(expr_a, expr_b)
			
			_save_current_level(LevelType.DOUBLE_LINEAR, level_seed)
		else:
			push_warning("DOUBLE_LINEAR: module not initialized; skipping level generation")
		return
	elif lvl_type == LevelType.INPUT_LINEAR:
		options = []
		for cb in root.option_check_buttons:
			if cb and cb is CanvasItem:
				cb.disabled = true
		if root.build_button:
			root.build_button.disabled = false

		if root.k_input:
			root.k_input.clear()
		if root.b_input:
			root.b_input.clear()
		if root.x_label:
			root.x_label.text = ""
		if root.y_label:
			root.y_label.text = ""
		if root.k_value_label:
			root.k_value_label.text = ""
		if root.b_value_label:
			root.b_value_label.text = ""
		var expr = Expression.new()
		if expr.parse(current_correct_func, ["x"]) == OK:
			root.utils.setup_level_positions(expr)
			_save_current_level(lvl_type, level_seed)
	elif lvl_type == LevelType.INPUT_SLIDER:
		options = []
		for cb in root.option_check_buttons:
			if cb and cb is CanvasItem:
				cb.disabled = true
		if root.input_slider_module:
			root.input_slider_module.setup_ui_with_function(current_correct_func)
			if root.has_method("refresh_input_slider_value_labels"):
				root.refresh_input_slider_value_labels()
		else:
			if root.build_button:
				root.build_button.disabled = false
			if root.k_slider:
				root.k_slider.value = 0.0
			if root.b_slider:
				root.b_slider.value = 0.0
			if root.k_slider_label:
				root.k_slider_label.text = "0.0"
			if root.b_slider_label:
				root.b_slider_label.text = "0.0"
			if root.has_method("refresh_input_slider_value_labels"):
				root.refresh_input_slider_value_labels()
			var expr = Expression.new()
			if expr.parse(current_correct_func, ["x"]) == OK:
				root.utils.setup_level_positions(expr)
		_save_current_level(lvl_type, level_seed)

	else:
		if root.build_button:
			root.build_button.disabled = false

		options = generate_options_for_type(lvl_type, valid_correct_func)
		while options.size() < 3:
			var fallback = random_function([FuncType.LINEAR])
			if not options.has(fallback):
				options.append(fallback)
		options.shuffle()

		var expr = Expression.new()
		if expr.parse(valid_correct_func, ["x"]) == OK:
			root.utils.setup_level_positions(expr)

		var button_node = root.get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option0/FormulaLabel")
		if button_node:
			button_node.text = root.utils.format_function_from_string(options[0])
		var button2_node = root.get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option1/FormulaLabel")
		if button2_node:
			button2_node.text = root.utils.format_function_from_string(options[1])
		var button3_node = root.get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option2/FormulaLabel")
		if button3_node:
			button3_node.text = root.utils.format_function_from_string(options[2])

		print("Сторона шара:", "RIGHT" if root.ball_side == Side.RIGHT else "LEFT")
		print("Правильная функция:", current_correct_func)
		print("Все варианты ответов:")
		for i in range(options.size()):
			print("  [", i, "] ", options[i])
		
		_save_current_level(lvl_type, level_seed)

func get_option_for_group(group: int, index: int) -> String:
	var list = options if group == 0 else options_secondary
	if index >= 0 and index < list.size():
		return list[index]
	return ""


func _save_current_level(lvl_type: int, level_seed: int = 0):
	if not root.level_saver:
		return

	if is_level_loaded_from_save:
		return
	var LevelSaver = root.level_saver
	var level_data = LevelSaver.LevelData.new()
	level_data.level_number = root.level
	level_data.level_type = lvl_type
	if "level_type_name" in level_data:
		level_data.level_type_name = level_type_to_name(lvl_type)
	level_data.correct_func = current_correct_func
	level_data.correct_func_b = current_correct_func_b
	level_data.options = options.duplicate()
	level_data.options_b = options_secondary.duplicate()
	level_data.ball_side = root.ball_side
	level_data.star_seed = level_seed if level_seed != 0 else randi()
	level_data.double_intersection_x = double_intersection_x
	var saved = LevelSaver.save_level(level_data)
	is_level_loaded_from_save = true  



func generate_options_for_type(lvl_type: int, base_func: String) -> Array:
	var opts = [base_func]

	match lvl_type:
		LevelType.SIMPLE:
			while opts.size() < 3:
				var cand = random_function([FuncType.LINEAR])
				if not opts.has(cand):
					opts.append(cand)

		LevelType.VARY_B:
			var expr_chk = Expression.new()
			if expr_chk.parse(base_func, ["x"]) == OK:
				var b_val = expr_chk.execute([0.0])
				var y1 = expr_chk.execute([1.0])
				if typeof(b_val) == TYPE_FLOAT and typeof(y1) == TYPE_FLOAT:
					var k_val = y1 - b_val
					opts = root.utils.make_variants_varying_b(k_val, b_val, root.ball_side)

		LevelType.VARY_K:
			var expr_chk2 = Expression.new()
			if expr_chk2.parse(base_func, ["x"]) == OK:
				var b_val2 = expr_chk2.execute([0.0])
				var y12 = expr_chk2.execute([1.0])
				if typeof(b_val2) == TYPE_FLOAT and typeof(y12) == TYPE_FLOAT:
					var k_val2 = y12 - b_val2
					opts = root.utils.make_variants_varying_k(k_val2, b_val2, root.ball_side)

		LevelType.QUADRATIC:
			while opts.size() < 3:
				var cand = random_function([FuncType.QUADRATIC])
				if not opts.has(cand):
					opts.append(cand)

		LevelType.TRIG:
			while opts.size() < 3:
				var cand = random_function([FuncType.SIN, FuncType.COS])
				if not opts.has(cand):
					opts.append(cand)
					
		_:
			pass

	return opts


func random_function(allowed_types: Array = []) -> String:
	if allowed_types.is_empty():
		allowed_types = [FuncType.LINEAR, FuncType.QUADRATIC, FuncType.SIN, FuncType.COS]

	var type = allowed_types[randi() % allowed_types.size()]
	var func_str = ""
	match type:
		FuncType.LINEAR:
			var k = 0.0
			while abs(k) < 0.3:
				k = round(randf_range(-2, 2) * 10) / 10.0
			var b = round(randf_range(-5.0, 5.0) * 10) / 10.0
			func_str = str(k) + "*x + " + str(b)
		FuncType.QUADRATIC:
			var a = round(randf_range(0, 1) * 10) / 10.0
			if a == 0.0:
				a = 0.05
			var b2 = round(randf_range(-5, 5) * 10) / 10.0
			var c = round(randf_range(-10.0, 10.0) * 10) / 10.0
			func_str = str(a) + "*x*x + " + str(b2) + "*x + " + str(c)
		FuncType.SIN:
			var A = round(randf_range(1.0, 2.0) * 10) / 10.0
			var f = round(randf_range(0.05, 0.3) * 10) / 10.0
			func_str = str(A) + "*sin(" + str(f) + "*x)"
		FuncType.COS:
			var A = round(randf_range(1.0, 2.0) * 10) / 10.0
			var f = round(randf_range(0.05, 0.3) * 10) / 10.0
			func_str = str(A) + "*cos(" + str(f) + "*x)"
	return func_str

func reset_current_level():
	root.restart.disabled = false
	root.utils.enable_option_buttons(root)
	
	if root.option_check_buttons:
		for cb in root.option_check_buttons:
			if cb:
				cb.button_pressed = false
	if root.option_buttons2:
		for cb in root.option_buttons2:
			if cb:
				cb.button_pressed = false
	if root.has_method("set_forward_button_active"):
		root.set_forward_button_active(false)
	
	for child in root.track.get_children():
		if child is CollisionShape2D:
			child.queue_free()
	if root.track2:
		for child in root.track2.get_children():
			if child is CollisionShape2D:
				child.queue_free()
	
	if root.timer:
		root.timer.stop()
		root.timer.paused = false
		root.timer.wait_time = root.timer_duration
	if root.timer_label:
		root.timer_label.text = root.format_time(root.timer_duration)
	
	var current_lvl_type = get_level_type(root.level)
	if current_lvl_type == LevelType.INPUT_LINEAR:
		if root.k_input:
			root.k_input.clear()
		if root.b_input:
			root.b_input.clear()
	elif current_lvl_type == LevelType.INPUT_SLIDER:
		if root.k_slider:
			root.k_slider.value = 0.0
		if root.b_slider:
			root.b_slider.value = 0.0
	
	if root.k_input:
		root.k_input.clear()
	if root.b_input:
		root.b_input.clear()
	if root.k_slider:
		root.k_slider.value = 0.0
	if root.b_slider:
		root.b_slider.value = 0.0
	
	root.track.visible = false
	if root.track2:
		root.track2.visible = false
	if root.timer:
		root.timer.stop()
	if root.timer_label:
		root.timer_label.text = "Таймер: --"

	root.score = 0
	root.ui.update_score_label()
	root.first_selection_done = false
	
	for s in root.stars:
		s.visible = true
	
	if current_lvl_type == LevelType.INPUT_LINEAR or current_lvl_type == LevelType.INPUT_SLIDER:
		if root.build_button:
			root.build_button.disabled = false
	
	if current_lvl_type == LevelType.INPUT_LINEAR or current_lvl_type == LevelType.INPUT_SLIDER:
		if root.has_method("set_forward_button_active"):
			root.set_forward_button_active(false)

	root.ball.freeze = false
	root.ball.linear_velocity = Vector2.ZERO
	root.ball.angular_velocity = 0
	
	var expr = Expression.new()
	if expr.parse(current_correct_func, ["x"]) == OK:
		if current_lvl_type == LevelType.DOUBLE_LINEAR:
			if root.double_linear_module:
				root.double_linear_module.set_intersection(double_intersection_x)
				root.double_linear_module.draw_tracks(current_correct_func, current_correct_func_b)
		else:
			root.utils.setup_level_positions(expr)
		if root.ui:
			root.ui.update_stars_count_label()
	
	root.ball.freeze = true


func _reset_slider_ui():
	if root.k_slider:
		root.k_slider.value = 0.0
	if root.b_slider:
		root.b_slider.value = 0.0
