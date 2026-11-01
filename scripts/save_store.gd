extends RefCounted
const Campaign = preload("res://scripts/campaign_model.gd")
var path: String
var last_error = ""

func _init(save_path: String = "user://greyford_demo.json"):
	path = save_path

func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var text = FileAccess.get_file_as_string(file_path)
	var parser = JSON.new()
	if parser.parse(text) != OK:
		return {}
	return parser.data if Campaign.valid_snapshot(parser.data) else {}

func load_data() -> Dictionary:
	last_error = ""
	var data = _read(path)
	if not data.is_empty():
		return data
	data = _read(path + ".bak")
	if not data.is_empty():
		last_error = "The current save was unreadable. Your last good backup was recovered."
	elif FileAccess.file_exists(path):
		last_error = "The save and backup could not be read. They have been preserved. Start a new demo to continue."
	return data

func write(data: Dictionary) -> bool:
	last_error = ""
	if not Campaign.valid_snapshot(data):
		last_error = "The campaign snapshot was invalid. Nothing was saved."
		return false
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Could not write the save. Your previous checkpoint is unchanged."
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK or _read(path + ".tmp").is_empty():
		last_error = "Save validation failed. Your previous checkpoint is unchanged."
		return false
	# Never replace a good backup with a corrupt current snapshot.
	if not _read(path).is_empty():
		var backup_error = DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak"))
		if backup_error != OK:
			last_error = "Could not preserve the backup. Your previous checkpoint is unchanged."
			return false
	var error = DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))
	if error != OK:
		last_error = "Could not replace the save. Your previous checkpoint is available."
		return false
	return true
