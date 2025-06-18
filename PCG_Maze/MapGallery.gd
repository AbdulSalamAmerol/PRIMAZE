extends Control

onready var MapList = $VBoxContainer/HBoxContainer/MapList
onready var MapPreview = $VBoxContainer/HBoxContainer/MapPreview
onready var PlayButton = $VBoxContainer/HBoxContainer2/PlayButton
var main_scene = preload("res://Main.tscn")  # Adjust path if needed
var map_files = []

func _ready():
	PlayButton.disabled = true
	load_map_list()

func load_map_list():
	var dir = Directory.new()
	if dir.open("res://export") == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json") and file_name.begins_with("map_"):
				map_files.append(file_name)
				MapList.add_item(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Failed to open directory.")


func _on_MapList_item_selected(index):
	var map_name = map_files[index]
	var base_name = map_name.get_basename()
	var img_path = "res://export/%s.png" % base_name
	var img = load(img_path)

	if img and img is Texture:
		MapPreview.texture = img
	else:
		MapPreview.texture = null
		print("⚠️ Screenshot not found: ", img_path)
	PlayButton.disabled = false  # Enable the Play button once a selection is made

func _on_PlayButton_pressed():
	var selected = MapList.get_selected_items()
	var map_file = map_files[selected[0]]
	var full_path = "res://export/" + map_file

	# Load the scene manually
	var scene = main_scene.instance()
	scene.set("map_path", full_path)  # Pass the map path directly

	get_tree().get_root().add_child(scene)
	get_tree().current_scene.queue_free()  # Optional: Remove current gallery scene
	get_tree().set_current_scene(scene)




func _on_BackButton_pressed():
	get_tree().change_scene("res://MainMenu.tscn")
