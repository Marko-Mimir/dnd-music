extends ColorRect
class_name PlaylistManager

signal home_selected
signal playlist_selected(song_ids: Array[int])

@export var menu: VBoxContainer
@export var song_loader: SongLoader
@export var collapsed_width := 63.0
@export var expanded_width := 300.0
@export var reveal_speed := 10.0

const ADD_SONG_ICON := preload("res://sprites/addMusic.png")
const ADD_PLAYLIST_ICON := preload("res://sprites/addPlaylist.png")
const PLAYLIST_ICON := preload("res://sprites/playlist.png")

var selected : Button = null
var home_button: Button
var playlists: Dictionary[int, Dictionary] = {}
var random := RandomNumberGenerator.new()
var _expanded := false
var _normal_style := StyleBoxFlat.new()
var _selected_style := StyleBoxFlat.new()

func _ready() -> void:
	if menu == null:
		push_error("PlaylistManager requires a menu container.")
		return

	clip_contents = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	offset_right = collapsed_width
	_normal_style.bg_color = Color(0.29, 0.29, 0.29, 1.0)
	_selected_style.bg_color = Color(0.16, 0.16, 0.16, 1.0)
	random.randomize()
	_add_special_button("Add Music", ADD_SONG_ICON, _on_add_song_pressed)
	_add_special_button("Create Playlist", ADD_PLAYLIST_ICON, _on_add_playlist_pressed)
	home_button = _add_special_button("Home", preload("res://sprites/home.png"), _on_home)
	_select(home_button)
	_on_home()

func _process(delta: float) -> void:
	var target_width := expanded_width if _expanded else collapsed_width
	offset_right = lerp(offset_right, target_width, clamp(reveal_speed * delta, 0.0, 1.0))

func _add_special_button(label: String, icon: Texture2D, callback: Callable) -> Button:
	var button := _make_button(label, icon)
	button.pressed.connect(callback)
	menu.add_child(button)
	return button

func _make_button(label: String, icon: Texture2D) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(292, 55)
	button.text = label
	button.icon = icon
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.expand_icon = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_constant_override("icon_max_width", 55)
	button.add_theme_constant_override("h_separation", 12)
	button.add_theme_stylebox_override("normal", _normal_style.duplicate())
	button.pressed.connect(_select.bind(button))
	return button

func _select(button: Button) -> void:
	if selected == button:
		return
	if is_instance_valid(selected):
		selected.add_theme_stylebox_override("normal", _normal_style.duplicate())
	selected = button
	selected.add_theme_stylebox_override("normal", _selected_style.duplicate())

func _on_home() -> void:
	home_selected.emit()

func _on_add_song_pressed() -> void:
	print("Launching Add Song Modal")
	%MODAL.open_modal(ModalManager.Modals.SONG)
	_select(home_button)
	_on_home()

func _on_add_playlist_pressed() -> void:
	print("Launching Creae PLaylist Modal")
	%MODAL.open_modal(ModalManager.Modals.PLAYLIST)
	_select(home_button)
	_on_home()

func _on_mouse_entered() -> void:
	_expanded = true

func _on_mouse_exited() -> void:
	_expanded = false

func create_fake_playlist(song_ids: Array[int] = []) -> int:
	var id := random.randi()
	while playlists.has(id):
		id = random.randi()

	var button := _make_button("Playlist %d" % id, PLAYLIST_ICON)
	button.pressed.connect(_on_fake_playlist_pressed.bind(id, song_ids))
	menu.add_child(button)
	playlists[id] = {"id": id, "button": button, "song_ids": song_ids.duplicate()}
	print("Created fake playlist with id: ", id)
	return id

func _on_fake_playlist_pressed(id: int, song_ids: Array[int]) -> void:
	print("Playlist menu: fake playlist clicked, id: ", id)
	playlist_selected.emit(song_ids)
