extends Node

var root
var Side = preload("res://scripts/level_generator.gd").Side

var hidden_func: String = ""

func init(r):
	root = r

func generate_level():
	var candidate = random_function()
	while not root.utils.is_level_valid_for_edges(candidate, root.ball_side):
		candidate = random_function()
	hidden_func = candidate

	var expr = Expression.new()
	if expr.parse(hidden_func, ["x"]) == OK:
		root.utils.setup_level_positions(expr)

	return hidden_func

func random_function() -> String:
	var k = 0.0
	while abs(k) < 0.3:
		k = round(randf_range(-3, 3) * 10) / 10.0
	var b = round(randf_range(-5.0, 5.0) * 10) / 10.0
	return str(k) + "*x + " + str(b)
