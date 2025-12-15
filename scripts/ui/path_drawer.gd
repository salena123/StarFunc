extends Node2D
class_name PathDrawer

@export var line_width: float = 22.0
@export var color_full: Color = Color(1.0, 0.78, 0.15)
@export var color_empty: Color = Color(0.45, 0.45, 0.45, 0.35)
@export var invert_direction: bool = false
@export var smoothness_per_segment: int = 40

var _raw_points: Array[Vector2] = []
var _curve: Array[Vector2] = []

var _seg_lengths: Array[float] = []
var _total_length: float = 0.0

@export var _fill_amount: float = 0.0:
	set(value):
		_fill_amount = clamp(value, 0.0, 1.0)
		queue_redraw()
	get:
		return _fill_amount


# =======================================================================
# ПРИЁМ ТОЧЕК
# =======================================================================

func set_points(global_points: Array[Vector2]) -> void:
	_raw_points.clear()

	for p in global_points:
		_raw_points.append(to_local(p))

	_curve = _smooth_curve(_raw_points, smoothness_per_segment)

	_compute_lengths()

	queue_redraw()


# =======================================================================
# FILL_AMOUNT
# =======================================================================

func set_fill_amount(v: float) -> void:
	_fill_amount = clamp(v, 0.0, 1.0)
	queue_redraw()

func get_fill_amount() -> float:
	return _fill_amount


func animate_fill_to(target: float, duration: float = 1.0) -> void:
	target = clamp(target, 0.0, 1.0)
	var tw = create_tween()
	tw.tween_property(self, "_fill_amount", target, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


# =======================================================================
# РИСОВАНИЕ
# =======================================================================

func _draw() -> void:
	if _curve.size() < 2:
		return

	var pts := _curve.duplicate()
	if invert_direction:
		pts.reverse()

	# фон
	draw_polyline(pts, color_empty, line_width, true)

	if _fill_amount <= 0.001:
		return

	_draw_fill(pts)


func _draw_fill(pts: Array[Vector2]) -> void:
	var target_length := _total_length * _fill_amount
	var passed := 0.0

	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		var seg_len := _seg_lengths[i]

		if passed + seg_len < target_length:
			draw_polyline([a, b], color_full, line_width, true)
			passed += seg_len
		else:
			var remain := target_length - passed
			var t: float = remain / seg_len
			var mid := a.lerp(b, t)

			draw_polyline([a, mid], color_full, line_width, true)
			return


# =======================================================================
# РАСЧЁТ ДЛИНЫ
# =======================================================================

func _compute_lengths() -> void:
	_seg_lengths.clear()
	_total_length = 0.0

	if _curve.size() < 2:
		return

	for i in range(_curve.size() - 1):
		var l = _curve[i].distance_to(_curve[i + 1])
		_seg_lengths.append(l)
		_total_length += l


# =======================================================================
# СГЛАЖИВАНИЕ CATMULL–ROM
# =======================================================================

func _smooth_curve(points: Array[Vector2], smoothness: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if points.size() < 2:
		return result

	for i in range(points.size() - 1):
		var p0 = points[max(i - 1, 0)]
		var p1 = points[i]
		var p2 = points[i + 1]
		var p3 = points[min(i + 2, points.size() - 1)]

		for t_i in range(smoothness):
			var t = float(t_i) / float(smoothness)
			var tt = t * t
			var ttt = tt * t

			var q1 = -ttt + 2.0 * tt - t
			var q2 = 3.0 * ttt - 5.0 * tt + 2.0
			var q3 = -3.0 * ttt + 4.0 * tt + t
			var q4 = ttt - tt

			var x = 0.5 * (p0.x * q1 + p1.x * q2 + p2.x * q3 + p3.x * q4)
			var y = 0.5 * (p0.y * q1 + p1.y * q2 + p2.y * q3 + p3.y * q4)

			result.append(Vector2(x, y))

	result.append(points[points.size() - 1])
	return result

func get_curve_points() -> Array:
	return _curve.duplicate()

func get_segment_lengths() -> Array:
	return _seg_lengths.duplicate()

func get_total_length() -> float:
	return _total_length

func get_progress_to_global_point(global_point: Vector2) -> float:
	if _curve.size() < 2 or _total_length <= 0.0:
		return 0.0

	var local_pt: Vector2 = to_local(global_point)

	var nearest_idx: int = 0
	var nearest_dist: float = INF
	for i in range(_curve.size()):
		var d: float = _curve[i].distance_to(local_pt)
		if d < nearest_dist:
			nearest_dist = d
			nearest_idx = i

	var acc: float = 0.0
	for j in range(nearest_idx):
		if j < _seg_lengths.size():
			acc += float(_seg_lengths[j])
		else:
			acc += _curve[j].distance_to(_curve[j + 1])

	if nearest_idx < _curve.size() - 1:
		var seg_a: Vector2 = _curve[nearest_idx]
		var seg_b: Vector2 = _curve[nearest_idx + 1]
		var seg_len: float = seg_a.distance_to(seg_b)
		if seg_len > 1e-6:
			var proj_t: float = ((local_pt - seg_a).dot(seg_b - seg_a)) / seg_len / seg_len
			proj_t = clamp(proj_t, 0.0, 1.0)
			acc += proj_t * seg_len

	return clamp(acc / _total_length, 0.0, 1.0)
