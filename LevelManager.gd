extends Node2D

@onready var line2d = $track/Line2D
@onready var track_static = $track
@onready var ball = $ball
@onready var exit = $exit
@onready var stars = $stars.get_children()
@onready var score_label = $UI/ScoreLabel
@onready var level_complete_popup = $UI/LevelCompletePopup
@onready var retry_button = $UI/LevelCompletePopup/RetryButton
@onready var next_button = $UI/LevelCompletePopup/NextButton
@onready var level_label = $UI/LevelCompletePopup/Label
@onready var fail_popup = $UI/FailPopup
@onready var fail_retry_button = $UI/FailPopup/RetryButton

var options = []
var correct_index = 0
var score = 0
var level = 1
var first_selection_done = false
var current_correct_func = ""
var top_margin = 50
var bottom_margin = 50
var vertical_offset_pixels = 35

enum FuncType { LINEAR, QUADRATIC, SIN, COS }
enum Side { LEFT, RIGHT }

var ball_side: int = Side.RIGHT
var screen_size: Vector2


var x_min: float
var x_max: float
var y_min: float
var y_max: float
var base_unit: float
var screen_center: Vector2

var x_scale = 1.0
var y_scale = 1.0

func calc_base_unit():

	var min_side = min(screen_size.x, screen_size.y)
	var desired_range = min_side * 0.1 
	base_unit = min(screen_size.x, screen_size.y) / desired_range
	x_min = -screen_size.x / (2 * base_unit)
	x_max = screen_size.x / (2 * base_unit)
	y_min = -screen_size.y / (2 * base_unit)
	y_max = screen_size.y / (2 * base_unit)

func fx_to_screen(x):
	return screen_center.x + x * base_unit

func fy_to_screen(y):
	return screen_center.y - y * base_unit

func fy_to_screen_track(fy_val):
	var track_height = screen_size.y - top_margin - bottom_margin
	var t = (fy_val - y_min) / (y_max - y_min)
	return screen_size.y - bottom_margin - t * track_height

func _ready():
	screen_size = get_viewport_rect().size
	screen_center = screen_size / 2
	calc_base_unit()
	randomize()
	setup_ui()
	generate_new_level()
	print_scene_info()
	$track.visible = false
	ball.freeze = true
	ball.linear_damp = 0.0
	ball.angular_damp = 0.0
	ball.continuous_cd = true
	set_process(true)
	update_score_label()

func setup_ui():
	if $UI/Button:
		$UI/Button.pressed.connect(func(): select_option(0))
	if $UI/Button2:
		$UI/Button2.pressed.connect(func(): select_option(1))
	if $UI/Button3:
		$UI/Button3.pressed.connect(func(): select_option(2))
	if retry_button:
		retry_button.pressed.connect(func():
			level_complete_popup.hide()
			reset_current_level()
		)
	if next_button:
		next_button.pressed.connect(func():
			level_complete_popup.hide()
			level += 1
			generate_new_level()
		)
	if fail_retry_button:
		fail_retry_button.pressed.connect(func():
			fail_popup.hide()
			reset_current_level()
		)
	level_complete_popup.hide()
	fail_popup.hide()


func _process(_delta):
	check_star_collection()
	check_exit_reached()
	check_ball_fall_off_screen()


func select_option(index):
	draw_track(options[index])
	$track.visible = true
	if not first_selection_done:
		ball.freeze = false
		first_selection_done = true
		ball.apply_impulse(Vector2.ZERO, Vector2(0, 50))


func draw_track(input_str: String):
	for child in track_static.get_children():
		if child is CollisionShape2D:
			child.queue_free()

	var expr = Expression.new()
	if expr.parse(input_str, ["x"]) != OK:
		return

	var points = []
	var step = (x_max - x_min) / 100.0

	if ball_side == Side.RIGHT:
		for i in range(101):
			var x = x_max - i * step
			points.append(Vector2(fx_to_screen(x), fy_to_screen_track(expr.execute([x]))))
	else:
		for i in range(101):
			var x = x_min + i * step
			points.append(Vector2(fx_to_screen(x), fy_to_screen_track(expr.execute([x]))))

	line2d.points = points

	for i in range(points.size() - 1):
		var seg = SegmentShape2D.new()
		seg.a = points[i]
		seg.b = points[i + 1]
		var col = CollisionShape2D.new()
		col.shape = seg
		track_static.add_child(col)


func random_function(allowed_types: Array = []) -> String:
	if allowed_types.is_empty():
		allowed_types = [FuncType.LINEAR, FuncType.QUADRATIC, FuncType.SIN, FuncType.COS]

	var type = allowed_types[randi() % allowed_types.size()]
	var func_str = ""
	match type:
		FuncType.LINEAR:
			var k = 0.0
			while abs(k) < 0.2:
				k = round(randf_range(-1.5, 1.5) * 10) / 10.0
			var b = round(randf_range(-5.0, 5.0) * 10) / 10.0
			func_str = str(k) + "*x + " + str(b)
		FuncType.QUADRATIC:
			var a = round(randf_range(-0.1, 0.1) * 10) / 10.0
			if a == 0.0: a = 0.05
			var b = round(randf_range(-0.8, 0.8) * 10) / 10.0
			var c = round(randf_range(-4.0, 4.0) * 10) / 10.0
			func_str = str(a) + "*x*x + " + str(b) + "*x + " + str(c)
		FuncType.SIN:
			var A = round(randf_range(1.0, 2.0) * 10) / 10.0
			var f = round(randf_range(0.05, 0.3) * 10) / 10.0
			func_str = str(A) + "*sin(" + str(f) + "*x)"
		FuncType.COS:
			var A = round(randf_range(1.0, 2.0) * 10) / 10.0
			var f = round(randf_range(0.05, 0.3) * 10) / 10.0
			func_str = str(A) + "*cos(" + str(f) + "*x)"
	return func_str


func setup_level_positions(expr: Expression):
	var control_x = [-25, 0, 25]
	for i in range(stars.size()):
		var fx_val = control_x[i]
		var fy_val = expr.execute([fx_val])
		stars[i].visible = true
		stars[i].position = Vector2(fx_to_screen(fx_val), fy_to_screen_track(fy_val) - vertical_offset_pixels)

	var ball_x = 40 if ball_side == Side.RIGHT else -40
	var exit_x = -40 if ball_side == Side.RIGHT else 40
	var ball_y = expr.execute([ball_x])
	var exit_y = expr.execute([exit_x])
	var screen_top = 0
	ball.position = Vector2(fx_to_screen(ball_x), screen_top + vertical_offset_pixels)
	exit.position = Vector2(fx_to_screen(exit_x), fy_to_screen_track(exit_y) - vertical_offset_pixels)


func generate_new_level():
	$track.visible = false
	score = 0
	update_score_label()
	first_selection_done = false
	for s in stars:
		s.visible = true

	ball_side = Side.RIGHT if randi() % 2 == 0 else Side.LEFT
	print("Выбранная сторона шарика:", "RIGHT" if ball_side == Side.RIGHT else "LEFT")

	var valid_correct_func = ""
	for i in range(100):
		var candidate = random_function([FuncType.LINEAR]) if level < 10 else random_function()
		if is_level_valid_for_edges(candidate, ball_side):
			valid_correct_func = candidate
			break

	if valid_correct_func == "":
		valid_correct_func = "0.5*x - 2"

	current_correct_func = valid_correct_func
	options = [valid_correct_func]
	while options.size() < 3:
		var candidate2 = random_function([FuncType.LINEAR])
		if not options.has(candidate2):
			options.append(candidate2)

	options.shuffle()

	var expr = Expression.new()
	if expr.parse(valid_correct_func, ["x"]) == OK:
		setup_level_positions(expr)

	if $UI/Button: $UI/Button.text = options[0]
	if $UI/Button2: $UI/Button2.text = options[1]
	if $UI/Button3: $UI/Button3.text = options[2]

	draw_track(current_correct_func)


func reset_current_level():
	for child in track_static.get_children():
		if child is CollisionShape2D:
			child.queue_free()
	$track.visible = false
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0
	ball.freeze = true
	score = 0
	update_score_label()
	first_selection_done = false
	var expr = Expression.new()
	if expr.parse(current_correct_func, ["x"]) == OK:
		setup_level_positions(expr)
		draw_track(current_correct_func)


func check_star_collection():
	for star in stars:
		if star.visible and ball.global_position.distance_to(star.global_position) < 25:
			star.visible = false
			score += 1
			update_score_label()


func check_exit_reached():
	if ball.global_position.distance_to(exit.global_position) < 40:
		show_level_complete_popup()


func check_ball_fall_off_screen():
	var rect = get_viewport_rect()
	if ball.global_position.y > rect.size.y + 100 \
	or ball.global_position.x > rect.size.x + 50 \
	or ball.global_position.x < -50:
		ball.freeze = true
		fail_popup.show()


func show_level_complete_popup():
	ball.freeze = true
	level_label.text = "Уровень " + str(level) + " пройден!"
	level_complete_popup.show()


func update_score_label():
	if score_label:
		score_label.text = "Звёзды: " + str(score)


func print_scene_info():
	var rect = get_viewport_rect()
	print("Размер экрана:", rect.size)
	print("Ball:", ball.global_position)
	print("Exit:", exit.global_position)
	for i in range(stars.size()):
		print("Star", i + 1, ":", stars[i].global_position)


func is_level_valid_for_edges(func_str: String, desired_side: int) -> bool:
	var expr = Expression.new()
	if expr.parse(func_str, ["x"]) != OK:
		return false

	var step = (x_max - x_min) / 50.0
	for i in range(51):
		var x = x_min + i * step
		var y = expr.execute([x])
		var screen_y = fy_to_screen(y)
		if screen_y < -50 or screen_y > screen_size.y + 50:
			return false

	var y1 = expr.execute([x_min])
	var y2 = expr.execute([x_max])
	if typeof(y1) != TYPE_FLOAT or typeof(y2) != TYPE_FLOAT:
		return false

	var k = y2 - y1
	if abs(k) < 0.05:
		return false
	if desired_side == Side.RIGHT and k <= 0:
		return false
	if desired_side == Side.LEFT and k >= 0:
		return false

	return true
