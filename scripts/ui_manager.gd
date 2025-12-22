extends Node

var root

@onready var score_label
@onready var level_complete_popup
@onready var next_button
@onready var level_label
@onready var fail_popup
@onready var fail_retry_button
@onready var restart
@onready var fail_label_level
@onready var popup_star1
@onready var popup_star2
@onready var popup_star3
@onready var popup_star4
@onready var popup_star5
@onready var popup_star6
@onready var help_layer
@onready var help_dimmer
@onready var help_button

func init(r):
	root = r
	score_label = root.get_node("UI/ScoreLabel")
	level_complete_popup = root.get_node("UI/LevelCompletePopup")
	next_button = root.get_node("UI/LevelCompletePopup/Card/VBoxContainer/NextButton")
	level_label = root.get_node("UI/LevelCompletePopup/Card/VBoxContainer/BannerControl/Medial/LevelLabel")
	fail_popup = root.get_node("UI/FailPopup")
	fail_retry_button = root.get_node("UI/FailPopup/Card/VBoxContainer/RetryButton")
	restart = root.get_node("UI/Restart")
	fail_label_level = root.get_node("UI/FailPopup/Card/VBoxContainer/BannerControl/Medial/LevelLabel")
	popup_star1 = root.get_node_or_null("UI/LevelCompletePopup/Card/VBoxContainer/BannerControl/StarsContainer/Star1")
	popup_star2 = root.get_node_or_null("UI/LevelCompletePopup/Card/VBoxContainer/BannerControl/StarsContainer/Star2")
	popup_star3 = root.get_node_or_null("UI/LevelCompletePopup/Card/VBoxContainer/BannerControl/StarsContainer/Star3")
	popup_star4 = root.get_node_or_null("UI/LevelCompletePopup/Card/VBoxContainer/BannerControl/StarsContainer/Star4")
	popup_star5 = root.get_node_or_null("UI/LevelCompletePopup/Card/VBoxContainer/BannerControl/StarsContainer/Star5")
	popup_star6 = root.get_node_or_null("UI/LevelCompletePopup/Card/VBoxContainer/BannerControl/StarsContainer/Star6")
	help_layer = root.get_node_or_null("UI/Help")
	help_dimmer = root.get_node_or_null("UI/Help/Dimmer")
	help_button = root.get_node_or_null("UI/BottomLayout/Items/Items/HBoxContainer/Help")

	level_complete_popup.hide()
	fail_popup.hide()
	if help_layer:
		help_layer.hide()

	next_button.pressed.connect(func():
		level_complete_popup.hide()
		root.level += 1
		root.level_gen.generate_new_level()
	)
	fail_retry_button.pressed.connect(func():
		fail_popup.hide()
		root.level_gen.reset_current_level()
	)
	
	restart.pressed.connect(func():
		root.level_gen.reset_current_level()
	)

	if help_button and help_layer:
		help_button.pressed.connect(func():
			help_layer.show()
			if help_layer.has_method("refresh_from_consts"):
				help_layer.refresh_from_consts()
		)
	
	if help_dimmer and help_layer:
		help_dimmer.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				help_layer.hide()
		)

func update_score_label():
	if score_label:
		score_label.text = "Звёзды: " + str(root.score)

func update_stars_count_label():
	if score_label:
		score_label.text = "Звёзды: " + str(root.score)

func show_level_complete():
	root.ball.freeze = true
	root.restart.disabled = true
	level_label.text = str(root.level)
	_update_level_complete_stars()
	level_complete_popup.show()
	if root.timer:
		root.timer.paused = true


func _update_level_complete_stars():
	var stars = [popup_star1, popup_star2, popup_star3, popup_star4, popup_star5, popup_star6]
	for s in stars:
		if s:
			s.visible = false
	var collected: int = root.score
	if collected <= 0:
		return
	elif collected == 1:
		if popup_star1:
			popup_star1.visible = true
		if popup_star5:
			popup_star5.visible = true
		if popup_star6:
			popup_star6.visible = true
	elif collected == 2:
		if popup_star1:
			popup_star1.visible = true
		if popup_star2:
			popup_star2.visible = true
		if popup_star6:
			popup_star6.visible = true
	else:
		if popup_star1:
			popup_star1.visible = true
		if popup_star2:
			popup_star2.visible = true
		if popup_star3:
			popup_star3.visible = true

func show_fail():
	root.restart.disabled = true
	root.ball.freeze = true
	fail_label_level.text = str(root.level)
	fail_popup.show()
	if root.timer:
		root.timer.paused = true
