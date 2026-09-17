extends Node2D
class_name DependancyManager

@export var popup : CenterContainer
@export var progress : CenterContainer
@export var progressTarget : VBoxContainer
@export var dlObj : PackedScene
var downloadProgress : Dictionary[String, DownloadObject] = {}
var active_downloads: Dictionary = {}
var hasYTDLP : bool
var hasFFMPG : bool
var hasDependencies := false

func _ready() -> void:
	var dir = DirAccess.open("user://")
	if dir and dir.dir_exists("user://temp"):
		UTIL.delete_dir("user://temp")
	if dir and !dir.dir_exists("user://dependencies"):
		dir.make_dir("user://dependencies")
	
	var yt = validate_file("yt-dlp.exe")
	hasYTDLP = yt
	var fmp = validate_file("ffmpeg.exe")
	hasFFMPG = fmp
	if !fmp or !yt:
		if !fmp:
			print("Missing ffmpeg.exe")
		if !yt:
			print("Missing yt-dlp.exe")
		print("Asking user if they want to download dependancies...")
		popup.visible = true
	
	if fmp and yt:
		print('Has all dependencies!')
		hasDependencies = true

func _process(_delta: float) -> void:
	if active_downloads.is_empty():
		return
	
	for file_name in active_downloads.keys():
		var http = active_downloads[file_name]
		if is_instance_valid(http):
			file_progress(file_name, http)

func validate_file(fileName) -> bool:
	if FileAccess.file_exists("user://dependencies/"+fileName):
		return true
	return false

func download(link, fileName):
	if active_downloads.has(fileName):
		print("Download already in progress for: ", fileName)
		return
		
	print("Starting download for: ", fileName)
	var http = HTTPRequest.new()
	add_child(http)
	http.max_redirects = 5
	active_downloads[fileName] = http
	
	http.request_completed.connect(func(result, response_code, headers, body):
		complete(result, response_code, headers, body, http, fileName)
	)
	
	http.download_file = "user://dependencies/"+fileName
	var req = http.request(link)
	if req != OK:
		push_error("HTTP Request error for: ", fileName)
		active_downloads.erase(fileName)
		http.queue_free()

func file_progress(file_name: String, http: HTTPRequest) -> void:
	var total_bytes = http.get_body_size()
	var downloaded_bytes = http.get_downloaded_bytes()
	var obj : DownloadObject
	if downloadProgress.has(file_name):
		obj = downloadProgress[file_name]
	else:
		obj = dlObj.instantiate()
		obj.file_name.text = file_name
		progressTarget.add_child(obj)
		downloadProgress[file_name] = obj
	
	if total_bytes <= 0:
		obj.update("0 / 0 MB", "[color=yellow]Connecting...")
		return
	
	var current_mb = float(downloaded_bytes) / 1024.0 / 1024.0
	var total_mb = float(total_bytes) / 1024.0 / 1024.0
	
	obj.update("%.1f / %.1f MB" % [current_mb, total_mb], "[color=green]Downloading...")

func complete(result, _response_code, headers, _body, http, fileName):
	downloadProgress[fileName].update("", "[color=green]Done!")
	active_downloads.erase(fileName)
	
	if result == HTTPRequest.RESULT_SUCCESS and _response_code in [301, 302, 303, 307, 308]:
		var redirect_url = ""
		for header in headers:
			if header.to_lower().begins_with("location:"):
				redirect_url = header.substr(9).strip_edges()
				break
				
		if redirect_url != "":
			print("Redirecting ", fileName, " to: ", redirect_url)
			if is_instance_valid(http):
				http.queue_free()
			download(redirect_url, fileName)
			return
	
	if result != HTTPRequest.RESULT_SUCCESS or _response_code != 200:
		push_error("Download Failed. Result code: ", result, " HTTP code: ", _response_code)
		if http:
			http.queue_free()
		return
		
	print("\n>>> Success! Finished downloading: ", fileName)
	if fileName == "ffmpeg.zip":
		UnpackFFMPEG()
	if hasFFMPG:
		hasDependencies = true
	if http:
		http.queue_free()

func UnpackFFMPEG():
	downloadProgress["ffmpeg.zip"].update("", "[color=green]Processing...")
	var dir = DirAccess.open("user://")
	dir.make_dir("user://temp")
	UTIL.extract_zip("user://dependencies/ffmpeg.zip", "user://temp")
	UTIL.connect("zip_unpacked", processFFMPEG)

func processFFMPEG():
	var dir = DirAccess.open("user://")
	var res = dir.rename("user://temp/ffmpeg-9.0-essentials_build/bin/ffmpeg.exe", "user://dependencies/ffmpeg.exe")
	if res == OK:
		print("Ffmpeg is avaliable!")
		downloadProgress["ffmpeg.zip"].update("", "[color=green]Done!")
	else:
		print(res)
	DirAccess.remove_absolute("user://dependencies/ffmpeg.zip")
	UTIL.delete_dir("user://temp")
	hasDependencies = true

func yes() -> void:
	print("User confirmed.")
	popup.visible = false
	progress.visible = true
	if !hasYTDLP:
		download("https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe", "yt-dlp.exe")
	if !hasFFMPG:
		download("https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip", "ffmpeg.zip")

func no() -> void:
	print("User does not want to download dependancies. Goodbye!")
	get_tree().quit()
