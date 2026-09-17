extends CenterContainer
class_name DownloadModal

@onready var song_label: Label = $Panel/MarginContainer/VBox/Song
@onready var progress_label: Label = $Panel/MarginContainer/VBox/Progress
@onready var progress_bar: ProgressBar = $Panel/MarginContainer/VBox/ProgressBar

func update_progress(song_name: String, percent: float, item: int, total: int) -> void:
	visible = true
	song_label.text = song_name if song_name != "" else "Preparing download..."
	progress_label.text = "%d of %d" % [item, total] if total > 0 else "Downloading"
	progress_bar.value = percent

func reset() -> void:
	visible = false
