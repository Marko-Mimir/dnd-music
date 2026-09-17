extends Control
class_name ContextTarget

@export var actions : Array[String] = []
@export var pass_through : bool = false

func get_context_actions() -> Array:
	return actions

func handle_action(id : int) -> void:
	print("ACTION NOT HANDLED!! ["+actions[id]+"]" )

func _enter_tree() -> void:
	add_to_group("context_targets")

func _exit_tree() -> void:
	remove_from_group("context_targets")
