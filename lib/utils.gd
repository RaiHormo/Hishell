extends Node
class_name Utils

static func format_bytes(bytes: float) -> String:
	var units = ["bytes", "KB", "MB", "GB", "TB"]
	var unit_index = 0
	
	while bytes >= 1000 and unit_index < units.size() - 1:
		bytes /= 1000.0
		unit_index += 1
		
	return str(int(snapped(bytes, 0.01))) + " " + units[unit_index]

static func regex(string: String, pattern: String) -> RegExMatch:
	var ex = RegEx.create_from_string(pattern)
	return ex.search(string)
