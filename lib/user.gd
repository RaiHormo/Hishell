extends Node

var users: Array[Dictionary] = [
	{
		"name": "Iris",
		"password": "",
	}
]
var current: Dictionary

func user_path(for_user: String = current.get("name")) -> String:
	var usr: Dictionary = get_user(for_user)
	if usr.is_empty(): return System.root
	else: return "%s/%s/"%[System.root, usr.get("name")]

func get_user(username: String) -> Dictionary:
	return users[users.find_custom(user_finder.bind(username))]

func user_finder(find: Dictionary, username: String) -> bool:
	return username == find.get("name")

func get_usernames() -> Array[String]:
	var arr: Array[String]
	for i in users:
		arr.append(i.get("name"))
	return arr

func create_user_folder(username: String) -> String:
	print("Creating user folder for ", username)
	return Filesystem.copy_folder(username, "res://filesystem/default-user", "user://filesystem")
