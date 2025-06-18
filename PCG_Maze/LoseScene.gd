extends Control

func _ready():
	$LoseSceneAudio.play()

func _on_PlayAgainButton_pressed():
	get_tree().change_scene("res://MapGallery.tscn")

func _on_ExitButton_pressed():
	get_tree().quit()
