extends Node
class_name CustomLevelManager

const SAVE_DIR := "user://custom_levels/"


static func ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


static func sanitize_filename(name_str: String) -> String:
	var clean := name_str.strip_edges().to_lower()
	var regex := RegEx.new()
	regex.compile("[^a-z0-9_\\-]")
	clean = regex.sub(clean, "_", true)
	if clean.is_empty():
		clean = "nivel_custom"
	return clean


static func save_level(filename: String, level_data: Dictionary) -> bool:
	ensure_save_dir()
	var clean_name := sanitize_filename(filename)
	var file_path := SAVE_DIR + clean_name + ".json"

	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("CustomLevelManager: Could not open file for writing: " + file_path + " Error: " + str(FileAccess.get_open_error()))
		return false

	var json_str := JSON.stringify(level_data, "\t")
	file.store_string(json_str)
	file.close()
	print("CustomLevelManager: Saved level to ", file_path)
	return true


static func load_level(filename: String) -> Dictionary:
	ensure_save_dir()
	var clean_name := sanitize_filename(filename)
	var file_path := SAVE_DIR + clean_name + ".json"

	if not FileAccess.file_exists(file_path):
		# Try exact path if provided with extension or relative
		if FileAccess.file_exists(filename):
			file_path = filename
		elif FileAccess.file_exists(SAVE_DIR + filename):
			file_path = SAVE_DIR + filename
		else:
			push_error("CustomLevelManager: Level file does not exist: " + file_path)
			return {}

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("CustomLevelManager: Could not open file for reading: " + file_path)
		return {}

	var json_str := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_str)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("CustomLevelManager: Failed to parse level JSON in file: " + file_path)
		return {}

	return parsed as Dictionary


static func list_custom_levels() -> Array[String]:
	ensure_save_dir()
	var result: Array[String] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir != null:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				result.append(file_name.get_basename())
			file_name = dir.get_next()
		dir.list_dir_end()
	result.sort()
	return result


static func delete_level(filename: String) -> bool:
	ensure_save_dir()
	var clean_name := sanitize_filename(filename)
	var file_path := SAVE_DIR + clean_name + ".json"
	if FileAccess.file_exists(file_path):
		var err := DirAccess.remove_absolute(file_path)
		return err == OK
	return false


static func vector3_to_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


static func array_to_vector3(arr: Array, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	if arr != null and arr.size() >= 3:
		return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
	return fallback
