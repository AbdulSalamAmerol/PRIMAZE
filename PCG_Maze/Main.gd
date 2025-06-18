extends Node2D	
var Room = preload("res://Room.tscn")
var font = preload("res://assets/RobotoBold120.tres")
var Enemy = preload("res://Enemy.tscn")  # Adjust path if needed
export(String) var map_path = ""
export(float) var game_duration = 5.0 # Duration in seconds (e.g., 2 minutes)
var time_remaining = 0
export(String, FILE, "*.tscn") var win_scene_path = "res://WinScene.tscn" # Path to your win screen
export(String, FILE, "*.tscn") var lose_scene_path = "res://LoseScene.tscn" # Path to your lose screen
var Player = preload("res://DemoPlayer.tscn")
var player = null
onready var GameLevelMusic = $GameLevelMusic
onready var Map = $TileMap #added
onready var FogMap = $FogMap
var game_timer = null # Timer node for game duration
var tile_size = 32  # size of a tile in the TileMap
var num_rooms = 50  # number of rooms to generate
var min_size = 6  # minimum room size (in tiles)
var max_size = 15  # maximum room size (in tiles)
var hspread = 400  # horizontal spread (in pixels)
var cull = 0.5  # chance to cull room

var path  # AStar pathfinding object
var start_room = null
var end_room = null
var play_mode = false  
const VISION = 5   # tiles of vision
var last_tile = Vector2(-999, -999)   # impossible start

func _ready():
	randomize()
	    # Initial button states
    # Disable PlayButton initially
	get_node("HUD/PlayButton").disabled = true
	get_node("HUD/BuildButton").disabled = false

	FogMap.cell_size = Map.cell_size
	FogMap.clear()
		# Initialize the game timer
	game_timer = Timer.new()
	game_timer.wait_time = game_duration
	game_timer.one_shot = true # Timer stops after reaching zero
	# Connect the timeout signal to  game over function
	game_timer.connect("timeout", self, "_on_GameTimer_timeout")
	add_child(game_timer) # Add timer to the scene tree
	time_remaining = game_duration


	print("Ì†ΩÌ≥Ç Received map path: ", map_path)
	if map_path != "":
		var map_data = load_map_from_json(map_path)
		if map_data:
			load_rooms_from_data(map_data.rooms)
			load_paths_from_data(map_data.path_points, map_data.path_connections)
			
	else:
		print("‚ö†Ô∏è No map path received.")
	

func spawn_enemy_at(position):
	var e = Enemy.instance()
	add_child(e)
	e.global_position = position

func load_map_from_json(path):
	var file = File.new()
	if file.file_exists(path):
		file.open(path, File.READ)
		var data = parse_json(file.get_as_text())
		file.close()
		return data
	else:
		print("Map file not found: ", path)
		return null

func load_rooms_from_data(rooms):
	for room_data in rooms:
		var r = Room.instance()
		var pos = Vector2(room_data.position.x, room_data.position.y)
		var size = Vector2(room_data.size.x, room_data.size.y)
		r.make_room(pos, size)
		r.mode = RigidBody2D.MODE_STATIC
		$Rooms.add_child(r)


func load_paths_from_data(points, connections):
    if not points or not connections:
        print("No path data found!")
        return

    path = AStar.new()
    for pt in points:
        if typeof(pt) == TYPE_DICTIONARY:
            path.add_point(pt.id, Vector3(pt.position.x, pt.position.y, pt.position.z))
    for conn in connections:
        path.connect_points(conn.from, conn.to)


func make_rooms_from_json(map_data):
	# Assumes map_data is already parsed JSON with "rooms", "path_points", "path_connections"
	for room_data in map_data.rooms:
		var r = Room.instance()
		r.position = Vector2(room_data.position.x, room_data.position.y)
		r.size = Vector2(room_data.size.x, room_data.size.y)
		r.mode = RigidBody2D.MODE_STATIC
		$Rooms.add_child(r)

	path = AStar.new()
	for pt in map_data.path_points:
		path.add_point(pt.id, Vector3(pt.position.x, pt.position.y, pt.position.z))

	for conn in map_data.path_connections:
		path.connect_points(conn.from, conn.to)

            
func _draw():
	if start_room:
		draw_string(font, start_room.position - Vector2(125, 0), "START", Color(0,0,0))
	if end_room:
		draw_string(font, end_room.position - Vector2(125, 0), "END", Color(0,0,0))
    
	if play_mode:
		draw_string(font, Vector2(0, 0), "" + str(int(game_timer.time_left)), Color(1,1,0))
		return

	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size * 2), Color(0, 0, 0), false)

	if path:
		for p in path.get_points():
			for c in path.get_point_connections(p):
				var pp = path.get_point_position(p)
				var cp = path.get_point_position(c)
				draw_line(Vector2(pp.x, pp.y), Vector2(cp.x, cp.y), Color(1, 1, 1), 15, true)

func _process(delta):

	update() # Request redraw for _draw() method
	if game_timer.time_left > 0:
		time_remaining = game_timer.time_left
		$HUD/TimerLabel.text = format_time(time_remaining)

	if play_mode and player and end_room:
		# Check if player reached the end room.
		# Both end_room_bounds and player.global_position should be in the same (global) coordinate space.
		# Assuming end_room.size represents half-extents of the room.
		# Define the bounds using the end_room's global position and its size.
		var end_room_bounds = Rect2(end_room.global_position - end_room.size, end_room.size * 2)
		
		if end_room_bounds.has_point(player.global_position):
			_player_reached_end()	
	
			
func format_time(seconds):
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]


func _input(event):
	if event.is_echo():
		return  

	if event.is_action_pressed('ui_select'):
		if play_mode:
			player.queue_free()
			play_mode = false
		for n in $Rooms.get_children():
			n.queue_free()
		path = null
		start_room = null
		end_room = null

		var map_data = load_map_from_json(MapLoader.map_path)
		if map_data:
			load_rooms_from_data(map_data.rooms)
			load_paths_from_data(map_data.path_points, map_data.path_connections)

    # ‚úÖ this must be separate
	if event.is_action_pressed('ui_focus_next'):
		print("Calling make_map...")
		make_map()

	if event.is_action_pressed('ui_cancel'):
		if start_room:
			player = Player.instance()
			add_child(player)
			player.position = start_room.position
			play_mode = true
			reveal_fog_around_player()
			game_timer.start() # Start the game timer
			print("Game started! Timer running for ", game_timer.wait_time, " seconds.")
			game_timer.start()
			GameLevelMusic.connect("finished", self, "_on_GameLevelMusic_finished")
			GameLevelMusic.play()


func make_map(): #create a TileMap from the generated rooms and path
	print("make_map called! Rooms: ", $Rooms.get_child_count(), ", Path: ", path)
	Map.clear()
	find_start_room()
	find_end_room()
	spawn_enemies_in_random_rooms()
    
	var full_rect = Rect2() #full rectangle that encloses our entire map
	for room in $Rooms.get_children():
		var r = Rect2(room.position - room.size, room.get_node("CollisionShape2D").shape.extents * 2)
		full_rect = full_rect.merge(r)

	var topleft = Map.world_to_map(full_rect.position)
	var bottomright = Map.world_to_map(full_rect.end)

	for x in range(topleft.x, bottomright.x):
		for y in range(topleft.y, bottomright.y):
			Map.set_cell(x, y, 1) 
			FogMap.set_cell(x, y, 0)  #tama to

	#carve Rooms
	var corridors = [] #one corridor per connection
	for room in $Rooms.get_children():
		var s = (room.size / tile_size).floor()
		var pos = Map.world_to_map(room.position)
		var ul = (room.position / tile_size).floor() - s

		for x in range(2, s.x * 2 - 1):
			for y in range(2, s.y * 2 - 1):
				Map.set_cell(ul.x + x, ul.y + y, 0)
	#carve connecting corridor
		var p = path.get_closest_point(Vector3(room.position.x, room.position.y, 0))
		for conn in path.get_point_connections(p):
			if not conn in corridors:
				var start = Map.world_to_map(Vector2(path.get_point_position(p).x, path.get_point_position(p).y))
				var end = Map.world_to_map(Vector2(path.get_point_position(conn).x, path.get_point_position(conn).y))                                    
				carve_path(start, end)
		corridors.append(p)
                
func carve_path(pos1, pos2):
	#carve a path between two points
    var x_diff = sign(pos2.x - pos1.x)
    var y_diff = sign(pos2.y - pos1.y)
    if x_diff == 0: x_diff = pow(-1.0, randi() % 2)
    if y_diff == 0: y_diff = pow(-1.0, randi() % 2)

    var x_y = pos1
    var y_x = pos2
    if (randi() % 2) > 0:
        x_y = pos2
        y_x = pos1

    for x in range(pos1.x, pos2.x, x_diff):
        Map.set_cell(x, x_y.y, 0)
        Map.set_cell(x, x_y.y + y_diff, 0)

    for y in range(pos1.y, pos2.y, y_diff):
        Map.set_cell(y_x.x, y, 0)
        Map.set_cell(y_x.x + x_diff, y, 0)

func find_start_room():
    var min_x = INF
    for room in $Rooms.get_children():
        if room.position.x < min_x:
            start_room = room
            min_x = room.position.x

func find_end_room():
    var max_x = -INF
    for room in $Rooms.get_children():
        if room.position.x > max_x:	
            end_room = room
            max_x = room.position.x
			
func _player_reached_end():
	"""Called when the player reaches the end room."""
	if play_mode: # Ensure game is still running
		print("Player reached the end! You win!")
		get_tree().change_scene("res://WinScene.tscn")
		game_timer.stop() # Stop the timer as player won
		get_tree().change_scene("res://WinScene.tscn")
		play_mode = false # Stop game logic
		if player:
			player.queue_free()
			player = null
# --- Timer and Game State Callbacks ---

func _on_GameTimer_timeout():
	if play_mode: 
		$HUD/TimerLabel.text = "00:00"
		print("Timer timed out! You lose.")
		get_tree().change_scene("res://LoseScene.tscn")
		play_mode = false 
		if player:
			player.queue_free()
			player = null


func spawn_enemies_in_random_rooms(enemy_count = 5):
	var available_rooms = []

	for room in get_node("Rooms").get_children():
		if room != start_room and room != end_room:
			available_rooms.append(room)

	if available_rooms.empty():
		print("‚ùå No valid rooms for enemy spawning!")
		return

	for i in range(enemy_count):
		var room = available_rooms[randi() % available_rooms.size()]
		var e = Enemy.instance()
		add_child(e)
		e.global_position = room.global_position

func reveal_fog_around_player():
	var center = FogMap.world_to_map(player.global_position)
	var radius = 20.5  # Slightly over to catch edges better

	for dx in range(-ceil(radius), ceil(radius) + 1):
		for dy in range(-ceil(radius), ceil(radius) + 1):
			var offset = Vector2(dx, dy)
			if offset.length() <= radius:
				var cell = center + offset
				FogMap.set_cellv(cell, -1)

func reveal():
	var center = FogMap.world_to_map(player.global_position)
	var radius = VISION + 0.5  # Add a small buffer
	var radius_squared = radius * radius

	for dx in range(-ceil(radius), ceil(radius) + 1):
		for dy in range(-ceil(radius), ceil(radius) + 1):
			var offset = Vector2(dx, dy)
			if offset.length_squared() <= radius_squared:
				var cell = center + offset
				FogMap.set_cellv(cell, -1)  # Clear fog

				
				
func _physics_process(delta):
    if player == null:
        return
    var current_tile = FogMap.world_to_map(player.global_position)
    if current_tile != last_tile:
        reveal()
        last_tile = current_tile



func _on_Player_moved():
    reveal_fog_around_player()

func _on_ExitButton_pressed():
	get_tree().quit()


func _on_BackButton_pressed():
	get_tree().change_scene("res://MapGallery.tscn")


func _on_BuildButton_pressed():
    print("Calling make_map...")
    make_map()
    
    # Enable PlayButton, disable BuildButton
    get_node("HUD/PlayButton").disabled = false
    get_node("HUD/BuildButton").disabled = true


func _on_PlayButton_pressed():
    if start_room:
        player = Player.instance()
        add_child(player)
        player.position = start_room.position
        play_mode = true
        reveal_fog_around_player()
        game_timer.start()
        print("Game started! Timer running for ", game_timer.wait_time, " seconds.")

        # Disable both buttons
        get_node("HUD/PlayButton").disabled = true
        get_node("HUD/BuildButton").disabled = true

        # Setup music loop
        GameLevelMusic.connect("finished", self, "_on_GameLevelMusic_finished", [], CONNECT_ONESHOT)
        GameLevelMusic.play()


func _on_GameLevelMusic_finished():
    if get_tree().current_scene.name == "Main":
        GameLevelMusic.play()

