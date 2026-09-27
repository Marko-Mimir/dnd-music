extends CenterContainer
class_name MediaController

@export var audio : AudioStreamPlayer2D
@export var durration : Label
@export var currentTime : Label
@export var title : Label
@export var media : CheckBox
@export var shuffle : CheckBox 
@export var loop : CheckBox
@export var timeline : MusicSlider

signal next_song()
signal previous_song()

func _ready() -> void:
	timeline.drag_ended.connect(change_timeline)

func set_controls(stream : AudioStream, base_name : String) -> void:
	durration.text = UTIL.get_durration(stream)
	title.text = base_name
	timeline.value = 0.0
	timeline.max_value = stream.get_length()

func play_song(path : String) -> void:
	print('playing song...')
	print(path)
	audio.stream = UTIL.importSong(path)
	set_controls(audio.stream, path.get_file().get_basename())
	media.button_pressed = true
	audio.stream_paused = false
	audio.play()

func fade_into_song(path : String) -> void:
	print("fading into song...")
	print(path)
	audio.stream = UTIL.importSong(path)
	set_controls(audio.stream, path.get_file().get_basename())
	media.button_pressed = true
	audio.stream_paused = false
	audio.play()

func media_control_toggled(is_playing: bool) -> void:
	audio.stream_paused = not is_playing

func audio_ended():
	print('ended yuhh')
	next_song.emit()

func change_timeline(val : bool):
	if val:
		var num = timeline.value
		audio.play(num)
		audio.stream_paused = false
		if !media.button_pressed:
			audio.stream_paused = true
		currentTime.text = UTIL.get_current_time(audio)

func _process(_delta: float) -> void:
	if audio.playing:
		currentTime.text = UTIL.get_current_time(audio)
		if !timeline.dragging:
			timeline.value = audio.get_playback_position()

func volume_changed(value: float) -> void:
	audio.volume_db = linear_to_db(value)

func skip() -> void:
	next_song.emit()

func reverse() -> void:
	previous_song.emit()
