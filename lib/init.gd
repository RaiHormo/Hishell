extends Control

const always_reinstall:= true

func _ready() -> void:
	System.init = self
	await System.wait(0.3)
	if always_reinstall and DirAccess.dir_exists_absolute("user://filesystem"):
		System.delete_folder(System.root)
	if not DirAccess.dir_exists_absolute(System.root):
		await install()
	System.user = System.users[0]
	System.launch(System.root, Vector2i.ZERO, get_tree().root, true)
	queue_free()

func install():
	print("Starting installation")
	System.copy_folder("filesystem", "res://filesystem", "user://")
	System.root = System.abs_path("user://filesystem")
	for i in System.get_usernames():
		var _user_folder = DirAccess.open(System.create_user_folder(i))
		#await get_tree().process_frame
		#var data_folder = DirAccess.open(user_folder.get_current_dir()+"/data")
	System.delete_folder(System.root+"/default-user")
	print("Installed!")
