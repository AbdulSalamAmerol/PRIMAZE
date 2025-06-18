# ADDED ZOOM LEVEL
extends KinematicBody2D

export var id = 0
export var speed = 250
export var acceleration = 20
export var friction = 5
export var min_zoom = 0.5  # Minimum camera zoom level
export var max_zoom = 3.0  # Maximum camera zoom level

var velocity = Vector2()
onready var camera = $Camera2D

func _input(event):
    if event.is_action_pressed('scroll_up'):
        var new_zoom = camera.zoom - Vector2(0.1, 0.1)
        new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
        new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
        camera.zoom = new_zoom

    if event.is_action_pressed('scroll_down'):
        var new_zoom = camera.zoom + Vector2(0.1, 0.1)
        new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
        new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
        camera.zoom = new_zoom

func get_input():
    var input_vector = Vector2()
    
    if Input.is_action_pressed('ui_right'):
        input_vector.x += 1
    if Input.is_action_pressed('ui_left'):
        input_vector.x -= 1
    if Input.is_action_pressed('ui_up'):
        input_vector.y -= 1
    if Input.is_action_pressed('ui_down'):
        input_vector.y += 1
    
    input_vector = input_vector.normalized()
    
    # Apply acceleration and friction for smooth movement
    if input_vector != Vector2():
        velocity = velocity.linear_interpolate(input_vector * speed, acceleration * get_physics_process_delta_time())
    else:
        velocity = velocity.linear_interpolate(Vector2(), friction * get_physics_process_delta_time())

func _physics_process(delta):
    get_input()
    velocity = move_and_slide(velocity)
