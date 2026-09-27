extends CanvasLayer
class_name ContextManager

@export var popup : CtxPopup
var hover_target : ContextTarget= null
var menu_target : ContextTarget = null

func _process(_delta: float) -> void:
	if popup.visible and popup.get_global_rect().has_point(get_viewport().get_mouse_position()):
		hover_target = null
		return
	var t := _check_hover_target(get_viewport().get_mouse_position())
	if t != hover_target:
		hover_target = t

func _check_hover_target(mouse_pos : Vector2) -> ContextTarget:
	var candidates : Array[ContextTarget] = []
	
	for n in get_tree().get_nodes_in_group("context_targets"):
		if n is ContextTarget:
			var c := n as ContextTarget
			if !is_instance_valid(c) or !c.visible:
				continue
			if c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
				continue
			if c.get_global_rect().has_point(mouse_pos):
				candidates.append(c)
	
	if candidates.is_empty():
		return null
	
	candidates.sort_custom(func(a: ContextTarget, b: ContextTarget) -> bool:
		if a.z_index == b.z_index:
			return a.get_index() > b.get_index()
		return a.z_index > b.z_index
		)
	for c in candidates:
		if c.pass_through:
			continue
		return c
	return null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if popup.visible and not popup.get_global_rect().has_point(event.position):
				popup.kill()
			return

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if popup.visible:
				popup.kill()
			var target := _check_hover_target(event.position)
			if target == null:
				return
			
			menu_target = target
			popup.build_menu(menu_target, menu_target.get_context_actions())
			popup.global_position = event.position
			popup.move_to_front()
		#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#if popup.visible:
				#popup.kill()
