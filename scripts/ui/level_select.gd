extends Control

class_name LevelSelect

@export var time: float = 1.5

@onready var scroll: ScrollContainer = $MapScroll
@onready var map_container: Control = $MapScroll/Control
@onready var map_layer: Node2D = $MapScroll/Control/MapContainer
@onready var path_drawer: Node2D = $MapScroll/Control/MapContainer/PathDrawer
@onready var popup: ConfirmationDialog = $PopupDialog

var level_icons: Array = []
var level_saver = preload("res://scripts/level_saver.gd")


func _ready() -> void:
	await get_tree().process_frame
	_collect_icons()
	_apply_saved_state()
	_scale_map_to_screen()
	_connect_signals()
	_build_path_and_animate()
	_scroll_to_bottom()


func _collect_icons() -> void:
	level_icons.clear()
	for child in map_layer.get_children():
		if child is Node and child.has_method("set_stars") and child.has_method("set_locked"):
			level_icons.append(child)
	level_icons.sort_custom(Callable(self, "_cmp_icons"))
	level_icons.reverse()


func _cmp_icons(a: Object, b: Object) -> int:
	var al: int = int(a.level_number)
	var bl: int = int(b.level_number)
	if al == bl:
		return 0
	elif al < bl:
		return -1
	else:
		return 1


func _apply_saved_state() -> void:
	for icon in level_icons:
		var lvl: int = int(icon.level_number)
		var stars: int = int(level_saver.get_level_stars(lvl))
		icon.set_stars(stars)
		if lvl == 1:
			icon.set_locked(false)
		else:
			var prev_stars: int = int(level_saver.get_level_stars(lvl - 1))
			icon.set_locked(prev_stars <= 0)


func _connect_signals() -> void:
	for icon in level_icons:
		if not icon.is_connected("level_selected", Callable(self, "_on_level_selected")):
			icon.connect("level_selected", Callable(self, "_on_level_selected"))


# -------------------------
# Масштабирование карты
# -------------------------
func _scale_map_to_screen() -> void:
	var design_width: float = 537.0
	var screen_width: float = float(get_viewport().size.x)
	var scale_factor: float = screen_width / design_width
	map_layer.scale = Vector2(scale_factor, scale_factor)

	var bounds: Rect2 = _compute_map_layer_bounds()
	if bounds.size == Vector2.ZERO:
		bounds.size = Vector2(100.0, 100.0)

	var content_size: Vector2 = bounds.size * scale_factor
	map_container.custom_minimum_size = content_size

func _compute_map_layer_bounds() -> Rect2:
	var first: bool = true
	var min_x: float = 0.0
	var min_y: float = 0.0
	var max_x: float = 0.0
	var max_y: float = 0.0

	for child in map_layer.get_children():
		if not (child is Node2D):
			continue
		var ch: Node2D = child
		var pos: Vector2 = ch.position 
		if first:
			min_x = pos.x
			min_y = pos.y
			max_x = pos.x
			max_y = pos.y
			first = false
		else:
			if pos.x < min_x:
				min_x = pos.x
			if pos.y < min_y:
				min_y = pos.y
			if pos.x > max_x:
				max_x = pos.x
			if pos.y > max_y:
				max_y = pos.y

	if first:
		return Rect2(Vector2.ZERO, Vector2.ZERO)

	var size: Vector2 = Vector2(max_x - min_x, max_y - min_y)
	var padding: float = 48.0
	return Rect2(Vector2(min_x - padding, min_y - padding), size + Vector2(padding * 2.0, padding * 2.0))


# -------------------------
# Построение и анимация пути
# -------------------------
func _build_path_and_animate() -> void:
	# Проверки
	if path_drawer == null:
		return
	if level_icons.size() == 0:
		return

	var global_points: Array[Vector2] = []
	for icon in level_icons:
		if icon is Node2D:
			global_points.append((icon as Node2D).get_global_position())
		else:
			if icon.has_method("get_global_transform"):
				var tr = icon.get_global_transform()
				global_points.append(tr.origin)
			else:
				global_points.append(map_layer.to_global(icon.position))

	path_drawer.call("set_points", global_points)

	var last_open_level: int = 0
	for icon2 in level_icons:
		var lvl2: int = int(icon2.level_number)
		if level_saver.get_level_stars(lvl2) > 0:
			last_open_level = lvl2

	var target_index: int = 0
	var i: int = 0
	while i < level_icons.size():
		if int(level_icons[i].level_number) == last_open_level+1:
			target_index = i
			break
		i += 1

	var progress_val: float = 0.0
	if last_open_level > 0:
		var target_global: Vector2 = (level_icons[target_index] as Node2D).get_global_position()
		if path_drawer.has_method("get_progress_to_global_point"):
			progress_val = float(path_drawer.call("get_progress_to_global_point", target_global))
		else:
			if level_icons.size() > 1:
				progress_val = float(target_index) / float(level_icons.size() - 1)
			else:
				progress_val = 0.0

	if path_drawer.has_method("set_fill_amount"):
		path_drawer.call("set_fill_amount", 0.0)
	if path_drawer.has_method("animate_fill_to"):
		path_drawer.call("animate_fill_to", progress_val, time)
	else:
		if path_drawer.has_method("set_fill_amount"):
			path_drawer.call("set_fill_amount", progress_val)

	_animate_icons(level_icons)


func _animate_icons(entries: Array) -> void:
	var delay = 0.1
	for e in entries:
		if e.has_method("set_scale"):
			# если Node2D с scale
			e.scale = Vector2(0.6, 0.6)

		var tw = create_tween()
		tw.tween_interval(delay)
		if e is Node2D:
			tw.tween_property(e, "scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			if e.has_method("set"):
				tw.tween_property(e, "rect_scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.1


# -------------------------
# Обработка выбора уровня
# -------------------------
func _on_level_selected(level_num: int):
	popup.title = "Подтвердить"
	popup.dialog_text = "Начать уровень %d?" % level_num
	popup.popup_centered()

	if popup.is_connected("confirmed", Callable(self, "_start_level")):
		popup.disconnect("confirmed", Callable(self, "_start_level"))
	
	popup.connect("confirmed", Callable(self, "_start_level").bind(level_num))

func _on_back_button_pressed() -> void: 
	get_tree().change_scene_to_file("res://mainMenu.tscn") 

func _start_level(chosen_level: int): 
	var level_scene := preload("res://Node_2D.tscn").instantiate() 
	level_scene.level = chosen_level 
	get_tree().get_root().add_child(level_scene) 
	get_tree().current_scene.queue_free() 

func _scroll_to_bottom():
	await get_tree().process_frame
	var bar = scroll.get_v_scroll_bar()
	scroll.scroll_vertical = bar.max_value
