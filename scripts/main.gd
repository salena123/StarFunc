extends Node2D

var utils
var ui
var track_drawer
var level_gen
var physics
var lin_gen
var input_linear_module

@onready var ball = $ball
@onready var exit = $exit
@onready var stars = $stars.get_children()
@onready var track = $track
@onready var line2d = $track/Line2D
@onready var forward_button = $UI/Buttons/ForwardButton
@onready var option_buttons = [
	$UI/Buttons/Button,
	$UI/Buttons/Button2,
	$UI/Buttons/Button3
]
@onready var input_panel = $UI/InputPanel
@onready var k_input = $UI/InputPanel/KInput
@onready var b_input = $UI/InputPanel/BInput
@onready var build_button = $UI/InputPanel/BuildButton
@onready var forward_button_input = $UI/InputPanel/ForwardButtonInput
@onready var error_label = $UI/InputPanel/ErrorLabel
@onready var restart = $UI/Restart

var score: int = 0
var level: int = 1
var first_selection_done: bool = false
var ball_side: int
var current_correct_func: String = ""
var base_unit: float
var screen_size: Vector2
var screen_center: Vector2

func _ready():
	utils = preload("res://scripts/utils.gd").new()
	ui = preload("res://scripts/ui_manager.gd").new()
	track_drawer = preload("res://scripts/track_drawer.gd").new()
	level_gen = preload("res://scripts/level_generator.gd").new()
	physics = preload("res://scripts/physics_checker.gd").new()
	input_linear_module = preload("res://scripts/input_linear_level.gd").new()

	screen_size = get_viewport_rect().size
	screen_center = screen_size / 2

	utils.init(self)
	ui.init(self)
	track_drawer.init(self)
	level_gen.init(self)
	physics.init(self)
	input_linear_module.init(self)

	randomize()
	ui.update_score_label()
	setup_ui_buttons()

	$track.visible = false
	ball.freeze = true
	ball.linear_damp = 0.0
	ball.angular_damp = 0.0
	ball.continuous_cd = true

	set_process(true)
	print_scene_info()
	forward_button.pressed.connect(func():
		utils.on_forward_pressed(self, forward_button, option_buttons))
	forward_button.hide()
	forward_button_input.pressed.connect(func():
		utils.on_forward_pressed(self, forward_button_input, option_buttons))
	forward_button_input.hide()
	level_gen.generate_new_level()
	build_button.pressed.connect(func():
		utils.on_build_button_pressed(self, k_input, b_input, track_drawer, track, forward_button_input, level_gen))
	
	
func _process(_delta):
	physics.check_star_collection()
	physics.check_exit_reached()
	physics.check_ball_fall_off_screen()

func select_option(index: int):
	var func_str = level_gen.options[index]
	track_drawer.draw_track(func_str)
	$track.visible = true
	forward_button.show()

func setup_ui_buttons():
	if $UI/Buttons/Button:
		$UI/Buttons/Button.pressed.connect(func(): select_option(0))
	if $UI/Buttons/Button2:
		$UI/Buttons/Button2.pressed.connect(func(): select_option(1))
	if $UI/Buttons/Button3:
		$UI/Buttons/Button3.pressed.connect(func(): select_option(2))

func print_scene_info():
	var rect = get_viewport_rect()
	print("Размер экрана:", rect.size)
	print("Ball:", ball.global_position)
	print("Exit:", exit.global_position)
	for i in range(stars.size()):
		print("Star", i + 1, ":", stars[i].global_position)
