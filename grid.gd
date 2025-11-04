extends Node2D

@export var grid_spacing_x: int = 50
@export var grid_spacing_y: int = 50
@export var grid_color: Color = Color(0.5, 0.5, 0.5, 0.3)
@export var axis_color_x: Color = Color(1, 0, 0)
@export var axis_color_y: Color = Color(0, 0, 1)
@export var label_color: Color = Color(1, 1, 1)

@export var font: Font

@export var game_node_path: NodePath
var game_node

func _ready():
	if game_node_path != null:
		game_node = get_node(game_node_path)

func _process(_delta):
	call_deferred("update")

func _draw():
	if game_node == null:
		return

	var screen_size = get_viewport_rect().size
	var center = game_node.screen_center
	var base_unit = game_node.base_unit

	var x_min = -center.x / base_unit
	var x_max = (screen_size.x - center.x) / base_unit
	var y_min = -center.y / base_unit
	var y_max = (screen_size.y - center.y) / base_unit

	# Вертикальные линии
	for i in range(int(floor(x_min)), int(ceil(x_max)) + 1):
		var x_pos = center.x + i * base_unit
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, screen_size.y), grid_color, 1)

	# Горизонтальные линии (Y вверх)
	for j in range(int(floor(y_min)), int(ceil(y_max)) + 1):
		var y_pos = center.y - j * base_unit
		draw_line(Vector2(0, y_pos), Vector2(screen_size.x, y_pos), grid_color, 1)

	# Оси
	draw_line(Vector2(0, center.y), Vector2(screen_size.x, center.y), axis_color_x, 2)
	draw_line(Vector2(center.x, 0), Vector2(center.x, screen_size.y), axis_color_y, 2)

	# Подписи
	for i in range(int(floor(x_min)), int(ceil(x_max)) + 1):
		if i != 0:
			var pos = Vector2(center.x + i * base_unit + 5, center.y + 5)
			draw_string(font, pos, str(i))

	for j in range(int(floor(y_min)), int(ceil(y_max)) + 1):
		if j != 0:
			var pos = Vector2(center.x + 5, center.y - j * base_unit - 5)
			draw_string(font, pos, str(j))

	draw_string(font, center + Vector2(5, 5), "0")
