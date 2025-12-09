extends Node

var root
var options = []
var options_secondary = []
var current_correct_func = ""
var current_correct_func_b = ""
var double_intersection_x: float = NAN
var is_level_loaded_from_save: bool = false

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

func init(r):
	root = r
	if root.utils:
		root.utils.calc_base_unit()

func get_level_type(level: int) -> LevelType:
	if level <= 1:
		return LevelType.SIMPLE
	elif level <= 2:
		return LevelType.VARY_B
	elif level <= 3:
		return LevelType.VARY_K
	elif level <= 4:
		return LevelType.INPUT_LINEAR
	elif level <= 5:
		return LevelType.INPUT_SLIDER
	elif level <= 6:
		return LevelType.DOUBLE_LINEAR
	elif level <= 35:
		return LevelType.TRIG
	else:
		var cycle = ((level - 1) % 25) + 1
		return get_level_type(cycle)

func load_saved_level(level_number: int) -> bool:
	if not root.level_saver:
		print("level_saver не инициализирован")
		is_level_loaded_from_save = false
		return false
	root.utils.clear_ui_before_level_load()
	var LevelSaver = root.level_saver
	var level_data = LevelSaver.load_level(level_number)
	if level_data == null:
		print("Уровень ", level_number, " не найден в levels.json")
		is_level_loaded_from_save = false
		return false
	print("Найден сохранённый уровень ", level_number, " (тип: ", level_data.level_type, ")")
	
	is_level_loaded_from_save = true
	current_correct_func = level_data.correct_func
	current_correct_func_b = level_data.correct_func_b
	options = level_data.options.duplicate() if level_data.options is Array else []
	options_secondary = level_data.options_b.duplicate() if level_data.options_b is Array else []
	root.ball_side = level_data.ball_side
	double_intersection_x = level_data.double_intersection_x
	
	seed(level_data.star_seed)
	
	var saved_lvl_type = level_data.level_type
	if saved_lvl_type == null:
		saved_lvl_type = get_level_type(level_number)
	var expr = Expression.new()
	if saved_lvl_type != LevelType.DOUBLE_LINEAR and expr.parse(current_correct_func, ["x"]) == OK:
		print("[LevelGen] setup_level_positions using saved func:", current_correct_func)
		root.utils.setup_level_positions(expr)
	
	if saved_lvl_type == LevelType.INPUT_LINEAR:
		for btn in root.option_buttons:
			btn.hide()
		_show_buttons(root.option_buttons2, false)
		if root.has_node("UI/BottomLayout/Panel/Items/Answers"):
			root.get_node("UI/BottomLayout/Panel/Items/Answers").show()
		if root.build_button:
			root.build_button.disabled = false
		if root.k_input:
			root.k_input.visible = true
		if root.b_input:
			root.b_input.visible = true
		if root.k_slider:
			root.k_slider.visible = false
		if root.b_slider:
			root.b_slider.visible = false
		if root.has_node("UI/BottomLayout/Panel/Items/Answers/Panel/Slider1"):
			root.get_node("UI/BottomLayout/Panel/Items/Answers/Panel/Slider1").visible = false
		if root.k_slider_label:
			root.k_slider_label.visible = false
		if root.b_slider_label:
			root.b_slider_label.visible = false
		if root.x_label:
			root.x_label.visible = false
		if root.y_label:
			root.y_label.visible = false
		if root.k_value_label:
			root.k_value_label.visible = false
			root.k_value_label.text = ""
		if root.b_value_label:
			root.b_value_label.visible = false
			root.b_value_label.text = ""
		root.input_panel.visible = true
	elif saved_lvl_type == LevelType.INPUT_SLIDER:
		if root.input_slider_module:
			root.input_slider_module.setup_ui_with_function(current_correct_func)
			# Показать новый Slider2, скрыть InputPanel/InputPanel2
			var slider2 = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/Slider2")
			if slider2:
				slider2.show()
			if root.input_panel:
				root.input_panel.hide()
			var input_panel2 = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/InputPanel2")
			if input_panel2:
				input_panel2.hide()
			if root.k_value_label:
				root.k_value_label.visible = true
			if root.b_value_label:
				root.b_value_label.visible = true
			if root.has_method("refresh_input_slider_value_labels"):
				root.refresh_input_slider_value_labels()
		else:
			for cb in root.option_check_buttons:
				cb.hide()
				cb.disabled = true
			if root.has_node("UI/BottomLayout/Panel/Items/Answers"):
				root.get_node("UI/BottomLayout/Panel/Items/Answers").hide()
			if root.build_button:
				root.build_button.disabled = false
			if root.k_slider:
				root.k_slider.value = 0.0
			if root.b_slider:
				root.b_slider.value = 0.0
			if root.k_slider_label:
				root.k_slider_label.text = "0.0"
				root.k_slider_label.visible = true
			if root.b_slider_label:
				root.b_slider_label.text = "0.0"
				root.b_slider_label.visible = true
			if root.k_input:
				root.k_input.visible = false
			if root.b_input:
				root.b_input.visible = false
			if root.k_slider:
				root.k_slider.visible = true
			if root.b_slider:
				root.b_slider.visible = true
			if root.has_node("UI/BottomLayout/Panel/Items/Answers/Slider"):
				root.get_node("UI/BottomLayout/Panel/Items/Answers/Slider").visible = true
			if root.x_label:
				root.x_label.visible = false
			if root.y_label:
				root.y_label.visible = false
			if root.k_value_label:
				root.k_value_label.visible = true
			if root.b_value_label:
				root.b_value_label.visible = true
			if root.has_method("refresh_input_slider_value_labels"):
				root.refresh_input_slider_value_labels()
			root.input_panel.visible = true
	elif saved_lvl_type == LevelType.DOUBLE_LINEAR:
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
			double_module.set_intersection(double_intersection_x)
			double_module.apply_ui(options, options_secondary)
			double_module.draw_tracks(current_correct_func, current_correct_func_b)
		else:
			push_warning("DOUBLE_LINEAR: module not initialized; cannot restore saved state")
		return true
	else:
		root.input_panel.visible = false
		# Показать Buttons1 для обычных уровней
		var buttons1_node = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons1")
		if buttons1_node:
			buttons1_node.show()
			for cb in root.option_check_buttons:
				if cb:
					cb.disabled = false
		# Скрыть Buttons2 для обычных уровней
		var buttons2_node = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons2")
		if buttons2_node:
			buttons2_node.hide()
		var button_node = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons1/Option0/FormulaLabel")
		if button_node:
			button_node.text = root.utils.format_function_from_string(options[0])
		var button2_node = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons1/Option1/FormulaLabel")
		if button2_node:
			button2_node.text = root.utils.format_function_from_string(options[1])
		var button3_node = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons1/Option2/FormulaLabel")
		if button3_node:
			button3_node.text = root.utils.format_function_from_string(options[2])
		if root.has_node("UI/BottomLayout/Panel/Items/Answers"):
			root.get_node("UI/BottomLayout/Panel/Items/Answers").show()
	
	return true


func generate_new_level():
	# Сначала скрыть все UI-элементы для чистого состояния
	var input_panel2_node = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/InputPanel2")
	if input_panel2_node:
		input_panel2_node.hide()
	var slider2_node = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/Slider2")
	if slider2_node:
		slider2_node.hide()
	if root.has_node("UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons1"):
		root.get_node("UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons1").hide()
	if root.has_node("UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons2"):
		root.get_node("UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons2").hide()
	if root.has_node("UI/BottomLayout/Panel/Items/Answers/Panel/Slider1"):
		root.get_node("UI/BottomLayout/Panel/Items/Answers/Panel/Slider1").hide()
	
	# Очистить поля ввода и сбросить слайдеры
	if root.k_input:
		root.k_input.clear()
	if root.b_input:
		root.b_input.clear()
	if root.k_slider:
		root.k_slider.value = 0.0
	if root.b_slider:
		root.b_slider.value = 0.0
	
	if root.k_value_label:
		root.k_value_label.visible = false
		root.k_value_label.text = ""
	if root.b_value_label:
		root.b_value_label.visible = false
		root.b_value_label.text = ""
	root.utils.clear_ui_before_level_load()
	_reset_slider_ui()
	
	# Сброс таймера в начале нового уровня
	if root.timer:
		root.timer.stop()
		root.timer.paused = false
	if root.timer_label:
		root.timer_label.text = root.format_time(root.timer_duration)
	
	if root.level_saver:
		var saved = load_saved_level(root.level)
		if saved:
			print("Загружен сохранённый уровень ", root.level)
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
		else:
			print("Уровень ", root.level, " не найден в сохранениях, генерирую новый...")
	
	# Генерация нового уровня
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

	var lvl_type = get_level_type(root.level)
	print("Тип уровня:", lvl_type)
	
	# Объявить переменные для кнопок один раз
	var buttons1_node = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons1")
	var buttons2_node = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/ButtonsRow/Buttons2")

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
			# Hide Buttons1 and Buttons2 containers
			if buttons1_node:
				buttons1_node.hide()
			if buttons2_node:
				buttons2_node.hide()
			var state = double_module.prepare_new_level(valid_correct_func)
			current_correct_func = state.primary
			current_correct_func_b = state.secondary
			options = state.options_primary
			options_secondary = state.options_secondary
			double_intersection_x = state.intersection
			double_module.set_intersection(double_intersection_x)
			double_module.apply_ui(options, options_secondary)
			double_module.draw_tracks(current_correct_func, current_correct_func_b)
			_save_current_level(LevelType.DOUBLE_LINEAR, level_seed)
		else:
			push_warning("DOUBLE_LINEAR: module not initialized; skipping level generation")
		return
	elif lvl_type == LevelType.INPUT_LINEAR:
		options = []
		for cb in root.option_check_buttons:
			cb.hide()
			cb.disabled = true
		# Hide Buttons1 and Buttons2 containers
		if buttons1_node:
			buttons1_node.hide()
		if buttons2_node:
			buttons2_node.hide()
		if root.has_node("UI/BottomLayout/Panel/Items/Answers"):
			root.get_node("UI/BottomLayout/Panel/Items/Answers").show()
		if root.build_button:
			root.build_button.disabled = false

		# INPUT_LINEAR: показываем новый InputPanel2, скрываем оба Slider контейнера
		if root.k_input:
			root.k_input.clear()
		if root.b_input:
			root.b_input.clear()
		var input_panel2_l = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/InputPanel2")
		if input_panel2_l:
			input_panel2_l.show()
		if root.input_panel:
			root.input_panel.hide()
		# спрятать старый Slider и новый Slider2
		if root.has_node("UI/BottomLayout/Panel/Items/Answers/Panel/Slider"):
			root.get_node("UI/BottomLayout/Panel/Items/Answers/Panel/Slider").hide()
		var slider2_l = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/Slider2")
		if slider2_l:
			slider2_l.hide()
		if root.k_slider_label:
			root.k_slider_label.visible = false
		if root.b_slider_label:
			root.b_slider_label.visible = false
		if root.x_label:
			root.x_label.visible = false
		if root.y_label:
			root.y_label.visible = false
		if root.k_value_label:
			root.k_value_label.visible = false
			root.k_value_label.text = ""
		if root.b_value_label:
			root.b_value_label.visible = false
			root.b_value_label.text = ""
		var expr = Expression.new()
		if expr.parse(current_correct_func, ["x"]) == OK:
			print("[LevelGen] setup_level_positions using input-linear func:", current_correct_func)
			root.utils.setup_level_positions(expr)
			_save_current_level(lvl_type, level_seed)
	elif lvl_type == LevelType.INPUT_SLIDER:
		options = []
		for cb in root.option_check_buttons:
			cb.hide()
			cb.disabled = true
		# Hide Buttons1 and Buttons2 containers
		if buttons1_node:
			buttons1_node.hide()
		if buttons2_node:
			buttons2_node.hide()
		if root.has_node("UI/BottomLayout/Panel/Items/Answers"):
			root.get_node("UI/BottomLayout/Panel/Items/Answers").show()
		if root.k_value_label:
			root.k_value_label.visible = true
		if root.b_value_label:
			root.b_value_label.visible = true
		if root.input_slider_module:
			print("[LevelGen] setup_level_positions using input-slider func:", current_correct_func)
			root.input_slider_module.setup_ui_with_function(current_correct_func)
			if root.has_method("refresh_input_slider_value_labels"):
				root.refresh_input_slider_value_labels()
		else:
			for btn in root.option_buttons:
				btn.hide()
			if root.build_button:
				root.build_button.disabled = false
			if root.k_slider:
				root.k_slider.value = 0.0
			if root.b_slider:
				root.b_slider.value = 0.0
			if root.k_slider_label:
				root.k_slider_label.text = "0.0"
				root.k_slider_label.visible = true
			if root.b_slider_label:
				root.b_slider_label.text = "0.0"
				root.b_slider_label.visible = true
			if root.k_input:
				root.k_input.visible = false
			if root.b_input:
				root.b_input.visible = false
			if root.k_slider:
				root.k_slider.visible = true
			if root.b_slider:
				root.b_slider.visible = true
			if root.has_node("UI/BottomLayout/Panel/Items/Answers/Panel/Slider"):
				root.get_node("UI/BottomLayout/Panel/Items/Answers/Panel/Slider").visible = true
			if root.x_label:
				root.x_label.visible = false
			if root.y_label:
				root.y_label.visible = false
			if root.has_method("refresh_input_slider_value_labels"):
				root.refresh_input_slider_value_labels()
			root.input_panel.visible = true
			var expr = Expression.new()
			if expr.parse(current_correct_func, ["x"]) == OK:
				root.utils.setup_level_positions(expr)
		_save_current_level(lvl_type, level_seed)

	else:
		# Обычные уровни: скрываем инпуты и слайдеры, показываем варианты Buttons1
		root.input_panel.visible = false
		var input_panel2_e = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/InputPanel2")
		if input_panel2_e:
			input_panel2_e.hide()
		var slider2_e = root.get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/Slider2")
		if slider2_e:
			slider2_e.hide()
		if root.has_node("UI/BottomLayout/Panel/Items/Answers/Panel/Slider"):
			root.get_node("UI/BottomLayout/Panel/Items/Answers/Panel/Slider").hide()
		if root.build_button:
			root.build_button.disabled = false
		
		# Показать Buttons1 для обычных уровней
		if buttons1_node:
			buttons1_node.show()
			# Сначала скрыть все OptionX
			for i in range(3):
				var option_node = buttons1_node.get_node_or_null("Option" + str(i))
				if option_node:
					option_node.visible = false
		# Скрыть Buttons2 для обычных уровней
		if buttons2_node:
			buttons2_node.hide()

		options = generate_options_for_type(lvl_type, valid_correct_func)
		while options.size() < 3:
			var fallback = random_function([FuncType.LINEAR])
			if not options.has(fallback):
				options.append(fallback)
		options.shuffle()

		var expr = Expression.new()
		if expr.parse(valid_correct_func, ["x"]) == OK:
			print("[LevelGen] setup_level_positions using generated func:", valid_correct_func)
			root.utils.setup_level_positions(expr)

		# Показать только нужные варианты и обновить тексты
		if buttons1_node:
			for i in range(min(3, options.size())):
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
						label.text = root.utils.format_function_from_string(options[i])
					var cb = option_node.get_node_or_null("CheckButton")
					if cb:
						cb.button_pressed = false
						cb.disabled = false
		if root.has_node("UI/BottomLayout/Panel/Items/Answers"):
			root.get_node("UI/BottomLayout/Panel/Items/Answers").show()

		print("Сторона шара:", "RIGHT" if root.ball_side == Side.RIGHT else "LEFT")
		print("Правильная функция:", current_correct_func)
		print("Все варианты ответов:")
		for i in range(options.size()):
			print("  [", i, "] ", options[i])
		
		_save_current_level(lvl_type, level_seed)
		
		# Убедиться, что ForwardButton видна и активна
		if root.forward_button:
			root.forward_button.disabled = false
			root.forward_button.show()



func _show_buttons(buttons: Array, visible: bool):
	if buttons == null:
		return
	for btn in buttons:
		if btn:
			if visible:
				btn.show()
				btn.disabled = false
			else:
				btn.hide()

func get_option_for_group(group: int, index: int) -> String:
	var list = options if group == 0 else options_secondary
	if index >= 0 and index < list.size():
		return list[index]
	return ""


func _save_current_level(lvl_type: int, level_seed: int = 0):
	if not root.level_saver:
		print("level_saver не инициализирован, сохранение невозможно")
		return

	if is_level_loaded_from_save:
		print("Уровень ", root.level, " был загружен из сохранения, пропускаю пересохранение")
		return
	var LevelSaver = root.level_saver
	var level_data = LevelSaver.LevelData.new()
	level_data.level_number = root.level
	level_data.level_type = lvl_type
	level_data.correct_func = current_correct_func
	level_data.correct_func_b = current_correct_func_b
	level_data.options = options.duplicate()
	level_data.options_b = options_secondary.duplicate()
	level_data.ball_side = root.ball_side
	level_data.star_seed = level_seed if level_seed != 0 else randi()
	level_data.double_intersection_x = double_intersection_x
	var saved = LevelSaver.save_level(level_data)
	if saved:
		print("✓ Уровень ", root.level, " сохранён в levels.json")
		is_level_loaded_from_save = true  
	else:
		print("✗ Ошибка сохранения уровня ", root.level)


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
			var a = round(randf_range(-0.1, 0.1) * 10) / 10.0
			if a == 0.0:
				a = 0.05
			var b2 = round(randf_range(-0.8, 0.8) * 10) / 10.0
			var c = round(randf_range(-4.0, 4.0) * 10) / 10.0
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
	# Снять все галочки с CheckButton при перезапуске уровня
	if root.option_check_buttons:
		for cb in root.option_check_buttons:
			if cb:
				cb.button_pressed = false
	# Снять все галочки с CheckButton в Buttons2 при перезапуске уровня
	if root.option_buttons2:
		for cb in root.option_buttons2:
			if cb:
				cb.button_pressed = false
	# Показать ForwardButton при перезапуске
	if root.forward_button:
		root.forward_button.disabled = false
		root.forward_button.show()
	for child in root.track.get_children():
		if child is CollisionShape2D:
			child.queue_free()
	if root.track2:
		for child in root.track2.get_children():
			if child is CollisionShape2D:
				child.queue_free()
	
	# Сброс таймера при перезапуске уровня
	if root.timer:
		root.timer.stop()
		root.timer.paused = false
	if root.timer_label:
		root.timer_label.text = root.format_time(root.timer_duration)
	
	var lvl_type = get_level_type(root.level)
	if lvl_type == LevelType.INPUT_LINEAR:
		# Очистить поля InputPanel2
		if root.k_input:
			root.k_input.clear()
		if root.b_input:
			root.b_input.clear()
		if root.forward_button_input:
			root.forward_button_input.hide()
	elif lvl_type == LevelType.INPUT_SLIDER:
		# Сбросить слайдеры Slider2
		if root.k_slider:
			root.k_slider.value = 0.0
		if root.b_slider:
			root.b_slider.value = 0.0
		if root.forward_button_input:
			root.forward_button_input.hide()
	
	# Всегда очищать поля InputPanel2 и Slider2 при сбросе уровня
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
	
	if lvl_type == LevelType.INPUT_LINEAR or lvl_type == LevelType.INPUT_SLIDER:
		if root.build_button:
			root.build_button.disabled = false

	root.ball.freeze = false
	root.ball.linear_velocity = Vector2.ZERO
	root.ball.angular_velocity = 0
	var expr = Expression.new()
	if expr.parse(current_correct_func, ["x"]) == OK:
		print("[LevelGen] reset_current_level placing stars for func:", current_correct_func)
		if lvl_type == LevelType.DOUBLE_LINEAR:
			if root.double_linear_module:
				root.double_linear_module.set_intersection(double_intersection_x)
				root.double_linear_module.draw_tracks(current_correct_func, current_correct_func_b)
		else:
			# Используем правильную функцию только для расстановки звёзд,
			# НЕ рисуем по ней физический трек, чтобы шарик не контактировал с невидимым графиком
			root.utils.setup_level_positions(expr)
	root.ball.freeze = true


func _reset_slider_ui():
	if root.k_slider:
		root.k_slider.visible = false
	if root.b_slider:
		root.b_slider.visible = false
	if root.k_slider_label:
		root.k_slider_label.visible = false
	if root.b_slider_label:
		root.b_slider_label.visible = false
	if root.has_node("UI/Slider"):
		root.get_node("UI/Slider").visible = false
