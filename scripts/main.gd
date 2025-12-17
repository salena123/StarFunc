extends Node2D

var utils
var ui
var track_drawer
var level_gen
var physics
var lin_gen
var input_linear_module
var input_slider_module
var double_linear_module
var progress_manager
var level_saver

@onready var bottom_layout: Control = get_node_or_null("UI/BottomLayout")
@onready var bottom_layout_items: Control = get_node_or_null("UI/BottomLayout/Items/Items")

@onready var ball = $ball
@onready var stars = $stars.get_children()
@onready var track = $track
@onready var line2d = $track/Line2D
@onready var track2 = $track2
@onready var line2d2 = $track2/Line2D
@onready var forward_button = get_node_or_null("UI/BottomLayout/Items/Items/ForwardButton")
@onready var option_check_buttons = [
	get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option0/CheckButton"),
	get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option1/CheckButton"),
	get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option2/CheckButton")
]
@onready var option_formula_labels = [
	get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option0/FormulaLabel"),
	get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option1/FormulaLabel"),
	get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option2/FormulaLabel")
]
@onready var option_buttons = [
	get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option0/CheckButton"),
	get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option1/CheckButton"),
	get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1/Option2/CheckButton")
]
@onready var option_buttons2 = [
	get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons2/Option0/CheckButton"),
	get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons2/Option1/CheckButton"),
	get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons2/Option2/CheckButton")
]
@onready var input_panel = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/InputPanel2")
## Старые input/slider узлы больше не используются напрямую, но свойства
## k_value_label / b_value_label всё ещё дергаются из других скриптов.
## Поэтому ниже мы переназначаем их на новые лейблы из Slider2.
#@onready var k_input = get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/InputPanel/KInput")
#@onready var b_input = get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/InputPanel/BInput")
#@onready var k_slider = get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/InputPanel/KSlider")
#@onready var b_slider = get_node_or_null("UI/BottomLayout/Panel/Items/Answers/Panel/InputPanel/BSlider")
@onready var build_button = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/InputPanel1/BuildButton")
@onready var forward_button_input = get_node_or_null("UI/BottomLayout/Items/Items/ForwardButton")

@onready var restart = $UI/Restart
@onready var timer_label: Label = $UI/TimerContainer/ContentHBox/Label

@onready var answers_panel: Control = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel")
@onready var answers_buttons_row: Control = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow")
@onready var answers_buttons1: Control = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1")
@onready var answers_buttons2: Control = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons2")

@onready var answers_input_panel2: Control = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/InputPanel2")
@onready var answers_slider2: Control = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/Slider2")
# Исходная высота нижней панели с ответами, чтобы при разворачивании
# возвращать её к первоначальному красивому виду
var _bottom_panel_initial_height: float = 0.0

# Высота нижней панели в развернутом состоянии (запоминаем один раз при первом сворачивании)
var _bottom_panel_full_height: float = 0.0

var _bottom_layout_last_height: float = 180.0

var _bottom_layout_refresh_scheduled := false

# Флаг, чтобы не реагировать на сигналы CheckButton, когда мы меняем их состояние из кода
var _suppress_check_signal := false
@onready var x_label = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/Slider/XLabel")
@onready var y_label = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/Slider/YLabel")

@onready var k_slider = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/Slider2/K/KSlider")
@onready var k_slider_label = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/Slider2/K/KLabelValue")
@onready var b_slider = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/Slider2/B/BSlider")
@onready var b_slider_label = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/Slider2/B/BLabelValue")

@onready var k_input = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/InputPanel2/K/KLineEdit")
@onready var b_input = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/InputPanel2/B/BLineEdit")

# Совместимость: другие скрипты обращаются к k_value_label/b_value_label,
# поэтому даём им ссылку на те же узлы, что и k_slider_label/b_slider_label.
@onready var k_value_label = k_slider_label
@onready var b_value_label = b_slider_label


var score: int = 0
var level: int = 1
var first_selection_done: bool = false
var ball_side: int
var current_correct_func: String = ""
var base_unit: float
var screen_size: Vector2
var screen_center: Vector2
var timer: Timer
var timer_duration: float = 15.0


func _ready():
	utils = preload("res://scripts/utils.gd").new()
	ui = preload("res://scripts/ui_manager.gd").new()
	track_drawer = preload("res://scripts/track_drawer.gd").new()
	level_gen = preload("res://scripts/level_generator.gd").new()
	physics = preload("res://scripts/physics_checker.gd").new()
	input_linear_module = preload("res://scripts/input_linear_level.gd").new()
	input_slider_module = preload("res://scripts/input_slider_level.gd").new()
	double_linear_module = preload("res://scripts/double_linear_level.gd").new()
	progress_manager = preload("res://scripts/progress_manager.gd").new()
	level_saver = preload("res://scripts/level_saver.gd")

	screen_size = get_viewport_rect().size
	screen_center = screen_size / 2

	utils.init(self)
	ui.init(self)
	track_drawer.init(self)
	level_gen.init(self)
	physics.init(self)
	input_linear_module.init(self)
	input_slider_module.init(self)
	double_linear_module.init(self)
	progress_manager.init(self)

	randomize()
	ui.update_score_label()
	setup_ui_buttons()
	_setup_bottom_layout_autosize()
	bottom_layout_begin_update()
	bottom_layout_end_update()
	set_forward_button_active(false)

	$track.visible = false
	ball.freeze = true
	ball.linear_damp = 0.0
	ball.angular_damp = 0.0
	ball.continuous_cd = true

	timer = Timer.new()
	timer.wait_time = timer_duration
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	if timer_label:
		timer_label.text = format_time(timer_duration)
	
	set_process(true)
	print_scene_info()
	# Стартовое состояние панели — развернутое: задаём минимальную высоту под контент
	var start_panel = get_node_or_null("UI/BottomLayout/Items")
	#var start_items = get_node_or_null("UI/BottomLayout/Panel/Items")
	#if start_panel and start_items:
		#var header = start_items.get_node_or_null("HBoxContainer")
		#var header_height := 40.0
		#if header and header.size.y > 0.0:
			#header_height = header.size.y
		#start_panel.custom_minimum_size.y = header_height + 160.0
		## Иконка развёрнутого состояния (стрелка вниз)
		#var roll_btn = header.get_node_or_null("RollButton") if header else null
		#if roll_btn:
			#var icon = roll_btn.get_node_or_null("Icon")
			#if icon:
				#icon.rotation_degrees = 0.0
	#if forward_button:
		#forward_button.pressed.connect(func():
			#utils.on_forward_pressed(self, forward_button, option_check_buttons))
		#forward_button.disabled = false
		#forward_button.show()
	if forward_button and not forward_button.pressed.is_connected(func():
		utils.on_forward_pressed(self, forward_button, option_check_buttons)):
		forward_button.pressed.connect(func():
			utils.on_forward_pressed(self, forward_button, option_check_buttons))
	# ForwardButton is always visible; initial state is inactive (no hover)
	set_forward_button_active(false)

	setup_sliders()
	
	# Сбросить все CheckButton при старте
	_suppress_check_signal = true
	for cb in option_check_buttons:
		if cb:
			cb.button_pressed = false
			cb.disabled = true
	_suppress_check_signal = false
	# Скрыть все контейнеры кнопок при старте (без влияния на layout)
	# Управление видимостью теперь только в apply_bottom_ui_for_level_type
	
	level_gen.generate_new_level()
	_refresh_bottom_layout_height_late()
	call_deferred("_debug_dump_bottom_ui_state")
	
	
func _process(_delta):
	physics.check_star_collection()
	physics.check_ball_fall_off_screen()
	update_timer_display()

func select_option(index: int, group: int = 0):
	if first_selection_done:
		return
	var func_str = level_gen.get_option_for_group(group, index)
	if func_str == "":
		return
	var lvl_type = level_gen.get_level_type(level)
	if lvl_type == level_gen.LevelType.DOUBLE_LINEAR:
		var bounds = double_linear_module.get_segment_range(group)
		if group == 1:
			track_drawer.draw_track_secondary_with_bounds(func_str, bounds.x, bounds.y)
			if track2:
				track2.visible = true
		else:
			track_drawer.draw_track_with_bounds(func_str, bounds.x, bounds.y)
			track.visible = true
	else:
		track_drawer.draw_track(func_str)
		track.visible = true
	if forward_button:
		set_forward_button_active(true)
	_refresh_bottom_layout_height_late()
	
	if timer and timer.is_stopped():
		timer.wait_time = timer_duration
		timer.start()
		if timer_label:
			timer_label.text = format_time(timer_duration)
		print("Таймер запущен, выбрана функция:", func_str)

func _on_timer_timeout():
	if timer_label:
		timer_label.text = format_time(0.0)
	physics.check_level_complete_by_stars()

func format_time(seconds: float) -> String:
	var secs = int(seconds)
	var millis = int((seconds - secs) * 10)
	return "%02d:%d" % [secs, millis]

func update_timer_display():
	if timer_label and timer:
		if timer.is_stopped():
			timer_label.text = format_time(timer_duration)
		else:
			var time_left = timer.time_left
			timer_label.text = format_time(time_left)

func print_scene_info():
	var rect = get_viewport_rect()
	print("Scene size:", rect.size)
	print("Ball:", ball.global_position)
	for i in range(stars.size()):
		print("Star", i + 1, ":", stars[i].global_position)


func _debug_dump_bottom_ui_state():
	# One-shot debug to understand why BottomLayout can be empty on first load.
	for _i in range(2):
		await get_tree().process_frame
	print("[UI-DBG] bottom_layout:", bottom_layout, " items:", bottom_layout_items)
	_debug_dump_node("bottom_layout", bottom_layout)
	_debug_dump_node("answers_panel", answers_panel)
	_debug_dump_node("answers_buttons_row", answers_buttons_row)
	_debug_dump_node("answers_buttons1", answers_buttons1)
	_debug_dump_node("answers_buttons2", answers_buttons2)
	_debug_dump_node("answers_input_panel2", answers_input_panel2)
	_debug_dump_node("answers_slider2", answers_slider2)


func _debug_dump_node(tag: String, n: Node):
	if n == null:
		print("[UI-DBG] ", tag, " = null")
		return
	var vis := "n/a"
	var alpha := "n/a"
	var mf := "n/a"
	if n is CanvasItem:
		var ci := n as CanvasItem
		vis = str(ci.visible)
		alpha = str(ci.modulate.a)
	if n is Control:
		mf = str((n as Control).mouse_filter)
	print("[UI-DBG] ", tag, " path=", n.get_path(), " vis=", vis, " a=", alpha, " mf=", mf)

func _setup_bottom_layout_autosize():
	if not bottom_layout or not bottom_layout_items:
		return
	if not bottom_layout_items.minimum_size_changed.is_connected(_on_bottom_layout_items_minimum_size_changed):
		bottom_layout_items.minimum_size_changed.connect(_on_bottom_layout_items_minimum_size_changed)
	var vp := get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)
	_refresh_bottom_layout_height_late()


func _on_bottom_layout_items_minimum_size_changed():
	_refresh_bottom_layout_height_late()


func _on_viewport_size_changed():
	_refresh_bottom_layout_height_late()


func _refresh_bottom_layout_height_late():
	if _bottom_layout_refresh_scheduled:
		return
	_bottom_layout_refresh_scheduled = true
	call_deferred("_refresh_bottom_layout_height_late_impl")


func _refresh_bottom_layout_height_late_impl():
	var last_h := -1.0
	var stable_count := 0
	for _i in range(10):
		await get_tree().process_frame
		if bottom_layout_items == null:
			continue
		var h := bottom_layout_items.get_combined_minimum_size().y
		if abs(h - last_h) <= 0.5 and h > 1.0:
			stable_count += 1
			if stable_count >= 2:
				break
		else:
			stable_count = 0
		last_h = h
	_bottom_layout_refresh_scheduled = false
	_refresh_bottom_layout_height()
	bottom_layout_end_update()


func bottom_layout_begin_update():
	if bottom_layout and bottom_layout is CanvasItem:
		var ci := bottom_layout as CanvasItem
		ci.visible = true
		ci.modulate.a = 1.0
		if bottom_layout is Control:
			(bottom_layout as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func bottom_layout_end_update():
	if bottom_layout and bottom_layout is CanvasItem:
		var ci := bottom_layout as CanvasItem
		ci.visible = true
		ci.modulate.a = 1.0
		if bottom_layout is Control:
			(bottom_layout as Control).mouse_filter = Control.MOUSE_FILTER_STOP




func apply_bottom_ui_for_level_type(lvl_type: int):
	# ForwardButton should always stay visible and active (per current game design).
	set_forward_button_active(true)

	match lvl_type:
		level_gen.LevelType.DOUBLE_LINEAR:
			set_panel_section_active(answers_buttons_row, true)
			set_panel_section_active(answers_buttons1, true)
			set_panel_section_active(answers_buttons2, true)
			set_panel_section_active(answers_input_panel2, false)
			set_panel_section_active(answers_slider2, false)

		level_gen.LevelType.INPUT_LINEAR:
			set_panel_section_active(answers_buttons_row, false)
			set_panel_section_active(answers_buttons1, false)
			set_panel_section_active(answers_buttons2, false)
			set_panel_section_active(answers_input_panel2, true)
			set_panel_section_active(answers_slider2, false)

		level_gen.LevelType.INPUT_SLIDER:
			set_panel_section_active(answers_buttons_row, false)
			set_panel_section_active(answers_buttons1, false)
			set_panel_section_active(answers_buttons2, false)
			set_panel_section_active(answers_input_panel2, false)
			set_panel_section_active(answers_slider2, true)

		_:
			set_panel_section_active(answers_buttons_row, true)
			set_panel_section_active(answers_buttons1, true)
			set_panel_section_active(answers_buttons2, false)
			set_panel_section_active(answers_input_panel2, false)
			set_panel_section_active(answers_slider2, false)

	_refresh_bottom_layout_height_late()


func set_forward_button_active(active: bool):
	if not forward_button:
		return
	forward_button.visible = true
	forward_button.disabled = false
	forward_button.mouse_filter = Control.MOUSE_FILTER_STOP


func set_panel_section_active(n: Node, active: bool):
	if not n:
		return
	if n is CanvasItem:
		var ci := n as CanvasItem
		ci.visible = active
		ci.modulate.a = 1.0
		if n is Control:
			(n as Control).mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
	for child in n.get_children():
		if child is BaseButton:
			(child as BaseButton).disabled = not active
		elif child is LineEdit:
			(child as LineEdit).editable = active
		elif child is Range:
			(child as Range).editable = active


func _refresh_bottom_layout_height():
	if not bottom_layout or not bottom_layout_items:
		return
	var h := bottom_layout_items.get_combined_minimum_size().y
	print("[DEBUG] BottomLayout height: ", h, "px (combined_minimum_size)")
	if h > 1.0:
		_bottom_layout_last_height = max(h + 8.0, 60.0)
	print("[DEBUG] BottomLayout last_height: ", _bottom_layout_last_height, "px")
	print("[DEBUG] BottomLayout offset_top: ", bottom_layout.offset_top, "px")
	bottom_layout.offset_top = -_bottom_layout_last_height

func setup_sliders():
	# Слайдеры уже есть в сцене (Slider2): настраиваем диапазоны и сигналы
	if k_slider:
		k_slider.min_value = -1.5
		k_slider.max_value = 1.5
		k_slider.step = 0.1
		if not k_slider.value_changed.is_connected(_on_k_slider_changed):
			k_slider.value_changed.connect(_on_k_slider_changed)

	if b_slider:
		b_slider.min_value = -10.0
		b_slider.max_value = 10.0
		b_slider.step = 0.1
		if not b_slider.value_changed.is_connected(_on_b_slider_changed):
			b_slider.value_changed.connect(_on_b_slider_changed)

	# Подключаем поля ввода k/b из InputPanel2
	if k_input and not k_input.text_changed.is_connected(_on_k_input_changed):
		k_input.text_changed.connect(_on_k_input_changed)
	if b_input and not b_input.text_changed.is_connected(_on_b_input_changed):
		b_input.text_changed.connect(_on_b_input_changed)

	# Начальные значения в метках
	if k_slider and k_slider_label:
		k_slider_label.text = utils.format_number(k_slider.value)
	if b_slider and b_slider_label:
		b_slider_label.text = utils.format_number(b_slider.value)


func _on_k_slider_changed(value: float):
	# Обновляем текст и график при любом изменении слайдера
	var formatted_value = utils.format_number(value)
	if k_slider_label:
		k_slider_label.text = formatted_value
	redraw_input_graph()


func _on_b_slider_changed(value: float):
	var formatted_value = utils.format_number(value)
	if b_slider_label:
		b_slider_label.text = formatted_value
	redraw_input_graph()


func _on_k_input_changed(new_text: String):
	if new_text == "":
		return
	if not new_text.is_valid_float() and not new_text.is_valid_int():
		return
	var val = float(new_text)
	if k_slider:
		val = clamp(val, k_slider.min_value, k_slider.max_value)
		k_slider.value = val
	if k_slider_label:
		k_slider_label.text = utils.format_number(val)
	redraw_input_graph()


func _on_b_input_changed(new_text: String):
	if new_text == "":
		return
	if not new_text.is_valid_float() and not new_text.is_valid_int():
		return
	var val = float(new_text)
	if b_slider:
		val = clamp(val, b_slider.min_value, b_slider.max_value)
		b_slider.value = val
	if b_slider_label:
		b_slider_label.text = utils.format_number(val)
	redraw_input_graph()


func redraw_input_graph():
	if not k_slider or not b_slider:
		return
	var k_val = k_slider.value
	var b_val = b_slider.value
	var func_str = str(k_val) + "*x + " + str(b_val)
	var expr = Expression.new()
	if expr.parse(func_str, ["x"]) == OK:
		track_drawer.draw_track(func_str)
		track.visible = true
	else:
		print("Ошибка парсинга функции из слайдеров: ", func_str)

func setup_ui_buttons():
	setup_check_buttons()
	# Подключение CheckButton для DOUBLE_LINEAR режима
	var buttons1_node = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons1")
	if buttons1_node:
		if buttons1_node.get_node_or_null("Option0/CheckButton"):
			buttons1_node.get_node("Option0/CheckButton").toggled.connect(func(pressed):
				if pressed:
					select_option(0, 0)
			)
		if buttons1_node.get_node_or_null("Option1/CheckButton"):
			buttons1_node.get_node("Option1/CheckButton").toggled.connect(func(pressed):
				if pressed:
					select_option(1, 0)
			)
		if buttons1_node.get_node_or_null("Option2/CheckButton"):
			buttons1_node.get_node("Option2/CheckButton").toggled.connect(func(pressed):
				if pressed:
					select_option(2, 0)
			)
	
	var buttons2_node = get_node_or_null("UI/BottomLayout/Items/Items/Answers/Panel/ButtonsRow/Buttons2")
	if buttons2_node:
		if buttons2_node.get_node_or_null("Option0/CheckButton"):
			buttons2_node.get_node("Option0/CheckButton").toggled.connect(func(pressed):
				if pressed:
					# Выключаем остальные чекбоксы в Buttons2
					_suppress_check_signal = true
					if buttons2_node.get_node_or_null("Option1/CheckButton"):
						buttons2_node.get_node("Option1/CheckButton").button_pressed = false
					if buttons2_node.get_node_or_null("Option2/CheckButton"):
						buttons2_node.get_node("Option2/CheckButton").button_pressed = false
					_suppress_check_signal = false
					select_option(0, 1)
			)
		if buttons2_node.get_node_or_null("Option1/CheckButton"):
			buttons2_node.get_node("Option1/CheckButton").toggled.connect(func(pressed):
				if pressed:
					# Выключаем остальные чекбоксы в Buttons2
					_suppress_check_signal = true
					if buttons2_node.get_node_or_null("Option0/CheckButton"):
						buttons2_node.get_node("Option0/CheckButton").button_pressed = false
					if buttons2_node.get_node_or_null("Option2/CheckButton"):
						buttons2_node.get_node("Option2/CheckButton").button_pressed = false
					_suppress_check_signal = false
					select_option(1, 1)
			)
		if buttons2_node.get_node_or_null("Option2/CheckButton"):
			buttons2_node.get_node("Option2/CheckButton").toggled.connect(func(pressed):
				if pressed:
					# Выключаем остальные чекбоксы в Buttons2
					_suppress_check_signal = true
					if buttons2_node.get_node_or_null("Option0/CheckButton"):
						buttons2_node.get_node("Option0/CheckButton").button_pressed = false
					if buttons2_node.get_node_or_null("Option1/CheckButton"):
						buttons2_node.get_node("Option1/CheckButton").button_pressed = false
					_suppress_check_signal = false
					select_option(2, 1)
			)
	
	# Подключение кнопки сворачивания
	var roll_button = get_node_or_null("UI/BottomLayout/Items/Items/HBoxContainer/RollButton")
	#if roll_button:
		#roll_button.pressed.connect(_on_roll_button_pressed)
	if roll_button:
		roll_button.disabled = true
		roll_button.visible = false

	if forward_button and not forward_button.pressed.is_connected(_on_forward_button_pressed):
		forward_button.pressed.connect(_on_forward_button_pressed)


func _on_forward_button_pressed():
	utils.on_forward_pressed(self, forward_button, option_check_buttons)

func setup_check_buttons():
	for i in range(option_check_buttons.size()):
		var cb = option_check_buttons[i]
		if cb:
			cb.toggled.connect(_on_check_toggled.bind(i))

func _on_check_toggled(pressed: bool, index: int):
	# Игнорируем сигналы, когда мы сами программно меняем чекбоксы
	if _suppress_check_signal:
		return
	# После нажатия ForwardButton запрещаем включать новые графики,
	# но разрешаем выключать текущий, чтобы убрать его со сцены
	if first_selection_done and pressed:
		return
	var func_str = level_gen.get_option_for_group(0, index)
	if func_str == "":
		return
	if pressed:
		# Выключаем остальные CheckButton, чтобы активным был только один
		_suppress_check_signal = true
		for i in range(option_check_buttons.size()):
			if i == index:
				continue
			var other_cb = option_check_buttons[i]
			if other_cb:
				other_cb.button_pressed = false
		_suppress_check_signal = false
		
		# Рисуем график для выбранной функции
		track_drawer.draw_track(func_str)
		track.visible = true
	else:
		# Полностью убираем текущий график: и визуально, и физически
		if track:
			track.visible = false
			if line2d:
				line2d.points = PackedVector2Array()
			for child in track.get_children():
				if child is CollisionShape2D:
					child.queue_free()
		if track2:
			track2.visible = false
			if line2d2:
				line2d2.points = PackedVector2Array()
			for child2 in track2.get_children():
				if child2 is CollisionShape2D:
					child2.queue_free()

func _on_double_linear_check_toggled(pressed: bool, index: int, group: int):
	# Игнорируем сигналы, когда мы сами программно меняем чекбоксы
	if _suppress_check_signal:
		return
	# После нажатия ForwardButton запрещаем включать новые графики,
	# но разрешаем выключать текущий, чтобы убрать его со сцены
	if first_selection_done and pressed:
		return
	var func_str = ""
	if group == 0:
		func_str = level_gen.get_option_for_group(0, index)
	else:
		func_str = level_gen.get_option_for_group(1, index)
	if func_str == "":
		return
	if pressed:
		# Выключаем остальные CheckButton в той же группе
		_suppress_check_signal = true
		var target_buttons = option_buttons if group == 0 else option_buttons2
		for i in range(target_buttons.size()):
			if i == index:
				continue
			var other_cb = target_buttons[i]
			if other_cb:
				other_cb.button_pressed = false
		_suppress_check_signal = false
		
		# Рисуем график для выбранной функции
		if group == 0:
			track_drawer.draw_track(func_str)
			track.visible = true
		else:
			track_drawer.draw_track_secondary(func_str)
			track2.visible = true
	else:
		# Полностью убираем текущий график: и визуально, и физически
		if group == 0 and track:
			track.visible = false
			if line2d:
				line2d.points = PackedVector2Array()
			for child in track.get_children():
				if child is CollisionShape2D:
					child.queue_free()
		elif group == 1 and track2:
			track2.visible = false
			if line2d2:
				line2d2.points = PackedVector2Array()
			for child2 in track2.get_children():
				if child2 is CollisionShape2D:
					child2.queue_free()
	if forward_button:
		forward_button.disabled = false

#func _on_roll_button_pressed():
	#var panel = get_node_or_null("UI/BottomLayout/Panel")
	#var items = get_node_or_null("UI/BottomLayout/Panel/Items")
	#var header = get_node_or_null("UI/BottomLayout/Panel/Items/HBoxContainer")
	#var roll_button = get_node_or_null("UI/BottomLayout/Panel/Items/HBoxContainer/RollButton")
	#
	#if not panel or not items or not header or not roll_button:
		#print("Не найдены узлы для сворачивания панели")
		#return
	#
	## считаем, что панель развернута, если хотя бы один ребёнок после header видим
	#var expanded := false
	#var children := items.get_children()
	#for i in range(1, children.size()):
		#var c = children[i]
		#if c is CanvasItem and c.visible:
			#expanded = true
			#break
	#
	#if expanded:
		## Сворачиваем: скрываем все элементы кроме заголовка
		#for i in range(1, children.size()):
			#var c = children[i]
			#if c is CanvasItem:
				#c.visible = false
		## При первом сворачивании запоминаем «правильную» полную высоту панели
		#if _bottom_panel_full_height == 0.0:
			#_bottom_panel_full_height = panel.size.y
		## Делаем панель компактной, оставляя высоту только под заголовок
		#panel.custom_minimum_size.y = header.size.y + 40.0
		#var icon = roll_button.get_node_or_null("Icon")
		#if icon:
			#icon.rotation_degrees = 180.0  # стрелка вверх
	#else:
		## Разворачиваем: показываем все элементы после заголовка
		#for i in range(1, children.size()):
			#var c = children[i]
			#if c is CanvasItem:
				#c.visible = true
		## При разворачивании возвращаем панель к сохранённой полной высоте,
		## чтобы она выглядела так же, как в первый раз
		#if _bottom_panel_full_height > 0.0:
			#panel.custom_minimum_size.y = _bottom_panel_full_height
		#var icon2 = roll_button.get_node_or_null("Icon")
		#if icon2:
			#icon2.rotation_degrees = 0.0  # стрелка вниз
