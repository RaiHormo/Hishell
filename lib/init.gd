extends Control

const always_reinstall := true

func _ready() -> void:
	System.init = self
	await System.wait(0.3)
	if always_reinstall and DirAccess.dir_exists_absolute("user://filesystem"):
		Filesystem.delete_folder(System.root)
	if not DirAccess.dir_exists_absolute(System.root) or always_reinstall:
		await install()
	User.current = User.users[0]
	System.launch(System.root, Vector2i.ZERO, get_tree().root, true)
	queue_free()

func install():
	print("Starting installation")
	Filesystem.copy_folder("filesystem", "res://filesystem", "user://")
	System.root = Filesystem.abs_path("user://filesystem")
	for i in User.get_usernames():
		var _user_folder = DirAccess.open(User.create_user_folder(i))
		#await get_tree().process_frame
		#var data_folder = DirAccess.open(user_folder.get_current_dir()+"/data")
	Filesystem.delete_folder(System.root+"/default-user")
	print("Installed!")
