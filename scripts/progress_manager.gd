extends Node

var level_saver = preload("res://scripts/level_saver.gd")
var root

func init(r):
	root = r

func on_level_complete(level_number: int, stars_collected: int):
	var current_stars = level_saver.get_level_stars(level_number)
	
	if stars_collected > current_stars:
		level_saver.save_progress(level_number, stars_collected)
		print("Уровень ", level_number, " пройден! Звёзд: ", stars_collected, " (было: ", current_stars, ")")
	else:
		print("Уровень ", level_number, " пройден. Звёзд: ", stars_collected, " (лучший результат: ", current_stars, ")")

func get_current_level_stars() -> int:
	return level_saver.get_level_stars(root.level)

func get_total_stars() -> int:
	return level_saver.get_total_stars()

