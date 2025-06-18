extends Control

func _ready():
    update_all_labels()

func _on_TileSizeHSlider_value_changed(value):
    $VBoxContainer/TileSizeRow/TileSizeCurrentValue.text = str(value)

func _on_NumRoomsHSlider_value_changed(value):
    $VBoxContainer/NumRoomsRow/NumRoomsCurrentValue.text = str(value)

func _on_MinRoomSizeHSlider_value_changed(value):
    $VBoxContainer/MinRoomSizeRow/MinRoomSizeCurrentValue.text = str(value)

func _on_MaxRoomSizeHSlider_value_changed(value):
    $VBoxContainer/MaxRoomSizeRow/MaxRoomSizeCurrentValue.text = str(value)

func _on_HSpreadHSlider_value_changed(value):
    $VBoxContainer/HSpreadRow/HSpreadCurrentValue.text = str(value)

func _on_CullHSlider_value_changed(value):
    $VBoxContainer/CullRow/CullCurrentValue.text = str(value)

func update_all_labels():
    _on_TileSizeHSlider_value_changed($VBoxContainer/TileSizeRow/TileSizeHSlider.value)
    _on_NumRoomsHSlider_value_changed($VBoxContainer/NumRoomsRow/NumRoomsHSlider.value)
    _on_MinRoomSizeHSlider_value_changed($VBoxContainer/MinRoomSizeRow/MinRoomSizeHSlider.value)
    _on_MaxRoomSizeHSlider_value_changed($VBoxContainer/MaxRoomSizeRow/MaxRoomSizeHSlider.value)
    _on_HSpreadHSlider_value_changed($VBoxContainer/HSpreadRow/HSpreadHSlider.value)
    _on_CullHSlider_value_changed($VBoxContainer/CullRow/CullHSlider.value)
