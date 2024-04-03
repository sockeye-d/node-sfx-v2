class_name SquareButton extends Button


func _ready() -> void:
	resized.connect(_on_resized)


func _on_resized() -> void:
	custom_minimum_size.x = size.y
