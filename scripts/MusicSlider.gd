extends HSlider
class_name MusicSlider

var dragging := false

func _ready() -> void:
	drag_started.connect(start)
	drag_ended.connect(end)

func start():
	dragging = true

func end(_val : bool):
	dragging = false
