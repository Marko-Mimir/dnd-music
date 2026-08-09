extends HBoxContainer
class_name DownloadObject

@export var file_name : Label
@export var download_progress : Label
@export var Status : RichTextLabel

func update(file, status):
	if file != "":
		download_progress.text = file
	Status.text = status
