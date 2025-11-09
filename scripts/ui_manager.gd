extends Node

var root

@onready var score_label
@onready var level_complete_popup
@onready var retry_button
@onready var next_button
@onready var level_label
@onready var fail_popup
@onready var fail_retry_button

func init(r):
	root = r
	score_label = root.get_node("UI/ScoreLabel")
	level_complete_popup = root.get_node("UI/LevelCompletePopup")
	retry_button = root.get_node("UI/LevelCompletePopup/RetryButton")
	next_button = root.get_node("UI/LevelCompletePopup/NextButton")
	level_label = root.get_node("UI/LevelCompletePopup/Label")
	fail_popup = root.get_node("UI/FailPopup")
	fail_retry_button = root.get_node("UI/FailPopup/RetryButton")

	level_complete_popup.hide()
	fail_popup.hide()

	retry_button.pressed.connect(func():
		level_complete_popup.hide()
		root.level_gen.reset_current_level()
	)
	next_button.pressed.connect(func():
		level_complete_popup.hide()
		root.level += 1
		root.level_gen.generate_new_level()
	)
	fail_retry_button.pressed.connect(func():
		fail_popup.hide()
		root.level_gen.reset_current_level()
	)

func update_score_label():
	if score_label:
		score_label.text = "Звёзды: " + str(root.score)

func show_level_complete():
	root.ball.freeze = true
	level_label.text = "Уровень " + str(root.level) + " пройден!"
	level_complete_popup.show()

func show_fail():
	root.ball.freeze = true
	fail_popup.show()
