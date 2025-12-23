extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	var scene := preload("res://ui/LevelSelect.tscn").instantiate()
	scene.mode = LevelSelect.MapMode.CHAPTERS
	scene.layout_scene = preload("res://ui/maps/Chapters.tscn")

	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	#get_tree().change_scene_to_file("res://ui/LevelSelect.tscn") # Replace with function body.


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/settings.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/mainMenu.tscn")
