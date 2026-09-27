extends Modal
class_name SongModal

@export var link : LineEdit
@export var error : RichTextLabel
@export var download : DownloadManager
@export var modal_manager : ModalManager

var rx = RegEx.new()

func _ready() -> void:
	rx.compile("(?:https?://)?(?:m\\.|www\\.)?(?:youtu\\.be/|youtube\\.com/(?:embed/|v/|watch\\?v=|watch\\?.+&v=))([\\w-]{11})(?:\\S+)?")

func _open_folder() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://music"))

func _paste_link() -> void:
	link.text = DisplayServer.clipboard_get()

func reset():
	link.text = ""

func _link_submitted(new_text: String) -> void:
	_start_download()

func _start_download() -> void:
	var res = rx.search(link.text)
	if res == null: print("invalid link!"); error.visible = true; return;
	print(res.get_string())
	download.download_mp3(res.get_string())
	if modal_manager != null:
		modal_manager.open_modal(ModalManager.Modals.DOWNLOAD)


func go() -> void:
	_start_download()
