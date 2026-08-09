extends Node2D
class_name DownloadManager

@export var dependancies : DependancyManager
var percent_regex: RegEx = RegEx.new()

func _ready() -> void:
	percent_regex.compile(r"\[download\]\s+(\d+(?:\.\d+)?)%")
	dependancies.hasDependencies.connect(test)

func test():
	pass
	print("meow")
	download_mp3("https://youtu.be/nBv5BzFpvvE")

func download_mp3(link : String) -> void:
	var dir = DirAccess.open("user://")
	if !dir.dir_exists("user://music"):
		dir.make_dir("user://music")
	#dispatch worker
	WorkerThreadPool.add_task(ytdl_worker.bind(link))

func ytdl_worker(link : String) -> void:
	var ytdlp_path: String = ProjectSettings.globalize_path("user://dependencies/yt-dlp.exe")
	var ffmpeg_dir: String = ProjectSettings.globalize_path("user://dependencies")
	var output_dir: String = ProjectSettings.globalize_path("user://music/%(title)s.%(ext)s")
	var args : PackedStringArray = [
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
	var stdout: FileAccess = pipe["stdio"]
	while stdout.is_open() and not stdout.get_error() == ERR_FILE_EOF:
		var line: String = stdout.get_line().strip_edges()
		if line.is_empty():
			OS.delay_msec(10)
			continue
			
		print(line)
		#var regex_match = percent_regex.search(line)
		#if regex_match:
			#var percentage_str: String = regex_match.get_string(1)
			#_report_progress(percentage_str.to_float())
		#elif "Deleting original file" in line:
			#print("Conversion finished, cleaning up video source...")
			
	print_rich("[color=green]Background download process completed successfully![/color]")

func _report_progress(percent: float) -> void:
	print("Download Progress: ", percent, "%")
