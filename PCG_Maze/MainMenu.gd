extends Control

func _ready():
    OS.window_maximized = true
    $VBoxContainer/PlayButton.grab_focus()

func _on_PlayButton_pressed():
    # Load the game scene (replace "GameScene.tscn" with your actual game scene file)
    get_tree().change_scene("res://MapGallery.tscn")

func _on_ExitButton_pressed():
    # Quit the game
    get_tree().quit()
