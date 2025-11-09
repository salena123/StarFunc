extends Node

var root

func init(r):
	root = r

func check_star_collection():
	for star in root.stars:
		if star.visible and root.ball.global_position.distance_to(star.global_position) < 25:
			star.visible = false
			root.score += 1
			root.ui.update_score_label()

func check_exit_reached():
	if root.ball.global_position.distance_to(root.exit.global_position) < 40:
		root.ui.show_level_complete()

func check_ball_fall_off_screen():
	var rect = root.get_viewport_rect()
	if root.ball.global_position.y > rect.size.y + 100 \
	or root.ball.global_position.x > rect.size.x + 50 \
	or root.ball.global_position.x < -50:
		root.ball.freeze = true
		root.ui.show_fail()
