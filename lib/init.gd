extends Node

var reinstall := false
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var status: Label = $Status


func _ready() -> void:
	System.init = self
	status.text = ""
	get_window().content_scale_factor = DisplayServer.screen_get_scale()
	animation_player.play("Boot")
	if reinstall and DirAccess.dir_exists_absolute("user://filesystem"):
		if OS.get_name() == "Web":
			JavaScriptBridge.eval("window.indexedDB.databases().then(dbs => { dbs.forEach(db => window.indexedDB.deleteDatabase(db.name)); })")
			JavaScriptBridge.eval('window.location.reload(true);')
			return
		else:
			Filesystem.delete_folder(System.root)
	if not DirAccess.dir_exists_absolute(System.root) or reinstall:
		await install()
	if not DirAccess.dir_exists_absolute(System.root):
		status.text = "Failed to copy files"
		return
	User.current = User.users[0]
	Filesystem.cleanup()
	
	if animation_player.is_playing():
		await animation_player.animation_finished
	
	if Input.is_physical_key_pressed(KEY_CTRL) and reinstall == false:
		reinstall = true
		_ready()
		return
	reinstall = false
	
	System.launch(System.root, Vector2.ZERO, get_tree().root, true)
	animation_player.play("Done")
	status.text = ""
	await animation_player.animation_finished
	queue_free()

func install():
	status.text = "Installing..."
	print("Starting installation")
	if Filesystem.copy_folder("filesystem", "res://filesystem", "user://", true, false).is_empty():
		print("Couldn't copy filesystem to user://")
	else:
		System.root = Filesystem.abs_path("user://filesystem")
		for i in User.get_usernames():
			User.create_user_folder(i)
		Filesystem.delete_folder(System.root.path_join("/default-user"))
		print("Installed!")
