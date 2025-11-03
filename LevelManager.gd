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
var x_scale = 10.0
var y_scale = 10.0
var first_selection_done = false
var current_correct_func = ""
var top_margin = 50
var bottom_margin = 50

enum FuncType { LINEAR, QUADRATIC, SIN, COS }

#var screen_size = get_viewport_rect().size
var x_min = 0
var x_max = 100
var y_min = -50
var y_max = 50
var vertical_offset_pixels = 35

func fx_to_screen(x):
	return lerp(0.0, float(screen_size.x), (x - x_min) / (x_max - x_min))

func fy_to_screen(y):
	return lerp(float(screen_size.y), 0.0, (y - y_min) / (y_max - y_min))

func fy_to_screen_track(fy_val):
	var track_height = get_viewport_rect().size.y - top_margin - bottom_margin
	var t = (fy_val - y_min) / (y_max - y_min)
	return get_viewport_rect().size.y - bottom_margin - t * track_height

var screen_size: Vector2

func _ready():
	screen_size = get_viewport_rect().size
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
		$UI/Button.pressed.connect(func() -> void:
			select_option(0)
		)
	if $UI/Button2:
		$UI/Button2.pressed.connect(func() -> void:
			select_option(1)
		)
	if $UI/Button3:
		$UI/Button3.pressed.connect(func() -> void:
			select_option(2)
		)
	if retry_button:
		retry_button.pressed.connect(func() -> void:
			level_complete_popup.hide()
			reset_current_level()
		)
	if next_button:
		next_button.pressed.connect(func() -> void:
			level_complete_popup.hide()
			level += 1
			generate_new_level()
		)
	if fail_retry_button:
		fail_retry_button.pressed.connect(func() -> void:
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
	var screen_height = get_viewport_rect().size.y

	for i in range(101):
		var x_val = lerp(x_min, x_max, i / 100.0)
		var y_val = expr.execute([x_val])
		points.append(Vector2(fx_to_screen(x_val), fy_to_screen_track(y_val)))

	if line2d:
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
			while k == 0.0 || abs(k) < 0.4:
				k = round(randf_range(-2.0, 2.0) * 10) / 10.0
			var b = round(randf_range(-15.0, 5.0) * 10) / 10.0
			func_str = str(k) + "*x + " + str(b)
		FuncType.QUADRATIC:
			var a = 0.0
			while a == 0.0:
				a = round(randf_range(-0.5, 0.5) * 10) / 10.0
			var b = round(randf_range(-1.0, 1.0) * 10) / 10.0
			var c = round(randf_range(-5.0, 5.0) * 10) / 10.0
			func_str = str(a) + "*x*x + " + str(b) + "*x + " + str(c)
		FuncType.SIN:
			var A = round(randf_range(1.0, 3.0) * 10) / 10.0
			var f = round(randf_range(0.1, 0.5) * 10) / 10.0
			var phi = round(randf_range(0.0, PI * 2) * 10) / 10.0
			func_str = str(A) + "*sin(" + str(f) + "*x + " + str(phi) + ")"
		FuncType.COS:
			var A = round(randf_range(1.0, 3.0) * 10) / 10.0
			var f = round(randf_range(0.1, 0.5) * 10) / 10.0
			var phi = round(randf_range(0.0, PI * 2) * 10) / 10.0
			func_str = str(A) + "*cos(" + str(f) + "*x + " + str(phi) + ")"
	return func_str

func setup_level_positions(expr: Expression):
	var control_x_frac = [0.2, 0.5, 0.8]
	var vertical_offset_frac = 0.05

	for i in range(stars.size()):
		var fx_val = control_x_frac[i] * (x_max - x_min) + x_min
		var fy_val = expr.execute([fx_val])
		stars[i].visible = true
		stars[i].position = Vector2(fx_to_screen(fx_val), fy_to_screen_track(fy_val) - vertical_offset_pixels)

	var y_start = expr.execute([x_min])
	var y_end = expr.execute([x_max])
	var k = y_end - y_start
	var ball_x = x_max if k > 0 else x_min
	var exit_x = x_min if k > 0 else x_max
	var ball_y = expr.execute([ball_x])
	var exit_y = expr.execute([exit_x])

	ball.position = Vector2(fx_to_screen(ball_x), fy_to_screen_track(ball_y) - vertical_offset_pixels)
	exit.position = Vector2(fx_to_screen(exit_x), fy_to_screen_track(exit_y) - vertical_offset_pixels)
	
func generate_new_level():
	$track.visible = false
	score = 0
	update_score_label()
	first_selection_done = false

	for s in stars:
		s.visible = true

	var max_attempts = 1000
	var attempts = 0
	var valid_correct_func = ""
	while attempts < max_attempts:
		attempts += 1
		var candidate = random_function([FuncType.LINEAR]) if level < 10 else random_function()
		print("Попытка ", attempts, ": пробуем ", candidate)
		if is_level_valid_for_edges(candidate):
			valid_correct_func = candidate
			print("Последний валидный график: " + valid_correct_func)
			break

	if valid_correct_func == "":
		print("Не найден валидный график за", max_attempts, "попыток. Использую fallback.")
		valid_correct_func = "0.5 * x - 4"

	current_correct_func = valid_correct_func

	options.clear()
	options.append(valid_correct_func)
	while options.size() < 3:
		var candidate2 = random_function([FuncType.LINEAR]) if level < 10 else random_function()
		# избегаем дубликатов
		if candidate2 != valid_correct_func and not options.has(candidate2):
			options.append(candidate2)

	correct_index = randi() % options.size()
	var temp = options[0]
	options[0] = options[correct_index]
	options[correct_index] = temp

	var expr = Expression.new()
	if expr.parse(valid_correct_func, ["x"]) == OK:
		setup_level_positions(expr)

	if $UI/Button:
		$UI/Button.text = options[0]
	if $UI/Button2:
		$UI/Button2.text = options[1]
	if $UI/Button3:
		$UI/Button3.text = options[2]

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
	var screen_rect = get_viewport_rect()
	if ball.global_position.y > screen_rect.size.y + 100 \
	or ball.global_position.x > screen_rect.size.x + 50 \
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
	var screen_rect = get_viewport_rect()
	print("Размер экрана: ", screen_rect.size)
	print("---Шар и выход ---")
	if ball:
		print("Ball: ", ball.global_position)
	if exit:
		print("Exit: ", exit.global_position)
	if stars.size() > 0:
		for i in range(stars.size()):
			print("Star", i + 1, ": ", stars[i].global_position)
	if track_static:
		print("Track: ", track_static.global_position)
	print("")
	print("--- UI ---")
	if $UI:
		for child in $UI.get_children():
			if child is Control:
				print(child.name, ": позиция =", child.position, ", глобальная позиция =", child.global_position)
	else:
		print("UI не найден")

func is_level_valid_for_edges(func_str: String) -> bool:
	var expr = Expression.new()
	if expr.parse(func_str, ["x"]) != OK:
		return false

	var min_x = 0
	var max_x = 100
	var y_start = expr.execute([min_x])
	var y_end = expr.execute([max_x])
	if typeof(y_start) != TYPE_FLOAT or typeof(y_end) != TYPE_FLOAT:
		return false

	var k = y_end - y_start
	if abs(k) < 0.04:
		return false

	var screen_height = get_viewport_rect().size.y
	var base_y = screen_height * 0.6
	var start_y_screen = base_y - y_start * y_scale
	var end_y_screen = base_y - y_end * y_scale

	var margin = 20
	if start_y_screen < -margin or start_y_screen > screen_height + margin:
		return false
	if end_y_screen < -margin or end_y_screen > screen_height + margin:
		return false

	var ball_x = 0
	var exit_x = 100
	if k > 0:
		ball_x = 100
		exit_x = 0
	else:
		ball_x = 0
		exit_x = 100
	var ball_y = expr.execute([ball_x])
	var exit_y = expr.execute([exit_x])
	var ball_y_screen = base_y - ball_y * y_scale
	var exit_y_screen = base_y - exit_y * y_scale
	if not (ball_y_screen < exit_y_screen):
		return false

	var control_x = [20, 50, 80]
	var star_on_path = false
	for fx in control_x:
		var fy = expr.execute([fx])
		var star_y_screen = base_y - fy * y_scale
		if star_y_screen > ball_y_screen and star_y_screen < exit_y_screen:
			star_on_path = true
			break

	return star_on_path
