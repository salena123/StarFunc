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

@onready var ball = $ball
@onready var stars = $stars.get_children()
@onready var track = $track
@onready var line2d = $track/Line2D
@onready var track2 = $track2
@onready var line2d2 = $track2/Line2D
@onready var forward_button = $UI/Buttons/ForwardButton
@onready var option_buttons = [
	$UI/Buttons/Button,
	$UI/Buttons/Button2,
	$UI/Buttons/Button3
]
@onready var option_buttons2 = [
	$UI/Buttons2/Button,
	$UI/Buttons2/Button2,
	$UI/Buttons2/Button3
]
@onready var input_panel = $UI/InputPanel
@onready var k_input = get_node_or_null("UI/InputPanel/KInput")
@onready var b_input = get_node_or_null("UI/InputPanel/BInput")
@onready var k_slider = get_node_or_null("UI/InputPanel/KSlider")
@onready var k_value_label = get_node_or_null("UI/InputPanel/KValueLabel")
@onready var b_slider = get_node_or_null("UI/InputPanel/BSlider")
@onready var b_value_label = get_node_or_null("UI/InputPanel/BValueLabel")
@onready var build_button = get_node_or_null("UI/InputPanel/BuildButton")
@onready var forward_button_input = get_node_or_null("UI/InputPanel/ForwardButtonInput")
@onready var error_label = get_node_or_null("UI/InputPanel/ErrorLabel")
@onready var restart = $UI/Restart
@onready var timer_label = $UI/Timer
@onready var k_slider_label = get_node_or_null("UI/Slider/KLabel")
@onready var b_slider_label = get_node_or_null("UI/Slider/BLabel")
@onready var x_label = get_node_or_null("UI/Slider/XLabel")
@onready var y_label = get_node_or_null("UI/Slider/YLabel")

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
		timer_label.text = "Таймер: --"
	
	set_process(true)
	print_scene_info()
	if has_node("UI/Slider"):
		get_node("UI/Slider").visible = false
	forward_button.pressed.connect(func():
		utils.on_forward_pressed(self, forward_button, option_buttons + option_buttons2))
	forward_button.hide()
	forward_button_input.pressed.connect(func():
		utils.on_forward_pressed(self, forward_button_input, option_buttons + option_buttons2))
	forward_button_input.hide()
	
	setup_sliders()
	
	level_gen.generate_new_level()
	build_button.pressed.connect(func():
		utils.on_build_button_pressed(self, k_input, b_input, track_drawer, track, forward_button_input, level_gen))
	
	
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
	forward_button.show()
	
	if timer and timer.is_stopped():
		timer.wait_time = timer_duration
		timer.start()
		if timer_label:
			timer_label.text = "Таймер: " + str(timer_duration)
		print("Таймер запущен, выбрана функция:", func_str)

func _on_timer_timeout():
	if timer_label:
		timer_label.text = "Таймер: 0.0"
	physics.check_level_complete_by_stars()

func update_timer_display():
	if timer_label and timer:
		if timer.is_stopped():
			timer_label.text = "Таймер: --"
		else:
			var time_left = timer.time_left
			timer_label.text = "Таймер: " + str(round(time_left * 10) / 10.0)

func print_scene_info():
	var rect = get_viewport_rect()
	print("Размер экрана:", rect.size)
	print("Ball:", ball.global_position)
	for i in range(stars.size()):
		print("Star", i + 1, ":", stars[i].global_position)

func setup_sliders():
	# === K SLIDER ===
	if not has_node("UI/InputPanel/KSlider"):
		var k_slider_node = HSlider.new()
		k_slider_node.name = "KSlider"
		k_slider_node.min_value = -1.5
		k_slider_node.max_value = 1.5
		k_slider_node.step = 0.1
		k_slider_node.value = 0.0
		k_slider_node.position = Vector2(42, 25)
		k_slider_node.size = Vector2(100, 20)
		$UI/InputPanel.add_child(k_slider_node)
		k_slider = k_slider_node
	else:
		k_slider = $UI/InputPanel/KSlider
		k_slider.min_value = -1.5
		k_slider.max_value = 1.5

	# === B SLIDER ===
	if not has_node("UI/InputPanel/BSlider"):
		var b_slider_node = HSlider.new()
		b_slider_node.name = "BSlider"
		b_slider_node.min_value = -10.0
		b_slider_node.max_value = 10.0
		b_slider_node.step = 0.1
		b_slider_node.value = 0.0
		b_slider_node.position = Vector2(149, 25)
		b_slider_node.size = Vector2(100, 20)
		$UI/InputPanel.add_child(b_slider_node)
		b_slider = b_slider_node
	else:
		b_slider = $UI/InputPanel/BSlider
		b_slider.min_value = -10.0
		b_slider.max_value = 10.0

	# === Connect ===
	if k_slider:
		k_slider.value_changed.connect(_on_k_slider_changed)

	if b_slider:
		b_slider.value_changed.connect(_on_b_slider_changed)


func _on_k_slider_changed(value: float):
	var lvl_type = level_gen.get_level_type(level)
	if lvl_type == level_gen.LevelType.INPUT_SLIDER:
		var formatted_value = utils.format_number(value)

		if k_slider_label:
			k_slider_label.text = formatted_value


func _on_b_slider_changed(value: float):
	if level_gen.get_level_type(level) == level_gen.LevelType.INPUT_SLIDER:
		if b_slider_label:
			b_slider_label.text = utils.format_number(value)


func _on_k_input_changed(new_text: String):
	var lvl_type = level_gen.get_level_type(level)
	if lvl_type == level_gen.LevelType.INPUT_SLIDER and k_slider and k_slider.visible:
		if new_text != "":
			if new_text.is_valid_float() or new_text.is_valid_int():
				var val = float(new_text)
				val = clamp(val, k_slider.min_value, k_slider.max_value)
				k_slider.value = val

func _on_b_input_changed(new_text: String):
	var lvl_type = level_gen.get_level_type(level)
	if lvl_type == level_gen.LevelType.INPUT_SLIDER and b_slider and b_slider.visible:
		if new_text != "":
			if new_text.is_valid_float() or new_text.is_valid_int():
				var val = float(new_text)
				val = clamp(val, b_slider.min_value, b_slider.max_value)
				b_slider.value = val

func setup_ui_buttons():
	if $UI/Buttons/Button:
		$UI/Buttons/Button.pressed.connect(func(): select_option(0, 0))
	if $UI/Buttons/Button2:
		$UI/Buttons/Button2.pressed.connect(func(): select_option(1, 0))
	if $UI/Buttons/Button3:
		$UI/Buttons/Button3.pressed.connect(func(): select_option(2, 0))
	if option_buttons2.size() > 0 and option_buttons2[0]:
		option_buttons2[0].pressed.connect(func(): select_option(0, 1))
	if option_buttons2.size() > 1 and option_buttons2[1]:
		option_buttons2[1].pressed.connect(func(): select_option(1, 1))
	if option_buttons2.size() > 2 and option_buttons2[2]:
		option_buttons2[2].pressed.connect(func(): select_option(2, 1))
