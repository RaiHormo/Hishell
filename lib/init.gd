extends Control

func _ready() -> void:
	System.init = self
	if not DirAccess.dir_exists_absolute(System.root):
		DirAccess.make_dir_absolute(System.root)
		for i in System.get_usernames():
			DirAccess.make_dir_absolute(System.root+"/"+i)
			var user_folder = DirAccess.open(System.root+"/"+i)
			user_folder.create_link(OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS), user_folder.get_current_dir()+"/Documents")
			user_folder.create_link(OS.get_system_dir(OS.SYSTEM_DIR_PICTURES), user_folder.get_current_dir()+"/Pictures")
			user_folder.create_link(OS.get_system_dir(OS.SYSTEM_DIR_MUSIC), user_folder.get_current_dir()+"/Music")
			user_folder.create_link(OS.get_system_dir(OS.SYSTEM_DIR_MOVIES), user_folder.get_current_dir()+"/Videos")
			user_folder.create_link(OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS), user_folder.get_current_dir()+"/Downloads")
	System.user = System.users[0]
	System.launch(System.root+"/"+System.user.get("name"), Vector2i.ZERO, get_tree().root, true)
