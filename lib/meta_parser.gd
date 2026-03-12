extends Node
class_name Meta

static func get_folder_meta(path: String, data: String, section:= "", default: Variant = false) -> Variant:
	path = System.abs_path(path)
	if not FileAccess.file_exists(path+"/.meta"): return default
	var config = ConfigFile.new()
	config.load(path+"/.meta")
	return config.get_value(section, data, default)

static func folder_title(path: String) -> String:
	var nam = get_folder_meta(path, "Title", "DISPLAY")
	if not nam:
		return path.split("/")[-1]
	else: return nam

static func set_folder_meta(path: String, data: String, section: String, value: Variant):
	path = System.abs_path(path)
	if not System.root in path: return
	var config = ConfigFile.new()
	config.load(path+"/.meta")
	config.set_value(section, data, value)
	config.save(path+"/.meta")
