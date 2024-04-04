@tool
class_name TextureToggleButton extends SquareButton


signal state_changed(state: bool)


@export var true_icon: Texture
@export var false_icon: Texture


@export var state: bool:
	set(value):
		icon = true_icon if value else false_icon
		state = value
	get:
		return state


func _ready() -> void:
	pressed.connect(_on_pressed)
	resized.connect(_on_resized)


func _on_pressed() -> void:
	state = not state
	state_changed.emit(state)


func _on_resized() -> void:
	custom_minimum_size.x = size.y
