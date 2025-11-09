extends Node

var root
var options = []
var current_correct_func = ""

enum FuncType { LINEAR, QUADRATIC, SIN, COS }

enum Side { LEFT, RIGHT }

enum LevelType {
	SIMPLE,         # просто случайные функции
	VARY_B,         # одинаковое k, разные b
	VARY_K,         # одинаковое b, разные k
	QUADRATIC,      # квадратичные функции
	TRIG            # синусы и косинусы
}

const STAGE_TO_TYPE = [
	LevelType.SIMPLE,  # 1
	LevelType.SIMPLE,  # 2
	LevelType.SIMPLE,  # 3
	LevelType.SIMPLE,  # 4
	LevelType.SIMPLE,  # 5
	LevelType.VARY_B,  # 6
	LevelType.VARY_B,  # 7
	LevelType.VARY_B,  # 8
	LevelType.VARY_K,  # 9
	LevelType.VARY_K,  # 10
	LevelType.VARY_K   # 11
]

func init(r):
	root = r
	if root.utils:
		root.utils.calc_base_unit()


func generate_new_level():
	root.utils.enable_option_buttons(root)
	root.track.visible = false
	root.score = 0
	root.ui.update_score_label()
	root.first_selection_done = false
	for s in root.stars:
		s.visible = true

	root.ball_side = Side.RIGHT if randi() % 2 == 0 else Side.LEFT
	print("Выбранная сторона шара:", "RIGHT" if root.ball_side == Side.RIGHT else "LEFT")

	var valid_correct_func = ""
	for i in range(100):
		var candidate = random_function([FuncType.LINEAR]) if root.level < 10 else random_function()
		if root.utils.is_level_valid_for_edges(candidate, root.ball_side):
			valid_correct_func = candidate
			break
	if valid_correct_func == "":
		valid_correct_func = "0.5*x"


	current_correct_func = valid_correct_func

	var stage = ((root.level - 1) % 11) + 1
	var lvl_type = STAGE_TO_TYPE[stage - 1]
	print("Стадия:", stage, "Тип уровня:", lvl_type)

	options = generate_options_for_type(lvl_type, valid_correct_func)

	while options.size() < 3:
		var fallback = random_function([FuncType.LINEAR])
		if not options.has(fallback):
			options.append(fallback)

	options.shuffle()

	var expr = Expression.new()
	if expr.parse(valid_correct_func, ["x"]) == OK:
		root.utils.setup_level_positions(expr)

	if root.get_node("UI/Buttons/Button"): root.get_node("UI/Buttons/Button").text = options[0]
	if root.get_node("UI/Buttons/Button2"): root.get_node("UI/Buttons/Button2").text = options[1]
	if root.get_node("UI/Buttons/Button3"): root.get_node("UI/Buttons/Button3").text = options[2]

	root.track_drawer.draw_track(current_correct_func)


func generate_options_for_type(lvl_type: int, base_func: String) -> Array:
	var opts = [base_func]

	match lvl_type:
		#LevelType.SIMPLE:
			#while opts.size() < 3:
				#var cand = random_function([FuncType.LINEAR])
				#if not opts.has(cand) and root.utils.is_level_valid_for_edges(cand, root.ball_side):
					#opts.append(cand)
					
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
				if not opts.has(cand) and root.utils.is_level_valid_for_edges(cand, root.ball_side):
					opts.append(cand)

		LevelType.TRIG:
			while opts.size() < 3:
				var cand = random_function([FuncType.SIN, FuncType.COS])
				if not opts.has(cand) and root.utils.is_level_valid_for_edges(cand, root.ball_side):
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
				k = round(randf_range(-1.5, 1.5) * 10) / 10.0
			var b = round(randf_range(-5.0, 5.0) * 10) / 10.0
			func_str = str(k) + "*x + " + str(b)
		FuncType.QUADRATIC:
			var a = round(randf_range(-0.1, 0.1) * 10) / 10.0
			if a == 0.0: a = 0.05
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
	root.utils.enable_option_buttons(root)
	for child in root.track.get_children():
		if child is CollisionShape2D:
			child.queue_free()

	root.track.visible = false
	root.ball.linear_velocity = Vector2.ZERO
	root.ball.angular_velocity = 0
	root.ball.freeze = true
	root.score = 0
	root.ui.update_score_label()
	root.first_selection_done = false

	var expr = Expression.new()
	if expr.parse(current_correct_func, ["x"]) == OK:
		root.utils.setup_level_positions(expr)
		root.track_drawer.draw_track(current_correct_func)
