extends Node2D

const EXPORT_DIR = "C:/Users/amero/Downloads/versions and journal/part09.5 (addded Map Algorithm) last point - Copy - Copy/PCG_Maze/export"
var Room = preload("res://Room.tscn")

onready var ExportSound = $UI/ExportSound
onready var ExportNotification = $UI/ExportNotification
onready var ExportTween = $UI/ExportTween

export(int) var num_rooms = 50 # number of rooms to generate
export(int) var min_size = 4  # minimum room size (in tiles)
export(int) var max_size = 10 # maximum room size (in tiles)
export(int) var hspread = 400 # horizontal spread (in pixels)
export(float) var cull = 0.5  # chance to cull room

const INPUT_COOLDOWN = 1  # half a second

var tile_size = 32  # size of a tile in the TileMap
var can_process_input = true
var path  # AStar pathfinding object
var export_counter = 0  # Increments for each exported map

func _ready():
	randomize()
	export_counter = get_next_export_index()
	make_rooms()

func show_export_message(filename):
	ExportNotification.text = "âœ… Exported: " + filename
	ExportNotification.modulate.a = 0
	ExportNotification.rect_position.y = -30  # Slide from above
	ExportNotification.show()
	ExportSound.play()

	ExportTween.stop_all()  # Reset if needed

	# Fade in
	ExportTween.interpolate_property(
		ExportNotification, "modulate:a",
		0.0, 1.0,
		0.4, Tween.TRANS_SINE, Tween.EASE_OUT
	)

	# Slide in (Y position)
	ExportTween.interpolate_property(
		ExportNotification, "rect_position:y",
		-30, 20,
		0.4, Tween.TRANS_SINE, Tween.EASE_OUT
	)

	# Fade out
	ExportTween.interpolate_property(
		ExportNotification, "modulate:a",
		1.0, 0.0,
		0.5, Tween.TRANS_SINE, Tween.EASE_IN,
		.5  # delay before fading out
	)

	# Slide out
	ExportTween.interpolate_property(
		ExportNotification, "rect_position:y",
		20, -30,
		0.5, Tween.TRANS_SINE, Tween.EASE_IN,
		.5  # same delay
	)
	ExportSound.play()
	ExportTween.start()
	
func make_rooms():
		for i in range(num_rooms):
			var pos = Vector2(rand_range(-hspread, hspread), 0)
			var r = Room.instance()
			var w = min_size + randi() % (max_size - min_size)
			var h = min_size + randi() % (max_size - min_size)
			r.make_room(pos, Vector2(w, h) * tile_size)
			$Rooms.add_child(r)
		# wait for movement to stop
		yield(get_tree().create_timer(1.1), 'timeout')
		# cull rooms
		var room_positions = []
		for room in $Rooms.get_children():
			if randf() < cull:
				room.queue_free()
			else:
				room.mode = RigidBody2D.MODE_STATIC
				room_positions.append(Vector3(room.position.x,
											  room.position.y, 0))
		yield(get_tree(), 'idle_frame')
		# generate a minimum spanning tree connecting the rooms
		path = find_mst(room_positions)
			
func _draw():
		for room in $Rooms.get_children():
			draw_rect(Rect2(room.position - room.size, room.size * 2),
					 Color8(0,255 , 0) , false)
		if path:
			for p in path.get_points():
				for c in path.get_point_connections(p):
					var pp = path.get_point_position(p)
					var cp = path.get_point_position(c)
					draw_line(Vector2(pp.x, pp.y), Vector2(cp.x, cp.y),
							  Color8(255, 255, 255), 15, true)

func _process(delta):
	update()
	
func _input(event):
	if event.is_echo() or not can_process_input:
		return

	if event.is_action_pressed("ui_select"):
		can_process_input = false
		for n in $Rooms.get_children():
			n.queue_free()
		path = null
		make_rooms()
		print("Action Pressed: ui_select")
		yield(get_tree().create_timer(INPUT_COOLDOWN), "timeout")
		can_process_input = true

	elif event.is_action_pressed("ui_accept"):
		can_process_input = false
		export_map_data()
		print("Action Pressed: ui_accept")
		yield(get_tree().create_timer(INPUT_COOLDOWN), "timeout")
		can_process_input = true

func find_mst(nodes):
	# Prim's algorithm Given an array of positions (nodes), generates a minimum
	# spanning tree Returns an AStar object Initialize the AStar and add the first point

	var path = AStar.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	# Repeat until no more nodes remain
	while nodes:
		var min_dist = INF  # Minimum distance so far
		var min_p = null  # Position of that node
		var p = null  # Current position
		# Loop through points in path
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			# Loop through the remaining nodes
			for p2 in nodes:
				# If the node is closer, make it the closest
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2)
					min_p = p2
					p = p1
		# Insert the resulting node into the path and add
		# its connection
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		# Remove the node from the array so it isn't visited again
		nodes.erase(min_p)
	return path

func _on_SaveButton_pressed():
	if can_process_input:
		can_process_input = false
		export_map_data()
		yield(get_tree().create_timer(INPUT_COOLDOWN), "timeout")
		can_process_input = true

func export_map_data():
	var data = {
		"rooms": [],
		"path_points": [],
		"path_connections": []
	}

	# Gather room data
	for room in $Rooms.get_children():
		data["rooms"].append({
			"position": {"x": room.position.x, "y": room.position.y},
			"size": {"x": room.size.x, "y": room.size.y}
		})

	# Path data
	if path:
		for point_id in path.get_points():
			var pos = path.get_point_position(point_id)
			data["path_points"].append({
				"id": point_id,
				"position": {"x": pos.x, "y": pos.y, "z": pos.z}
			})
			for conn in path.get_point_connections(point_id):
				data["path_connections"].append({
					"from": point_id,
					"to": conn
				})

	# Generate timestamp
	var dt = OS.get_datetime()
	var timestamp = "%04d%02d%02d_%02d%02d%02d" % [
		dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second
	]
	var base_name = "map_%02d_%s" % [export_counter, timestamp]

	# Export JSON
	var json_path = "%s/%s.json" % [EXPORT_DIR, base_name]
	var file = File.new()
	var err = file.open(json_path, File.WRITE)
	if err == OK:
		file.store_string(to_json(data))
		file.close()
		print("âœ… Map data exported to ", json_path)

		yield(get_tree(), "idle_frame")
		export_screenshot(base_name)
		show_export_message(json_path)

		export_counter += 1
	else:
		print("âŒ Failed to save map data")


func export_screenshot(base_name):
	var img = get_viewport().get_texture().get_data()
	img.flip_y()

	# Crop from center (example)
	var crop_w = 1600
	var crop_h = 1000
	var crop_x = int((img.get_width() - crop_w) / 2)
	var crop_y = int((img.get_height() - crop_h) / 2)

	var region = Image.new()
	region.create(crop_w, crop_h, false, img.get_format())
	region.blit_rect(img, Rect2(crop_x, crop_y, crop_w, crop_h), Vector2(0, 0))
	img = region

	var screenshot_path = "%s/%s.png" % [EXPORT_DIR, base_name]
	var err = img.save_png(screenshot_path)
	if err == OK:
		print("í ½í¶¼ï¸ Screenshot saved to ", screenshot_path)
	else:
		print("âŒ Failed to save screenshot")
		
func get_next_export_index():
	var dir = Directory.new()
	var index = 0

	if dir.open(EXPORT_DIR) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json") and file_name.begins_with("map_"):
				var parts = file_name.split("_")
				if parts.size() >= 2:
					var num = int(parts[1])
					if num >= index:
						index = num + 1
			file_name = dir.get_next()
		dir.list_dir_end()
	
	return index


func _on_ExitButton_pressed():
	get_tree().quit()

func _on_BackButton_pressed():
	get_tree().change_scene("res://SettingsMenu.tscn")

func _on_GenerateButton_pressed():
	can_process_input = false
	for n in $Rooms.get_children():
		n.queue_free()
	path = null
	make_rooms()
	print("Action Pressed: ui_select")
	yield(get_tree().create_timer(INPUT_COOLDOWN), "timeout")
	can_process_input = true



