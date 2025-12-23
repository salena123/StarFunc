extends Control

class_name LevelSelect

@export var time: float = 1.5

enum MapMode {
	CHAPTERS,
	LEVELS
}

@export var mode: MapMode = MapMode.CHAPTERS
@export var layout_scene: PackedScene
@export var chapter_id: int = 1 # актуально только для LEVELS

@onready var scroll: ScrollContainer = $MapScroll
@onready var map_container: Control = $MapScroll/Control
@onready var map_layer: Node2D = $MapScroll/Control/MapContainer
@onready var path_drawer: Node2D = $MapScroll/Control/MapContainer/PathDrawer
@onready var popup: ConfirmationDialog = $PopupDialog

var level_icons: Array = []
var level_saver = preload("res://scripts/level_saver.gd")
var _pending_level: int = -1

func _ready() -> void:
	popup.confirmed.connect(_on_popup_confirmed)
	popup.canceled.connect(_on_popup_canceled)
	_load_layout()
	await get_tree().process_frame
	_collect_icons()
	_apply_saved_state()
	_scale_map_to_screen()
	await get_tree().process_frame
	_connect_signals()
	_build_path_and_animate()
	await get_tree().process_frame
	_scroll_to_bottom()

func _load_layout():
	var layout = layout_scene.instantiate()

	var bg = layout.get_node("Background")
	var icons = layout.get_node("IconsLayer")
	
	var icon_children = []
	for child in icons.get_children():
		icon_children.append(child)
	
	for child in icon_children:
		icons.remove_child(child)
	
	layout.remove_child(bg)
	layout.remove_child(icons)

	$MapScroll/Control/MapContainer/BackgroundLayer.add_child(bg)
	
	var target_icons_layer = $MapScroll/Control/MapContainer/IconsLayer
	
	for child in icon_children:
		target_icons_layer.add_child(child)
	
	icons.queue_free()
	layout.queue_free()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
func _on_icon_selected(id: int):
	if mode == MapMode.CHAPTERS:
		_open_chapter(id)
		return

	_pending_level = id
	popup.title = "Подтвердить"
	popup.dialog_text = "Начать уровень %d?" % id
	popup.popup_centered()

func _open_chapter(chapter_id: int):
	var scene:PackedScene = load("res://ui/LevelSelect.tscn")
	var map := scene.instantiate()

	map.mode = MapMode.LEVELS
	map.chapter_id = chapter_id
	map.layout_scene = _get_chapter_layout(chapter_id)

	var old_scene = get_tree().current_scene
	
	get_tree().root.add_child(map)
	get_tree().current_scene = map
	
	if old_scene:
		old_scene.queue_free()


func _get_chapter_layout(chapter_id: int) -> PackedScene:
	match chapter_id:
		1:
			return preload("res://ui/maps/Chapter1.tscn")
		2:
			return preload("res://ui/maps/Chapter2.tscn")
		3:
			return preload("res://ui/maps/Chapter3.tscn")
		_:
			return preload("res://ui/maps/Chapter1.tscn")

func _collect_icons() -> void:
	level_icons.clear()
	var icons_layer = map_layer.get_node_or_null("IconsLayer")
	if icons_layer:
		if icons_layer.get_child_count() == 0:
			await get_tree().process_frame
		
		for child in icons_layer.get_children():
			if child is Node and child.has_method("set_stars") and child.has_method("set_locked"):
				level_icons.append(child)
	
	if mode == MapMode.LEVELS:
		level_icons.sort_custom(Callable(self, "_cmp_icons"))
		level_icons.reverse()


func _cmp_icons(a: Object, b: Object) -> int:
	var al: int = 0
	var bl: int = 0
	
	if "level_number" in a:
		al = int(a.level_number)
	if "level_number" in b:
		bl = int(b.level_number)
	
	if al == bl:
		return 0
	elif al < bl:
		return -1
	else:
		return 1


func _apply_saved_state() -> void:
	if mode == MapMode.CHAPTERS:
		for icon in level_icons:
			if icon is ChapterIcon:
				var chapter: ChapterIcon = icon
				chapter._update_stars_from_levels()
		
		for icon in level_icons:
			if icon is ChapterIcon:
				var chapter: ChapterIcon = icon
				if chapter.chapter_id == 1:
					chapter.set_locked(false)
				else:
					var prev_chapter_found: bool = false
					for prev_icon in level_icons:
						if prev_icon is ChapterIcon and prev_icon.chapter_id == chapter.chapter_id - 1:
							var prev_chapter_stars = prev_icon.get_chapter_stars()
							chapter.set_locked(prev_chapter_stars == 0)
							prev_chapter_found = true
							break
					if not prev_chapter_found:
						chapter.set_locked(false)
		return
	
	var first_level_in_chapter: int = -1
	
	for icon in level_icons:
		if "level_number" in icon:
			var lvl: int = int(icon.level_number)
			if first_level_in_chapter < 0 or lvl < first_level_in_chapter:
				first_level_in_chapter = lvl
	
	for icon in level_icons:
		if not ("level_number" in icon):
			continue
		var lvl: int = int(icon.level_number)
		var stars: int = int(level_saver.get_level_stars(lvl))
		icon.set_stars(stars)
		
		if lvl == first_level_in_chapter:
			icon.set_locked(false)
		else:
			var prev_stars: int = int(level_saver.get_level_stars(lvl - 1))
			icon.set_locked(prev_stars <= 0)


func _connect_signals() -> void:
	for icon in level_icons:
		if icon is ChapterIcon:
			if icon.is_connected("selected", _on_icon_selected):
				icon.disconnect("selected", _on_icon_selected)
			icon.connect("selected", _on_icon_selected)
		else:
			if icon.is_connected("level_selected", _on_icon_selected):
				icon.disconnect("level_selected", _on_icon_selected)
			icon.connect("level_selected", _on_icon_selected)


# -------------------------
# Масштабирование карты
# -------------------------
func _scale_map_to_screen() -> void:
	var design_width: float = 537.0
	var screen_width: float = float(get_viewport().size.x)
	var scale_factor: float = screen_width / design_width
	map_layer.scale = Vector2(scale_factor, scale_factor)
	
	await get_tree().process_frame
	
	var bounds: Rect2 = _compute_map_layer_bounds()
	if bounds.size == Vector2.ZERO:
		bounds.size = Vector2(566.3989, 2102.0)

	var content_size: Vector2 = bounds.size * scale_factor
	# Устанавливаем минимальный размер контейнера для ScrollContainer
	# Это автоматически обновит скролл-бар после следующего кадра
	map_container.custom_minimum_size = content_size

func _compute_map_layer_bounds() -> Rect2:
	var bg = $MapScroll/Control/MapContainer/BackgroundLayer.get_node_or_null("Background")
	var bg_size = Vector2.ZERO
	var bg_pos = Vector2.ZERO
	
	if bg:
		if bg is Control:
			bg_pos = bg.position
			bg_size = bg.size
			if bg_size == Vector2.ZERO or bg_size.x <= 0 or bg_size.y <= 0:
				var offset_right = bg.get("offset_right") if "offset_right" in bg else 566.3989
				var offset_bottom = bg.get("offset_bottom") if "offset_bottom" in bg else 2102.0
				bg_size = Vector2(offset_right, offset_bottom)
		elif bg is Node2D:
			bg_pos = bg.position
			var tex_rect = bg.get_node_or_null("TextureRect")
			if tex_rect and tex_rect is Control:
				bg_size = tex_rect.size
				if bg_size == Vector2.ZERO or bg_size.x <= 0 or bg_size.y <= 0:
					var offset_right = tex_rect.get("offset_right") if "offset_right" in tex_rect else 566.3989
					var offset_bottom = tex_rect.get("offset_bottom") if "offset_bottom" in tex_rect else 2102.0
					bg_size = Vector2(offset_right, offset_bottom)
			else:
				for child in bg.get_children():
					if child is Control:
						bg_size = child.size
						if bg_size == Vector2.ZERO or bg_size.x <= 0 or bg_size.y <= 0:
							var offset_right = child.get("offset_right") if "offset_right" in child else 566.3989
							var offset_bottom = child.get("offset_bottom") if "offset_bottom" in child else 2102.0
							bg_size = Vector2(offset_right, offset_bottom)
						break
	
	if bg_size == Vector2.ZERO:
		bg_size = Vector2(566.3989, 2102.0)
	
	var min_x = bg_pos.x
	var min_y = bg_pos.y
	var max_x = bg_pos.x + bg_size.x
	var max_y = bg_pos.y + bg_size.y
	
	var icons_layer = map_layer.get_node_or_null("IconsLayer")
	if icons_layer:
		var icon_radius = 42.0
		
		for child in icons_layer.get_children():
			if child is Node2D:
				var icon_pos = child.position
				var icon_min_x = icon_pos.x - icon_radius
				var icon_min_y = icon_pos.y - icon_radius
				var icon_max_x = icon_pos.x + icon_radius
				var icon_max_y = icon_pos.y + icon_radius
				
				if icon_min_x < min_x:
					min_x = icon_min_x
				if icon_min_y < min_y:
					min_y = icon_min_y
				if icon_max_x > max_x:
					max_x = icon_max_x
				if icon_max_y > max_y:
					max_y = icon_max_y
	
	var size = Vector2(max_x - min_x, max_y - min_y)
	var padding: float = 48.0
	return Rect2(Vector2(min_x - padding, min_y - padding), size + Vector2(padding * 2.0, padding * 2.0))


# -------------------------
# Построение и анимация пути
# -------------------------
func _build_path_and_animate() -> void:
	if path_drawer == null:
		_animate_icons(level_icons)
		return
	if level_icons.size() == 0:
		return

	if mode == MapMode.CHAPTERS:
		_animate_icons(level_icons)
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
		if not ("level_number" in icon2):
			continue
		var lvl2: int = int(icon2.level_number)
		if level_saver.get_level_stars(lvl2) > 0:
			last_open_level = lvl2

	var target_index: int = 0
	var i: int = 0
	while i < level_icons.size():
		if "level_number" in level_icons[i]:
			if last_open_level > 0:
				if int(level_icons[i].level_number) == last_open_level + 1:
					target_index = i
					break
			else:
				if int(level_icons[i].level_number) == 1:
					target_index = i
					break
		i += 1

	var progress_val: float = 0.0
	if target_index < level_icons.size():
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

func _on_popup_confirmed():
	if _pending_level < 0:
		return

	_start_level(_pending_level)
	_pending_level = -1
	
func _on_popup_canceled():
	_pending_level = -1

func _on_back_button_pressed() -> void:
	if mode == MapMode.LEVELS:
		_open_chapters()
	else:
		get_tree().change_scene_to_file("res://ui/mainMenu.tscn")

func _open_chapters():
	var scene:PackedScene = load("res://ui/LevelSelect.tscn")
	var map := scene.instantiate()

	map.mode = MapMode.CHAPTERS
	map.layout_scene = preload("res://ui/maps/Chapters.tscn")

	var old_scene = get_tree().current_scene
	
	get_tree().root.add_child(map)
	get_tree().current_scene = map
	
	if old_scene:
		old_scene.queue_free() 

func _start_level(chosen_level: int): 
	var level_scene := preload("res://Node_2D.tscn").instantiate() 
	level_scene.level = chosen_level 
	get_tree().get_root().add_child(level_scene) 
	get_tree().current_scene.queue_free() 

func _scroll_to_bottom():
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	var bar = scroll.get_v_scroll_bar()
	if bar and bar.max_value > 0:
		scroll.scroll_vertical = bar.max_value
