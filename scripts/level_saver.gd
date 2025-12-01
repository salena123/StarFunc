extends Node

const LEVELS_FILE = "user://levels.json"
const PROGRESS_FILE = "user://progress.json"

class LevelData:
	var level_number: int
	var level_type: int
	var correct_func: String
	var correct_func_b: String
	var options: Array
	var options_b: Array
	var ball_side: int
	var star_seed: int
	var double_intersection_x: float = NAN 	
	
	func to_dict() -> Dictionary:
		return {
			"level_number": level_number,
			"level_type": level_type,
			"correct_func": correct_func,
			"correct_func_b": correct_func_b,
			"options": options,
			"options_b": options_b,
			"ball_side": ball_side,
			"star_seed": star_seed,
			"double_intersection_x": (double_intersection_x if double_intersection_x == double_intersection_x else null)
		}
	
	static func from_dict(dict: Dictionary) -> LevelData:
		var level = LevelData.new()
		level.level_number = dict.get("level_number", 1)
		level.level_type = dict.get("level_type", 0)
		level.correct_func = dict.get("correct_func", "")
		level.correct_func_b = dict.get("correct_func_b", "")
		var opts = dict.get("options", [])
		var opts_b = dict.get("options_b", [])
		level.options = opts if opts is Array else []
		level.options_b = opts_b if opts_b is Array else []
		level.ball_side = dict.get("ball_side", 0)
		level.star_seed = dict.get("star_seed", 0)
		var double_val = dict.get("double_intersection_x", NAN)
		if double_val == null:
			double_val = NAN
		elif typeof(double_val) in [TYPE_INT, TYPE_FLOAT]:
			double_val = float(double_val)
		else:
			double_val = NAN
		level.double_intersection_x = double_val
		return level

static func save_level(level_data: LevelData) -> bool:
	var levels = load_all_levels()
	
	var found = false
	for i in range(levels.size()):
		if levels[i].level_number == level_data.level_number:
			levels[i] = level_data
			found = true
			break
	
	if not found:
		levels.append(level_data)
	
	levels.sort_custom(func(a, b): return a.level_number < b.level_number)
	
	var file = FileAccess.open(LEVELS_FILE, FileAccess.WRITE)
	if file == null:
		print("Ошибка: не удалось открыть файл для записи уровней")
		return false
	
	var json_data = []
	for level in levels:
		json_data.append(level.to_dict())
	
	var json_string = JSON.stringify(json_data)
	file.store_string(json_string)
	file.close()
	
	print("Уровень ", level_data.level_number, " сохранён")
	return true

static func load_all_levels() -> Array:
	var file = FileAccess.open(LEVELS_FILE, FileAccess.READ)
	if file == null:
		return []
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("Ошибка парсинга JSON: ", error)
		return []
	
	var json_data = json.data
	if not json_data is Array:
		return []
	
	var levels = []
	for dict in json_data:
		levels.append(LevelData.from_dict(dict))
	
	return levels

static func load_level(level_number: int) -> LevelData:
	var levels = load_all_levels()
	for level in levels:
		if level.level_number == level_number:
			return level
	return null

static func delete_level(level_number: int) -> bool:
	var levels = load_all_levels()
	var new_levels = []
	var found = false
	
	for level in levels:
		if level.level_number != level_number:
			new_levels.append(level)
		else:
			found = true
	
	if not found:
		return false
	
	var file = FileAccess.open(LEVELS_FILE, FileAccess.WRITE)
	if file == null:
		return false
	
	var json_data = []
	for level in new_levels:
		json_data.append(level.to_dict())
	
	var json_string = JSON.stringify(json_data)
	file.store_string(json_string)
	file.close()
	
	return true

static func save_progress(level_number: int, stars: int) -> bool:
	level_number = int(level_number)
	stars = int(stars)
	var progress = load_progress()
	
	if progress.has(level_number):
		if stars > progress[level_number]:
			progress[level_number] = stars
	else:
		progress[level_number] = stars
	
	var file = FileAccess.open(PROGRESS_FILE, FileAccess.WRITE)
	if file == null:
		print("Ошибка: не удалось открыть файл для записи прогресса")
		return false
	
	var json_string = JSON.stringify(progress)
	file.store_string(json_string)
	file.close()
	
	return true

static func load_progress() -> Dictionary:
	var file = FileAccess.open(PROGRESS_FILE, FileAccess.READ)
	if file == null:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return {}
	
	if not json.data is Dictionary:
		return {}
	
	var sanitized = {}
	for key in json.data.keys():
		var lvl_key = key
		if typeof(key) == TYPE_STRING:
			if key.is_valid_int():
				lvl_key = int(key)
			else:
				continue
		elif typeof(key) != TYPE_INT:
			continue
		
		var stars_val = json.data[key]
		if typeof(stars_val) != TYPE_INT:
			stars_val = int(stars_val)
		
		sanitized[lvl_key] = stars_val
	
	return sanitized

static func get_level_stars(level_number: int) -> int:
	var progress = load_progress()
	return progress.get(level_number, 0)

static func get_total_stars() -> int:
	var progress = load_progress()
	var total = 0
	for stars in progress.values():
		total += stars
	return total
