extends Node
## Local-first save system — versioned JSON in user://saves/.
## A cloud mirror (Firebase) can sync the same payload later; local stays the
## source of truth so the game works fully offline.

const SAVE_DIR := "user://saves"
const SCHEMA_VERSION := 1

var slot := 1


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_path() -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func has_save() -> bool:
	return FileAccess.file_exists(save_path())


func save_game() -> void:
	var data := {
		"version": SCHEMA_VERSION,
		"part": GameState.part,
		"quest_stage": GameState.quest_stage,
		"discernment_unlocked": GameState.discernment_unlocked,
		"collected_shards": GameState.collected_shards,
		"gifts": GameState.gifts,
		"delivered_spirits": GameState.delivered_spirits,
		"oil": GameState.oil,
		"playtime": GameState.playtime,
		"saved_at": Time.get_datetime_string_from_system(),
	}
	var file := FileAccess.open(save_path(), FileAccess.WRITE)
	if file == null:
		push_error("Save failed: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(save_path(), FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file unreadable — starting fresh.")
		return false
	GameState.apply_save(parsed)
	return true
