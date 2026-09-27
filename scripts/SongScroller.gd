extends Control
class_name SongManager

@export var container: Control
@export var radius: float = 300.0
@export var spacing_angle: float = 25.0
@export var fisheye_strength: float = 1.2
@export var scroll_sensitivity: float = 0.2
@export var friction: float = 5.0

var current_index: float = 0.0
var scroll_velocity: float = 0.0
var items: Array[Song] = []
var _refresh_generation := 0


func _ready() -> void:
	refresh_items()



func refresh_items() -> void:
	_refresh_generation += 1
	var generation := _refresh_generation
	items.clear()
	for child in container.get_children():
		if child is Song:
			items.append(child)
	
	await get_tree().process_frame
	await get_tree().process_frame
	if generation != _refresh_generation:
		return
	
	for item in items:
		if not is_instance_valid(item):
			continue
		item.pivot_offset = item.size * 0.5

	_update_menu_positions()


func _process(delta: float) -> void:
	if abs(scroll_velocity) > 0.001:
		current_index += scroll_velocity * delta

		current_index = clamp(
			current_index,
			0.0,
			max(0.0, float(items.size() - 1))
		)

		scroll_velocity = lerp(
			scroll_velocity,
			0.0,
			friction * delta
		)

		_update_menu_positions()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_velocity += scroll_sensitivity * 50.0
			get_viewport().set_input_as_handled()

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_velocity -= scroll_sensitivity * 50.0
			get_viewport().set_input_as_handled()


func _update_menu_positions() -> void:
	var valid_items: Array[Song] = []
	for item in items:
		if is_instance_valid(item) and item is Song:
			valid_items.append(item as Song)
	items = valid_items
	var viewport_size: Vector2 = get_viewport_rect().size
	var screen_center: Vector2 = viewport_size * 0.5
	var center: Vector2 = screen_center - container.global_position
	
	for i in range(items.size()):
		var item: Control = items[i]
		if not is_instance_valid(item):
			continue
		var song := item as Song
		if song != null and not song.display_enabled:
			item.visible = false
			continue

		var rel: float = float(i) - current_index
		var angle: float = deg_to_rad(rel * spacing_angle)
		if abs(angle) > PI * 0.5:
			item.visible = false
			continue

		item.visible = true
		var proximity: float = max(0.0, cos(angle))
		# Fisheye
		var scale_amount: float = pow(
			proximity,
			fisheye_strength
		)
		item.scale = Vector2.ONE * scale_amount
		var y: float = sin(angle) * radius
		var item_center: Vector2 = center + Vector2(0.0, y)
		item.position = item_center - item.size * 0.5
		item.z_index = int(proximity * 100.0)
		item.modulate.a = clamp(
			proximity,
			0.15,
			1.0
		)
