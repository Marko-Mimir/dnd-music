extends Node2D
class_name utils

signal zip_unpacked

func extract_zip(path : String, dest : String):
	var task = WorkerThreadPool.add_task(
		_unpack.bind(path, dest)
	)
	while not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	
	print("Zip Unpacked!")
	zip_unpacked.emit()

func _unpack(path : String, dest : String):
	var reader = ZIPReader.new()
	if reader.open(path) != OK:
		print("Invalid ZIP file! " + path)
		return
	
	var dir = DirAccess.open(dest)
	if not dir:
		print("Invalid Destination! "+ dest)
		return;
	
	for file in reader.get_files():
		if file.ends_with("/"):
			dir.make_dir_recursive(file)
			continue
		var base_dir = dir.get_current_dir().path_join(file).get_base_dir()
		dir.make_dir_recursive(base_dir)
		
		var file_data = reader.read_file(file)
		var write_path = dir.get_current_dir().path_join(file)
		var output_file = FileAccess.open(write_path, FileAccess.WRITE)
		
		if output_file:
			output_file.store_buffer(file_data)
			output_file.close()
	reader.close()

func delete_dir(path : String) -> int:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				var full_path = path.path_join(file_name)
				if dir.current_is_dir():
					# Recursively clear subfolder
					var err = delete_dir(full_path)
					if err != OK: return err
				else:
					# Delete file
					var err = DirAccess.remove_absolute(full_path)
					if err != OK: return err
			file_name = dir.get_next()
			
		dir.list_dir_end()
		# Directory is now empty, safe to remove
		return DirAccess.remove_absolute(path)
	else:
		print("Failed to open directory: ", path)
		return ERR_CANT_OPEN
