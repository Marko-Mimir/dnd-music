extends Node

@export var http_request: HTTPRequest;
const GITHUB_API_URL = "https://api.github.com/repos/marko-mimir/dnd-music/releases/latest"
@export var CURRENT_VERSION = "v1.0.0" # Match your current running version tag
@export var text : RichTextLabel

func _ready() -> void:
	var exe_dir = OS.get_executable_path().get_base_dir()
	http_request.request_completed.connect(_on_request_completed)
	check_for_updates()
	print(FileAccess.file_exists("res://batch/update.bat"))
	if OS.has_feature("editor"):
		print("hi debug marko")
		return
	if not FileAccess.file_exists(exe_dir.path_join("update.bat")):
		var source_file = FileAccess.open("res://batch/update.bat", FileAccess.READ)
		if source_file:
			print('source confirm')
			var dest =  FileAccess.open(exe_dir.path_join("update.bat"), FileAccess.WRITE)
			if dest:
				print('dest yay!')
				dest.store_buffer(source_file.get_buffer(source_file.get_length()))
				dest.close()
			else:
				print('no dest')
			source_file.close()
		else:
			print('no source')

func check_for_updates() -> void:
	# GitHub API requires a User-Agent header
	var headers = ["Accept: application/vnd.github+json", "X-GitHub-Api-Version: 2026-03-10"]
	var error = http_request.request(GITHUB_API_URL, headers)
	if error != OK:
		print("Failed to start HTTP request.")
		text.text= "[color=yellow]Maybe updated? (error)"

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("tag_name"):
			var latest_version = json["tag_name"]
			if latest_version != CURRENT_VERSION:
				print("New version available: ", latest_version)
				text.text = "[color=red]New version avaliable![color=#808080]("+latest_version+")"
			else:
				print("Game is up to date.")
				text.text = "[color=green]Up to date!"
	else:
		print("Failed to check updates. Response code: ", response_code)
