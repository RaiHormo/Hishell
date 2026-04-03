extends Node
class_name Meta

static func get_folder_meta(path: String, data: String, section:= "", default: Variant = false) -> Variant:
	var config = get_folder_config(path)
	if config == null: return default
	return config.get_value(section, data, default)

static func get_folder_config(path: String):
	if not Filesystem.is_file(path+"/.meta"): return null
	path = Filesystem.abs_path(path)
	var config = ConfigFile.new()
	config.load(path+"/.meta")
	return config

static func folder_title(path: String) -> String:
	var nam = get_folder_meta(path, "Title", "DISPLAY")
	if not nam:
		return path.split("/", false)[-1]
	else: return nam

static func set_folder_meta(path: String, data: String, section: String, value: Variant):
	path = Filesystem.abs_path(path)
	if not System.root in path: return
	var config = ConfigFile.new()
	config.load(path+"/.meta")
	config.set_value(section, data, value)
	config.save(path+"/.meta")

static func get_cutsom_icon(path: String) -> String:
	var dir = Filesystem.open_folder(path)
	if dir == null: return ""
	var icon_name = ".icon"
	for i in System.file_extensions["picture"]:
		if dir.file_exists(icon_name+"."+i):
			return path+"/"+icon_name+"."+i
	return ""
