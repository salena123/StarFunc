extends Node

var root

func init(r):
	root = r


func generate_function() -> String:
	if root == null or root.utils == null:
		return "0.5*x"
	var attempts = 0
	var max_attempts = 2000
	var candidate = _random_function()
	while attempts < max_attempts and not root.utils.is_level_valid_for_edges(candidate, root.ball_side):
		candidate = _random_function()
		attempts += 1
	return candidate


func setup_ui_with_function(func_str: String):
	if root == null:
		return
	_prepare_ui()
	_draw_function(func_str)


func _prepare_ui():
	if root == null:
		return
	for btn in root.option_buttons:
		btn.hide()
	if root.forward_button:
		root.forward_button.hide()
	if root.build_button:
		root.build_button.disabled = false
	if root.k_slider:
		root.k_slider.visible = true
		root.k_slider.value = 0.0
	if root.b_slider:
		root.b_slider.visible = true
		root.b_slider.value = 0.0
	if root.k_slider_label:
		root.k_slider_label.visible = true
		root.k_slider_label.text = "0.0"
	if root.b_slider_label:
		root.b_slider_label.visible = true
		root.b_slider_label.text = "0.0"
	if root.has_node("UI/Slider"):
		root.get_node("UI/Slider").visible = true
	if root.k_input:
		root.k_input.visible = false
	if root.b_input:
		root.b_input.visible = false
	if root.b_value_label:
		root.b_value_label.visible = true
	if root.has_method("refresh_input_slider_value_labels"):
		root.refresh_input_slider_value_labels()
	if root.x_label:
		root.x_label.visible = false
	if root.y_label:
		root.y_label.visible = false
	if root.input_panel:
		root.input_panel.visible = true


func _draw_function(func_str: String):
	if root == null or root.utils == null:
		return
	var expr = Expression.new()
	if expr.parse(func_str, ["x"]) == OK:
		root.utils.setup_level_positions(expr)
	else:
		push_warning("InputSliderLevel: failed to parse function %s" % func_str)


func _random_function() -> String:
	var k = 0.0
	while abs(k) < 0.3:
		k = round(randf_range(-3.0, 3.0) * 10) / 10.0
	var b = round(randf_range(-5.0, 5.0) * 10) / 10.0
	return str(k) + "*x + " + str(b)
