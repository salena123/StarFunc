extends Node2D

signal level_selected(level_number)

@export var level_number: int = 1
@export var max_stars: int = 3

@export var star_filled: Texture2D
@export var star_empty: Texture2D
@export var lock_texture: Texture2D
@export var tex_star1_2: Texture2D
@export var tex_star3: Texture2D

@onready var button: TextureButton = $LevelIcon1
@onready var label: RichTextLabel = $LevelIcon1/LevelNumber
@onready var star_box: HBoxContainer = $LevelIcon1/StarBox
@onready var lock_icon: TextureRect = $LevelIcon1/Lock

var stars_count := 0
var locked := false


func _ready():
	label.text = str(level_number)
	button.pressed.connect(_on_pressed)
	_update_visuals()


func _on_pressed():
	if locked:
		return
	emit_signal("level_selected", level_number)


func set_stars(n: int):
	stars_count = clamp(n, 0, max_stars)
	_update_stars()
	_update_visuals()


func set_locked(v: bool):
	locked = v
	_update_visuals()


func _update_stars():
	var children = star_box.get_children()
	for i in range(children.size()):
		var node = children[i]
		if node is TextureRect:
			node.texture = star_filled if i < stars_count else star_empty


func _update_visuals():
	button.disabled = locked
	#lock_icon.visible = locked
	match stars_count:
		1, 2:
			if tex_star1_2:
				button.texture_normal = tex_star1_2
		3:
			if tex_star3:
				button.texture_normal = tex_star3
	button.modulate = Color(0.6, 0.6, 0.6) if locked else Color(1, 1, 1)
