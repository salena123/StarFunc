extends Node2D

@export var grid_spacing_x: int = 50
@export var grid_spacing_y: int = 50
@export var grid_color: Color = Color(0.169, 0.106, 0.067, 0.302)
@export var axis_color_x: Color = Color(1, 1, 1)
@export var axis_color_y: Color = Color(1, 1, 1)
@export var label_color: Color = Color(1, 1, 1)

@export var font: Font

@export var game_node_path: NodePath
var game_node

func _ready():
	if game_node_path != null:
		game_node = get_node(game_node_path)

func _process(_delta):
	queue_redraw()

func _draw():
	if game_node == null:
		return
	if not ("utils" in game_node) or game_node.utils == null:
		return

	var screen_size = get_viewport_rect().size
	var base_unit = game_node.base_unit
	if base_unit == null or is_equal_approx(base_unit, 0.0):
		return
	var utils = game_node.utils
	# Ensure utils has up-to-date bounds.
	if utils.has_method("ensure_coordinate_bounds"):
		utils.ensure_coordinate_bounds()

	var x_min = utils.x_min
	var x_max = utils.x_max
	var y_min = utils.y_min
	var y_max = utils.y_max

	# Вертикальные линии
	for i in range(int(floor(x_min)), int(ceil(x_max)) + 1):
		var x_pos = utils.fx_to_screen(float(i))
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, screen_size.y), grid_color, 1)

	# Горизонтальные линии (Y вверх)
	for j in range(int(floor(y_min)), int(ceil(y_max)) + 1):
		var y_pos = utils.fy_to_screen(float(j))
		draw_line(Vector2(0, y_pos), Vector2(screen_size.x, y_pos), grid_color, 1)

	# Оси
	var axis_y = utils.fy_to_screen(0.0)
	var axis_x = utils.fx_to_screen(0.0)
	draw_line(Vector2(0, axis_y), Vector2(screen_size.x, axis_y), axis_color_x, 2)
	draw_line(Vector2(axis_x, 0), Vector2(axis_x, screen_size.y), axis_color_y, 2)

	# Подписи
	for i in range(int(floor(x_min)), int(ceil(x_max)) + 1):
		if i != 0:
			var pos = Vector2(utils.fx_to_screen(float(i)) + 5, axis_y + 5)
			draw_string(font, pos, str(i))

	for j in range(int(floor(y_min)), int(ceil(y_max)) + 1):
		if j != 0:
			var pos = Vector2(axis_x + 5, utils.fy_to_screen(float(j)) - 5)
			draw_string(font, pos, str(j))

	draw_string(font, Vector2(axis_x + 5, axis_y + 5), "0")
