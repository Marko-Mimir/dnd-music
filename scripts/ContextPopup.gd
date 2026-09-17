extends PanelContainer
class_name CtxPopup

@export var spawner: VBoxContainer
var cur_menu: Array[String] = []

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	top_level = true
	z_as_relative = false
	z_index = 4095

func kill() -> void:
	visible = false
	for child in spawner.get_children():
		child.queue_free()

func build_menu(target: ContextTarget, menu: Array[String]) -> void:
	kill() # clear previous content first
	if menu.is_empty():
		return
	cur_menu = menu
	visible = true
	move_to_front()
	for id in range(menu.size()):
		var bt := Button.new()
		bt.text = menu[id]
		bt.mouse_filter = Control.MOUSE_FILTER_STOP
		bt.pressed.connect(_option_pressed.bind(target, id))
		spawner.add_child(bt)

func _option_pressed(target: ContextTarget, id: int) -> void:
	target.handle_action(id)
	kill()
