extends Label

@export var scroll_speed: float = 30.0
@export var pause_time := 1.5

var direction: float = -1.0
var pause_timer: float = 0.0
var parent_control : Control

var current_text : String = ""

func _ready() -> void:
	parent_control = get_parent() as Control
	reset_size()
	reset_scroll()

func reset_scroll() -> void:
	position.x = 0
	direction = -1.0
	pause_timer = pause_time
	reset_size()

func _process(delta: float) -> void:
	if parent_control == null:
		return
	if current_text != text:
		current_text = text
		reset_scroll()
	var max_offset := size.x - parent_control.size.x
	if max_offset <= 0:
		position.x = 0
		return
	if pause_timer > 0:
		pause_timer -= delta
		return

	position.x += direction * scroll_speed * delta
	if position.x <= -max_offset:
		position.x = -max_offset
		direction = 1.0
		pause_timer = pause_time
	elif position.x >= 0:
		position.x = 0
		direction = -1.0
		pause_timer = pause_time
