extends Control

const Consts = preload("res://scripts/consts.gd")

@export var pages: Array[String] = []

var _current_page: int = 0

@onready var _label: Label = get_node("Card/VBoxContainer/HBoxContainer/RevardTitle")
@onready var _next_button: Button = get_node("Card/VBoxContainer/HBoxContainer/Control/Button")
@onready var _prev_button: Button = get_node("Card/VBoxContainer/HBoxContainer/Control3/Button2")

func _ready():
	_next_button.pressed.connect(_on_next_pressed)
	_prev_button.pressed.connect(_on_prev_pressed)
	_update_page_label()


func refresh_from_consts():
	var root = get_tree().get_current_scene()
	print("[HelpPager] refresh_from_consts called, root=", root)
	if root == null or root.level_gen == null or not root.level_gen.has_method("get_level_type"):
		print("[HelpPager] level_gen ещё не инициализирован")
		return
	var lvl_type = root.level_gen.get_level_type(root.level)
	var key = root.level_gen.level_type_to_name(int(lvl_type))
	print("[HelpPager] lvl_type=", lvl_type, " key=", key)
	if Consts.HelpText.has(key):
		var full_text = str(Consts.HelpText[key])
		print("[HelpPager] loaded text from Consts.HelpText[", key, "]: ", full_text)
		pages = _auto_split_text(full_text)
		_current_page = 0
		_update_page_label()
	else:
		print("[HelpPager] no HelpText for key=", key)

func set_text(text: String):
	pages = []
	for part in text.split("---"):
		var trimmed = part.strip_edges()
		if trimmed != "":
			pages.append(trimmed)
	_current_page = 0
	_update_page_label()

func _on_next_pressed():
	if pages.size() == 0:
		return
	_current_page = (_current_page + 1) % pages.size()
	_update_page_label()

func _on_prev_pressed():
	if pages.size() == 0:
		return
	_current_page = (_current_page - 1 + pages.size()) % pages.size()
	_update_page_label()

func _update_page_label():
	if _label == null:
		return
	if pages.size() == 0:
		_label.text = ""
		return
	_label.text = pages[_current_page]


func _auto_split_text(text: String) -> Array[String]:
	var max_chars_per_page := 80
	var result: Array[String] = []
	var current := ""
	for word in text.split(" "):
		var candidate := (current + " " + word).strip_edges()
		if candidate.length() > max_chars_per_page and current != "":
			result.append(current)
			current = word
		else:
			current = candidate
	if current != "":
		result.append(current)
	return result
