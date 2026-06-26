class_name FileUtils

const JSON_EXTENSION: String = ".json"

#############################################
### SEARCH
#############################################
static func get_files_in_dir_with_extension(dir_path: String, extension: String = "") -> Array[String]:
	var file_names: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name:
			if not dir.current_is_dir() and (extension.is_empty() or file_name.ends_with(extension)):
				file_names.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return file_names


#############################################
### LOAD
#############################################
static func load_json_as_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data:
		return {}
	return data


static func load_json(path: String, type: Script = null) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data:
		return null
	if type == null:
		return data
	return type.new().from_dict(data)


static func load_tres(path: String, type: Script = null) -> Variant:
	var resource: Variant = ResourceLoader.load(path)
	if resource == null:
		return null
	if type != null and resource.get_script() != type:
		push_error("Failed to load TRES as expected type: %s" % path)
		return null
	return resource


#############################################
### SAVE
#############################################
static func save_json(path: String, json: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(json, "\t"))
		file.close()
	else:
		push_error("Failed to save JSON.")


static func save_tres(path: String, tres: Resource) -> void:
	var err = ResourceSaver.save(tres, path)
	if err != OK:
		push_error("Failed to save TRES: %s" % err)
