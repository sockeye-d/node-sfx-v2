class_name Handle extends Control


signal pressed
signal moved(new_position: Vector2)


@export var selected: bool = false:
	set(value):
		if selected and not value:
			modulate -= Color(0.5, 0.5, 0.5)
		elif not selected and value:
			modulate += Color(0.5, 0.5, 0.5)
		selected = value
	get:
		return selected
var normalized_position: Vector2:
	set(value):
		position = value.clamp(Vector2.ZERO, Vector2.ONE) * get_parent_area_size()
	get:
		return position / get_parent_area_size()


const MOUSE_DRAG_NONE = Vector2(-1, -1)


var old_position: Vector2
var mouse_drag_position: Vector2 = MOUSE_DRAG_NONE


func _process(delta: float) -> void:
	if not mouse_drag_position == MOUSE_DRAG_NONE:
		position = old_position + get_parent().get_local_mouse_position() - mouse_drag_position
		position = position.clamp(Vector2.ZERO, get_parent_area_size())
		moved.emit(normalized_position)
	modulate.a = 1.0


func _on_button_mouse_entered() -> void:
	modulate += Color(0.1, 0.1, 0.1)


func _on_button_mouse_exited() -> void:
	modulate -= Color(0.1, 0.1, 0.1)


func _on_button_button_down() -> void:
	modulate += Color(0.2, 0.2, 0.2)
	old_position = position
	mouse_drag_position = get_parent().get_local_mouse_position()
	pressed.emit()


func _on_button_button_up() -> void:
	modulate -= Color(0.2, 0.2, 0.2)
	mouse_drag_position = MOUSE_DRAG_NONE
