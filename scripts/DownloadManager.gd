extends Node2D
class_name DownloadManager

signal progress_updated(song_name: String, percent: float, item: int, total: int)
signal download_finished

@export var songLoader : SongLoader
@export var dependancies : DependancyManager
@export var modal_manager: ModalManager
@export var music_directory := "user://music"
var percent_regex: RegEx = RegEx.new()
var item_regex: RegEx = RegEx.new()
var destination_regex: RegEx = RegEx.new()
var active_thread : Array[int] = []
var active_process : Array[int] = []
var shutting_down := false


func _ready() -> void:
	percent_regex.compile(r"\[download\]\s+(\d+(?:\.\d+)?)%")
	item_regex.compile(r"Downloading item (\d+) of (\d+)")
	destination_regex.compile(r"\[download\]\s+Destination:\s+(.+)$")
	progress_updated.connect(_on_progress_updated)
	download_finished.connect(_on_download_finished)

func download_mp3(link : String) -> void:
	if shutting_down: return;
	
	var dir = DirAccess.open("user://")
	if !dir.dir_exists(music_directory):
		dir.make_dir_recursive(music_directory)
	_emit_progress("Preparing download...", 0.0, 1, 0)
	#dispatch worker
	var id = WorkerThreadPool.add_task(ytdl_worker.bind(link))
	active_thread.append(id)

func ytdl_worker(link : String) -> void:
	var ytdlp_path: String = ProjectSettings.globalize_path("user://dependencies/yt-dlp.exe")
	var ffmpeg_dir: String = ProjectSettings.globalize_path("user://dependencies")
	var output_dir: String = ProjectSettings.globalize_path(music_directory.path_join("%(title)s.%(ext)s"))
	var args : PackedStringArray = [ 
		"--sleep-interval", "1", 
		"--max-sleep-interval", "9", 
		"--ignore-errors", 
		"--force-ipv4", 
		link, 
		"--extract-audio", 
		"--audio-format", "mp3", 
		"--ffmpeg-location", ffmpeg_dir, 
		"-o", output_dir, 
	    "--newline" 
	]
	
	print_rich("[color=yellow]Thread started. Executing yt-dlp...[/color]")
	var pipe: Dictionary = OS.execute_with_pipe(ytdlp_path, args)
	
	if not pipe.has("stdio"):
		print_rich("[color=red]Failed to initialize executable pipe.[/color]")
		return
	
	var pid : int = pipe["pid"]
	var stdout: FileAccess = pipe["stdio"]
	var state := {"song_name": "", "percent": 0.0, "item": 1, "total": 0}
	active_process.append.call_deferred(pid)
	while OS.is_process_running(pid) and not shutting_down:
		if stdout.is_open():
			while stdout.get_position() < stdout.get_length():
				var line := stdout.get_line().strip_edges()
				if not line.is_empty():
					print(line)
					_parse_output_line(line, state)
	
	stdout.close()
	
	print_rich("[color=green]Background download process completed successfully![/color]")
	active_process.erase.call_deferred(pid)
	call_deferred("_emit_download_finished")

func _parse_output_line(line: String, state: Dictionary) -> void:
	var item_match := item_regex.search(line)
	if item_match:
		state["item"] = int(item_match.get_string(1))
		state["total"] = int(item_match.get_string(2))
		state["percent"] = 0.0
		call_deferred(
			"_emit_progress",
			state["song_name"],
			state["percent"],
			state["item"],
			state["total"]
		)

	var destination_match := destination_regex.search(line)
	if destination_match:
		state["song_name"] = destination_match.get_string(1).get_file().get_basename()
		call_deferred(
			"_emit_progress",
			state["song_name"],
			state["percent"],
			state["item"],
			state["total"]
		)

	var percent_match := percent_regex.search(line)
	if percent_match:
		state["percent"] = float(percent_match.get_string(1))
		call_deferred(
			"_emit_progress",
			state["song_name"],
			state["percent"],
			state["item"],
			state["total"]
		)

func _emit_progress(song_name: String, percent: float, item: int, total: int) -> void:
	progress_updated.emit(song_name, percent, item, total)

func _emit_download_finished() -> void:
	download_finished.emit()

func _on_progress_updated(song_name: String, percent: float, item: int, total: int) -> void:
	if modal_manager == null:
		return
	modal_manager.open_modal(ModalManager.Modals.DOWNLOAD)
	modal_manager.download.update_progress(song_name, percent, item, total)

func _on_download_finished() -> void:
	if modal_manager != null:
		modal_manager.download.reset()
		songLoader.load_songs()
		

func _exit_tree() -> void:
	shutting_down = true
	for pid in active_process:
		if OS.is_process_running(pid):
			print("Stopping process: ", pid)
			OS.kill(pid)
	for task_id in active_thread:
		WorkerThreadPool.wait_for_task_completion(task_id)

func _report_progress(percent: float) -> void:
	print("Download Progress: ", percent, "%")
