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

enum FuncType { LINEAR, QUADRATIC, SIN, COS }

func _ready():
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
		$UI/Button.pressed.connect(func() -> void: select_option(0))
	if $UI/Button2:
		$UI/Button2.pressed.connect(func() -> void: select_option(1))
	if $UI/Button3:
		$UI/Button3.pressed.connect(func() -> void: select_option(2))

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


func _process(delta):
	check_star_collection()
	check_exit_reached()
	check_ball_fall_off_screen()
	
#func _physics_process(delta):
	#if not ball.freeze:
		#if ball.linear_velocity.y < 0:
			#var boost = Vector2(0, -860)
			#ball.apply_central_impulse(boost * delta)


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
	for i in range(-50, 101):
		var fx = i
		var fy = expr.execute([fx])
		var x = fx * x_scale
		var y = -fy * y_scale
		points.append(Vector2(x, y))

	if line2d:
		line2d.points = points

	for i in range(points.size() - 1):
		var seg = SegmentShape2D.new()
		seg.a = points[i]
		seg.b = points[i + 1]
		var col = CollisionShape2D.new()
		col.shape = seg
		track_static.add_child(col)

func random_function():
	var type = randi() % 4
	var func_str = ""
	match type:
		FuncType.LINEAR:
			var k = 0.0
			while k == 0.0:
				k = round(randf_range(-1.0, 1.0) * 10) / 10.0
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
			var phi = round(randf_range(0.0, PI*2) * 10) / 10.0
			func_str = str(A) + "*sin(" + str(f) + "*x + " + str(phi) + ")"
		FuncType.COS:
			var A = round(randf_range(1.0, 3.0) * 10) / 10.0
			var f = round(randf_range(0.1, 0.5) * 10) / 10.0
			var phi = round(randf_range(0.0, PI*2) * 10) / 10.0
			func_str = str(A) + "*cos(" + str(f) + "*x + " + str(phi) + ")"
	return func_str

func generate_new_level():
	setup_ui()
	$track.visible = false
	score = 0
	update_score_label()

	while true:
		ball.position = Vector2(100, 100)
		first_selection_done = false

		for s in stars:
			s.visible = true

		options.clear()
		for i in range(3):
			options.append(random_function())

		correct_index = randi() % options.size()
		current_correct_func = options[correct_index]

		var expr = Expression.new()
		expr.parse(current_correct_func, ["x"])

		var control_x = [20, 50, 80]
		for i in range(stars.size()):
			var fx = control_x[i]
			var fy = expr.execute([fx])
			stars[i].position = track_static.position + Vector2(fx * x_scale, -fy * y_scale - 35)

		var exit_x = 100
		var exit_y = expr.execute([exit_x])
		exit.position = track_static.position + Vector2(exit_x * x_scale, -exit_y * y_scale - 35)

		if is_level_valid():
			break

	if $UI/Button:
		$UI/Button.text = options[0]
	if $UI/Button2:
		$UI/Button2.text = options[1]
	if $UI/Button3:
		$UI/Button3.text = options[2]

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
	if ball.global_position.y > screen_rect.size.y + 100 || ball.global_position.x > screen_rect.size.x + 50 || ball.global_position.x < -50:
		ball.freeze = true
		fail_popup.show()

func show_level_complete_popup():
	ball.freeze = true
	level_label.text = "Уровень " + str(level) + " пройден!"
	level_complete_popup.show()

func reset_current_level():
	for child in track_static.get_children():
		if child is CollisionShape2D:
			child.queue_free()

	$track.visible = false
	ball.position = Vector2(100, 100)
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0
	ball.freeze = true
	first_selection_done = false
	score = 0
	update_score_label()

	var expr = Expression.new()
	if expr.parse(current_correct_func, ["x"]) == OK:
		var control_x = [20, 50, 80]
		for i in range(stars.size()):
			var fx = control_x[i]
			var fy = expr.execute([fx])
			stars[i].visible = true
			stars[i].position = track_static.position + Vector2(fx * x_scale, -fy * y_scale - 35)

		var exit_x = 100
		var exit_y = expr.execute([exit_x])
		exit.position = track_static.position + Vector2(exit_x * x_scale, -exit_y * y_scale - 35)

	draw_track(current_correct_func)

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


func is_level_valid() -> bool:
	var screen_rect = get_viewport_rect()
	var margin_x = 100
	var margin_y = 50
	
	if ball.global_position.x < -margin_x or ball.global_position.x > screen_rect.size.x + margin_x \
	or ball.global_position.y < -margin_y or ball.global_position.y > screen_rect.size.y + margin_y:
		return false
	
	if exit.global_position.x < -margin_x or exit.global_position.x > screen_rect.size.x + margin_x \
	or exit.global_position.y < -margin_y or exit.global_position.y > screen_rect.size.y + margin_y:
		return false
	
	for star in stars:
		if star.global_position.x < -margin_x or star.global_position.x > screen_rect.size.x + margin_x \
		or star.global_position.y < -margin_y or star.global_position.y > screen_rect.size.y + margin_y:
			return false
	
	return true
