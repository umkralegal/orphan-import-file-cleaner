tool
extends EditorPlugin


var orphan_imports: Array = []

onready var orphan_viewer: ConfirmationDialog = null


func _ready():
	orphan_viewer = get_node("ConfirmationDialog")
	orphan_viewer.connect("confirmed", self, "_on_ConfirmationDialog_confirmed")


func _enter_tree():
	add_tool_menu_item("Orphan .import file cleaner", self, "_on_cleaner_pressed")
	orphan_viewer = preload("./confirmation_dialog.tscn").instance()
	add_child(orphan_viewer)


func _exit_tree():
	orphan_viewer.queue_free()
	orphan_viewer = null
	remove_tool_menu_item("Orphan .import file cleaner")


func _on_cleaner_pressed(ub):
	var item_list: ItemList = orphan_viewer.get_node("VBoxContainer/ScrollContainer/VBoxContainer/ItemList")
	item_list.clear()

	var found_files: Array = []
	var dir: Directory = Directory.new()
	var sub_directories: Array = ["res://"]
	while sub_directories.size() > 0:
		var path: String = sub_directories[0]
		var err: int = dir.open(path)
		if err == OK:
			dir.list_dir_begin()
			var file_name: String = dir.get_next()
			while not file_name.empty():
				if not file_name.begins_with("."):
					if dir.current_is_dir():
						sub_directories.append(path + file_name + "/")
					else:
						found_files.append(path + file_name)
				file_name = dir.get_next()
			sub_directories.erase(path)
		else:
			printerr(err)
	dir.list_dir_end()

	orphan_imports = []
	for import_file in found_files:
		if import_file.ends_with(".import"):
			var original_file: String = import_file.rstrip(".import")
			if not original_file in found_files:
				orphan_imports.append(import_file)

	if not orphan_imports.empty():
		for orphan_file in orphan_imports:
			item_list.add_item(orphan_file)
		orphan_viewer.popup_centered()
		orphan_viewer.show()
	else:
		push_warning("No orphan .import files to delete.")


func _on_ConfirmationDialog_confirmed():
	var dir: Directory = Directory.new()
	for file in orphan_imports:
		var err: int = dir.remove(file)
		if not err == OK:
			printerr("Couldn't remove ", file)
	orphan_imports = []
