extends Control

const always_reinstall:= false

func _ready() -> void:
	System.init = self
	await System.wait(0.3)
	if always_reinstall:
		OS.move_to_trash(System.root)
	if not DirAccess.dir_exists_absolute(System.root):
		install()
	System.user = System.users[0]
	System.launch(System.root, Vector2i.ZERO, get_tree().root, true)
	queue_free()

func install():
	DirAccess.make_dir_absolute(System.root)
	for i in System.get_usernames():
		DirAccess.make_dir_absolute(System.root+"/"+i)
		DirAccess.make_dir_absolute(System.root+"/"+i+"/data")
		var user_folder = DirAccess.open(System.root+"/"+i)
		var data_folder = DirAccess.open(System.root+"/"+i+"/data")
		user_folder.copy("res://assets/cyan.png", user_folder.get_current_dir()+"/.wallpaper.png")
		user_folder.copy("res://assets/higameos-logo.png", System.root+"/.icon.png")
		if OS.get_name() == "Linux":
			data_folder.create_link(OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS), data_folder.get_current_dir()+"/Documents")
			data_folder.create_link(OS.get_system_dir(OS.SYSTEM_DIR_PICTURES), data_folder.get_current_dir()+"/Pictures")
			data_folder.create_link(OS.get_system_dir(OS.SYSTEM_DIR_MUSIC), data_folder.get_current_dir()+"/Music")
			data_folder.create_link(OS.get_system_dir(OS.SYSTEM_DIR_MOVIES), data_folder.get_current_dir()+"/Videos")
			data_folder.create_link(OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS), data_folder.get_current_dir()+"/Downloads")
