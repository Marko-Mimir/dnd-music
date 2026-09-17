extends Control
class_name ModalManager

@export var song : SongModal
@export var playlist : PlaylistModal
@export var download : DownloadModal
enum Modals {SONG, PLAYLIST, DOWNLOAD, NONE}
var current_modal : Modals = Modals.NONE

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape") and current_modal != Modals.NONE:
		close_modal()

func open_modal(modal : Modals):
	if current_modal == modal:
		return
	close_modal()
	match modal:
		Modals.SONG:
			song.visible = true
			current_modal = Modals.SONG
		Modals.PLAYLIST:
			playlist.visible = true
			current_modal = Modals.PLAYLIST
		Modals.DOWNLOAD:
			download.visible = true
			current_modal = Modals.DOWNLOAD
		Modals.NONE:
			close_modal()

func close_modal():
	current_modal = Modals.NONE
	for child in get_children():
		child.visible = false
		child.reset()
