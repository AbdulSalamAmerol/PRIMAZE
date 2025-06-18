extends Control

onready var ButtonClickSound = $ButtonClickSound

func _ready():
    update_all_labels()

func _on_NumRoomsHSlider_value_changed(value):
	$VBoxContainer/NumRoomsRow/NumRoomsCurrentValue.text = str(value)
	ButtonClickSound.play()

func _on_MinRoomSizeHSlider_value_changed(value):
	$VBoxContainer/MinRoomSizeRow/MinRoomSizeCurrentValue.text = str(value)
	ButtonClickSound.play()
	
func _on_MaxRoomSizeHSlider_value_changed(value):
	$VBoxContainer/MaxRoomSizeRow/MaxRoomSizeCurrentValue.text = str(value)
	ButtonClickSound.play()
	
func _on_HSpreadHSlider_value_changed(value):
	$VBoxContainer/HSpreadRow/HSpreadCurrentValue.text = str(value)
	ButtonClickSound.play()

func _on_CullHSlider_value_changed(value):
	$VBoxContainer/CullRow/CullCurrentValue.text = str(value)
	ButtonClickSound.play()

func update_all_labels():
    _on_NumRoomsHSlider_value_changed($VBoxContainer/NumRoomsRow/NumRoomsHSlider.value)
    _on_MinRoomSizeHSlider_value_changed($VBoxContainer/MinRoomSizeRow/MinRoomSizeHSlider.value)
    _on_MaxRoomSizeHSlider_value_changed($VBoxContainer/MaxRoomSizeRow/MaxRoomSizeHSlider.value)
    _on_HSpreadHSlider_value_changed($VBoxContainer/HSpreadRow/HSpreadHSlider.value)
    _on_CullHSlider_value_changed($VBoxContainer/CullRow/CullHSlider.value)
	


func _on_StartButton_pressed():
	var main_scene = preload("res://Main.tscn").instance()


    # Pass the slider values
	main_scene.num_rooms = int($VBoxContainer/NumRoomsRow/NumRoomsHSlider.value)
	main_scene.min_size = int($VBoxContainer/MinRoomSizeRow/MinRoomSizeHSlider.value)
	main_scene.max_size = int($VBoxContainer/MaxRoomSizeRow/MaxRoomSizeHSlider.value)
	main_scene.hspread = int($VBoxContainer/HSpreadRow/HSpreadHSlider.value)
	main_scene.cull = $VBoxContainer/CullRow/CullHSlider.value

	get_tree().get_root().add_child(main_scene)
	get_tree().current_scene.queue_free()
	get_tree().set_current_scene(main_scene)


func _on_ExitButton_pressed():

	get_tree().quit() 
