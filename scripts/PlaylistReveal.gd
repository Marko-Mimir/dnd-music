extends ColorRect

@export var collapsed_width: float = 63.0
@export var expanded_width: float = 232.0
@export var reveal_speed: float = 10.0

var _expanded := false

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	offset_right = collapsed_width

func _process(delta: float) -> void:
	var target_width := expanded_width if _expanded else collapsed_width
	offset_right = lerp(offset_right, target_width, clamp(reveal_speed * delta, 0.0, 1.0))

func _on_mouse_entered() -> void:
	_expanded = true

func _on_mouse_exited() -> void:
	_expanded = false
