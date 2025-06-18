extends KinematicBody2D

export var speed = 120
export var detection_range = 300
var player = null

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	if not player:
		player = get_tree().get_root().find_node("Player", true, false)
		if player:
			print("âœ… Player found: ", player.name)
		else:
			return

	var distance = global_position.distance_to(player.global_position)
	
	if distance < detection_range:
		print("Distance to player:", distance)
		print("Player detected! Moving...")
		var direction = (player.global_position - global_position).normalized()
		move_and_slide(direction * speed)

		if distance < 45:
			print("í ½í²€ Player caught!")
			player.queue_free()
			call_deferred("_on_player_caught")

func _on_player_caught():
	get_tree().change_scene("res://DeadScene.tscn")
