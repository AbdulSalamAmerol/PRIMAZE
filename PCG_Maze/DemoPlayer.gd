extends KinematicBody2D

onready var sprite = $Sprite
onready var anim_player = $AnimationPlayer
export var min_zoom = 0.5  # Minimum camera zoom level
export var max_zoom = 3.0  # Maximum camera zoom level
export var speed = 300.0
export var acceleration = 20
export var friction = 5

var velocity = Vector2()
onready var camera = $Camera2D

# Define direction vectors for Godot 3.x
const DIR_RIGHT = Vector2(1, 0)
const DIR_LEFT = Vector2(-1, 0)
const DIR_UP = Vector2(0, -1)
const DIR_DOWN = Vector2(0, 1)
const ZERO_VECTOR = Vector2(0,0) # More explicit than just Vector2() sometimes

# Keep track of the current animation state to avoid restarting it every frame
var current_animation_state = "idle_down" # Default animation
var last_direction = DIR_DOWN # Default to facing down

func _input(event):
    if event.is_action_pressed('scroll_up'):
        var current_zoom_value_x = camera.zoom.x
        var current_zoom_value_y = camera.zoom.y
        var new_zoom_x = clamp(current_zoom_value_x - 0.1, min_zoom, max_zoom)
        var new_zoom_y = clamp(current_zoom_value_y - 0.1, min_zoom, max_zoom)
        camera.zoom = Vector2(new_zoom_x, new_zoom_y)

    if event.is_action_pressed('scroll_down'):
        var current_zoom_value_x = camera.zoom.x
        var current_zoom_value_y = camera.zoom.y
        var new_zoom_x = clamp(current_zoom_value_x + 0.1, min_zoom, max_zoom)
        var new_zoom_y = clamp(current_zoom_value_y + 0.1, min_zoom, max_zoom)
        camera.zoom = Vector2(new_zoom_x, new_zoom_y)

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
    if input_vector != ZERO_VECTOR: # Compare with our defined ZERO_VECTOR or Vector2()
        velocity = velocity.linear_interpolate(input_vector * speed, acceleration * get_physics_process_delta_time())
        # Update last_direction only when there is input
        if abs(input_vector.x) > abs(input_vector.y):
            if input_vector.x > 0:
                last_direction = DIR_RIGHT
            else:
                last_direction = DIR_LEFT
        elif abs(input_vector.y) > abs(input_vector.x):
            if input_vector.y > 0:
                last_direction = DIR_DOWN
            else:
                last_direction = DIR_UP
        # If input_vector.x and input_vector.y are equal and non-zero (diagonal)
        # you might want to keep the last_direction or pick one.
        # For simplicity here, we'll let the last dominant axis stick if movement stops.
        # Or if they are equal, you can prioritize one, e.g., horizontal:
        elif input_vector.x != 0: # If y is also non-zero and equal, this prioritizes horizontal
             if input_vector.x > 0:
                last_direction = DIR_RIGHT
             else:
                last_direction = DIR_LEFT
        elif input_vector.y != 0: # Only vertical movement
            if input_vector.y > 0:
                last_direction = DIR_DOWN
            else:
                last_direction = DIR_UP

    else:
        velocity = velocity.linear_interpolate(ZERO_VECTOR, friction * get_physics_process_delta_time())

    return input_vector

func update_animations(): # Removed input_vector as a parameter, it's not directly used here anymore
    var new_anim_state = ""
    # Use a small threshold for velocity magnitude to determine if moving
    # length_squared is more efficient than length as it avoids a square root
    var is_moving = velocity.length_squared() > 25 # Adjust threshold as needed (5*5=25)

    if is_moving:
        if last_direction == DIR_RIGHT:
            new_anim_state = "walk_right"
        elif last_direction == DIR_LEFT:
            new_anim_state = "walk_left"
        elif last_direction == DIR_UP:
            new_anim_state = "walk_up"
        elif last_direction == DIR_DOWN:
            new_anim_state = "walk_down"
    else:
        # When not moving, play the idle animation corresponding to the last direction faced
        if last_direction == DIR_RIGHT:
            new_anim_state = "idle_right"
        elif last_direction == DIR_LEFT:
            new_anim_state = "idle_left"
        elif last_direction == DIR_UP:
            new_anim_state = "idle_up"
        elif last_direction == DIR_DOWN:
            new_anim_state = "idle_down"
        else: # Should not happen if last_direction is always maintained
            new_anim_state = "idle_down"


    # Only change animation if the state has actually changed and is valid
    if new_anim_state != "" and new_anim_state != current_animation_state:
        # Check if the animation exists before trying to play it
        if anim_player.has_animation(new_anim_state):
            current_animation_state = new_anim_state
            anim_player.play(current_animation_state)
        else:
            print("Warning: Animation not found: ", new_anim_state)
    # Special case: if we were walking and now we are not, ensure idle animation is played
    # This handles the transition from any walk animation to its corresponding idle animation
    elif not is_moving and current_animation_state.begins_with("walk_"):
        var idle_version_of_current_walk = current_animation_state.replace("walk_", "idle_")
        if anim_player.has_animation(idle_version_of_current_walk):
            current_animation_state = idle_version_of_current_walk
            anim_player.play(current_animation_state)
        else:
            # Fallback if the specific idle animation doesn't exist (e.g. idle_down)
            current_animation_state = "idle_" + get_direction_string(last_direction)
            if anim_player.has_animation(current_animation_state):
                 anim_player.play(current_animation_state)


# Helper function to convert direction vector to string
func get_direction_string(direction_vector):
    if direction_vector == DIR_RIGHT:
        return "right"
    elif direction_vector == DIR_LEFT:
        return "left"
    elif direction_vector == DIR_UP:
        return "up"
    elif direction_vector == DIR_DOWN:
        return "down"
    return "down" # Default


func _physics_process(delta):
    get_input() # This updates velocity and last_direction
    velocity = move_and_slide(velocity)
    update_animations() # Update animations based on velocity and last_direction