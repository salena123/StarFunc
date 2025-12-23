class_name ChapterIcon
extends Node2D

@export var chapter_id: int = 1
@export var max_stars: int = 3
@export var level_numbers: Array[int] = []  # Номера уровней в этой главе

signal selected(chapter_id: int)

@onready var button := $ChapterIcon1
@onready var chapter_number_label := $ChapterIcon1/ChapterNumber
@onready var stars := $ChapterIcon1/StarBox.get_children()

var level_saver = preload("res://scripts/level_saver.gd")
var locked := false
var chapter_stars: int = 0  # Количество звезд главы (0-3)

func _ready():
	if button:
		if not button.pressed.is_connected(_on_pressed):
			button.pressed.connect(_on_pressed)
	await get_tree().process_frame
	_update_chapter_number()
	_update_stars_from_levels()

func _update_chapter_number():
	if not chapter_number_label:
		chapter_number_label = $ChapterIcon1/ChapterNumber
	if chapter_number_label:
		chapter_number_label.text = "[b]" + str(chapter_id)

func set_locked(value: bool):
	locked = value
	if button:
		button.disabled = value
		if value:
			button.modulate = Color(0.8, 0.8, 0.8, 0.9)
		else:
			button.modulate = Color(1, 1, 1, 1)
	if value:
		modulate = Color(0.7, 0.7, 0.7, 1.0)
	else:
		modulate = Color(1, 1, 1, 1)

func set_stars(count: int):
	count = clamp(count, 0, max_stars)
	for i in stars.size():
		stars[i].visible = i < count

func _update_stars_from_levels():
	var total_stars: int = 0
	var total_max_stars: int = 0
	
	if level_numbers.size() > 0:
		for level_num in level_numbers:
			var stars: int = int(level_saver.get_level_stars(level_num))
			total_stars += stars
			total_max_stars += 3
	
	var stars_to_show: int = 0
	if total_max_stars > 0:
		var percentage: float = float(total_stars) / float(total_max_stars)
		if percentage >= 1.0:
			stars_to_show = 3
		elif percentage >= 0.67:
			stars_to_show = 2
		elif percentage > 0.33:
			stars_to_show = 1
	
	set_stars(stars_to_show)
	chapter_stars = stars_to_show

func get_chapter_stars() -> int:
	return chapter_stars

func get_world_position() -> Vector2:
	return global_position

func _on_pressed():
	if locked or (button and button.disabled):
		return
	emit_signal("selected", chapter_id)
