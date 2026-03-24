extends Component

var active_menus: PackedStringArray = []

func init():
	update()

func request_menu(menu: String):
	if menu not in active_menus:
		active_menus.append(menu)
		update()

func update():
	for i in get_children():
		if i.name in active_menus: 
			i.show()
		else: 
			i.hide()
