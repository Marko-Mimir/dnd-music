extends Node
class_name SongLoader

@export var song_container: Control
@export var song_scene: PackedScene
@export var download_manager: DownloadManager

var songs: Dictionary[int, Song] = {}
var _loaded_paths: Array[String] = []

func _ready() -> void:
	if song_container == null or song_scene == null:
		push_error("SongLoader requires a song container and song scene.")
		return
	if download_manager == null:
		push_error("SongLoader requires a download manager.")
		return
	load_songs()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		load_songs()

func _music_directory() -> String:
	return download_manager.music_directory

func load_songs() -> void:
	var directory := DirAccess.open(_music_directory())
	if directory == null:
		return
	
	var paths: Array[String] = []
	for file_name in directory.get_files():
		if file_name.get_extension().to_lower() == "mp3":
			paths.append(_music_directory().path_join(file_name))
	paths.sort()

	if paths == _loaded_paths:
		return

	var temp: Dictionary[int, Song] = {}
	for path in paths:
		var id := _song_id(path)
		var tile := song_scene.instantiate() as Song
		if tile == null:
			push_error("Song scene root must use Song.gd.")
			return
		tile.setup(id, path)
		temp[id] = tile

	for child in song_container.get_children():
		child.queue_free()
	songs = temp
	_loaded_paths = paths
	for tile in songs.values():
		song_container.add_child(tile)

	var scroller := song_container.get_parent() as Node
	if scroller != null and scroller.has_method("refresh_items"):
		scroller.call_deferred("refresh_items")

func load_playlist(song_ids: Array[int]) -> void:
	var ordered_tiles: Array[Song] = []
	for id in song_ids:
		if songs.has(id):
			ordered_tiles.append(songs[id])
	print("Loading playlist song ids: ", song_ids)
	print("Resolved playlist songs: ", ordered_tiles.size())

func _song_id(path: String) -> int:
	return abs(hash(path))
