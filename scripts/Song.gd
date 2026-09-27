extends ContextTarget
class_name Song

@export var button : Button
@export var nameEdit : LineEdit
@export var title : RichTextLabel
@export var SelectedRect : ColorRect
@export var durration : RichTextLabel

signal path_changed(oldpath : String, newpath : String, song : Song)

var fade

var select : bool = false:
	set(value):
		SelectedRect.visible = value
		select = value
var song_id: int
var file_path: String
var display_enabled: bool = true
var base_dir : String = "user://music/"
var _normal_title_minimum_size := Vector2.ZERO


func _ready() -> void:
	_normal_title_minimum_size = title.custom_minimum_size

func setup(id: int, path: String) -> void:
	song_id = id
	file_path = path
	title.text = path.get_file().get_basename()
	durration.text = UTIL.get_durration(UTIL.importSong(path))

func handle_action(id: int) -> void:
	match id:
		0: #play
			button.pressed.emit()
		1: #fade
			fade = true
			button.pressed.emit()
		2: #add to playlist
			pass
			print("add song to playlist via id:"+ str(song_id))
		3: #rename
			nameEdit.text = title.text
			title.visible = false
			nameEdit.visible = true
			_update_name_edit_width()
			nameEdit.caret_column = nameEdit.text.length()
			nameEdit.grab_focus()
		4: #edit description
			pass
		5: #Show in folder
			OS.shell_show_in_file_manager(ProjectSettings.globalize_path(file_path))

func name_text_changed(new_text: String) -> void:
	if nameEdit.visible == true:
		_update_name_edit_width()
		title.text = new_text

func _update_name_edit_width() -> void:
	var font := nameEdit.get_theme_font("font")
	var font_size := nameEdit.get_theme_font_size("font_size")
	var text_width := font.get_string_size(nameEdit.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var required_width: float = maxf(80.0, text_width + 24.0)
	nameEdit.custom_minimum_size.x = required_width


func _text_submitted(new_text: String) -> void:
	title.text = new_text
	nameEdit.release_focus()
	nameEdit.visible = false
	title.visible = true
	nameEdit.text = ""
	nameEdit.custom_minimum_size = Vector2.ZERO
	var error = DirAccess.rename_absolute(file_path, base_dir+new_text+".mp3")
	if error == OK:
		var old_path: String = file_path
		var new_path: String = base_dir + new_text + ".mp3"
		file_path = new_path
		path_changed.emit(old_path, new_path, self)
	else:
		print("Failed to rename file. Error code: ", error)
