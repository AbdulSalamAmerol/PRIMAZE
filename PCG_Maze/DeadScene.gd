extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	$DeadAudio.play()

func _on_PlayAgainButton_pressed():
	get_tree().change_scene("res://MapGallery.tscn")


func _on_ExitButton_pressed():
	get_tree().quit()
