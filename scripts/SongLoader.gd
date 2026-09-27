extends Node
class_name SongLoader

@export var song_container: Control
@export var song_scene: PackedScene
@export var media : MediaController
@export var download_manager: DownloadManager
@export var scroller : SongManager

var songs: Dictionary[int, Song] = {}
var current : Song = null
var _paths_by_id: Dictionary[int, String] = {}
var current_playlist : Array[int]
var queue : Array[int]
var previous : Array[int]

func _ready() -> void:
	if song_container == null or song_scene == null:
		push_error("SongLoader requires a song container and song scene.")
		return
	if download_manager == null:
		push_error("SongLoader requires a download manager.")
		return
	load_songs()

func song_renamed(_old_path: String, new_path: String, song: Song) -> void:
	var id: int = song.song_id
	if songs.get(id) != song:
		return
	_paths_by_id[id] = new_path

func song_pressed(song: Song) -> void:
	var path: String = song.file_path
	if current:
		current.select = false
	song.select = true
	current = song
	if song.fade:
		media.fade_into_song(path)
		song.fade = false
		return
	media.play_song(path)

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

	var changed: bool = false
	for path in paths:
		var id: int = _find_song_id(path)
		if id == -1:
			id = _song_id(path)
		if songs.has(id):
			continue
		var tile := song_scene.instantiate() as Song
		if tile == null:
			push_error("Song scene root must use Song.gd.")
			continue
		tile.setup(id, path)
		tile.button.pressed.connect(song_pressed.bind(tile))
		tile.path_changed.connect(song_renamed)
		songs[id] = tile
		_paths_by_id[id] = path
		song_container.add_child(tile)
		changed = true

	var ids_to_remove: Array[int] = []
	for id in songs:
		if not paths.has(_paths_by_id[id]):
			ids_to_remove.append(id)

	for id in ids_to_remove:
		var tile: Song = songs[id]
		if current == tile:
			current = null
		songs.erase(id)
		_paths_by_id.erase(id)
		tile.queue_free()
		changed = true

	if changed:
		_refresh_scroller()

func next_song():
	if media.loop.button_pressed and current:
		media.play_song(current.file_path)
		previous.push_front(current.song_id)
		return
	if queue.is_empty():
		if current_playlist.is_empty():
			queue = songs.keys().duplicate_deep()
	if media.shuffle.button_pressed:
		queue.shuffle()
		song_pressed(songs[queue[0]])
		previous.push_front(queue[0])
		queue.pop_front()
		return
	var val = queue.find(current.song_id)+1
	previous.push_front(current.song_id)
	if val >= len(queue):
		song_pressed(songs[queue[0]])
	else:
		song_pressed(songs[queue[val]])

func last_song():
	if previous.is_empty():
		media.audio.play(0)
		return
	song_pressed(songs[previous[0]])
	if media.shuffle.button_pressed:
		queue.push_front(previous.pop_front())
	else:
		previous.pop_front()

func display_songs(ids: Array[int] = []) -> void:
	current_playlist = ids
	var show_all: bool = ids.is_empty()
	var visible_ids: Dictionary[int, bool] = {}
	for id in ids:
		visible_ids[id] = true

	for id in songs:
		var tile: Song = songs[id]
		if is_instance_valid(tile):
			tile.display_enabled = show_all or visible_ids.has(id)
			tile.visible = tile.display_enabled

func _refresh_scroller() -> void:
	scroller.call_deferred("refresh_items")

func _find_song_id(path: String) -> int:
	for id in _paths_by_id:
		if _paths_by_id[id] == path:
			return id
	return -1

func _song_id(path: String) -> int:
	return abs(hash(path))
