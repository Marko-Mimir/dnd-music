extends ContextTarget
class_name Song

var song_id: int
var file_path: String

func setup(id: int, path: String) -> void:
	song_id = id
	file_path = path

	var title_label := get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer/RichTextLabel")
	if title_label is RichTextLabel:
		title_label.text = path.get_file().get_basename()

func handle_action(id: int) -> void:
	print("Song action [", actions[id], "] for id ", song_id)
