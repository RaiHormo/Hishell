extends Node
class_name ConfigManager

static var theme: Theme = load("res://assets/themes/Default.tres")
static var config_path := "~/config/"

static func get_config(path: String, data: String, section: String, default: Variant = null) -> Variant:
	var real_path := Filesystem.abs_path(config_path+path)
	var config = ConfigFile.new()
	config.load(real_path)
	return config.get_value(section, data, default)

static func set_config(path: String, data: String, section: String, set_to: Variant = null):
	var real_path := Filesystem.abs_path(config_path+path)
	var config = ConfigFile.new()
	if FileAccess.file_exists(real_path):
		config.load(real_path)
	config.set_value(section, data, set_to)
	config.save(real_path)

static func get_config_file(path: String) -> ConfigFile:
	var real_path := Filesystem.abs_path(config_path+path)
	if FileAccess.file_exists(real_path):
		var config = ConfigFile.new()
		config.load(real_path)
		return config
	else:
		System.dialog("Failed to get config: %s"%[path], "Error")
		return null

static func merge_config(source: ConfigFile, destination: ConfigFile) -> ConfigFile:
	for section in source.get_sections():
		for key in source.get_section_keys(section):
			var value = source.get_value(section, key)
			destination.set_value(section, key, value)
	return destination
