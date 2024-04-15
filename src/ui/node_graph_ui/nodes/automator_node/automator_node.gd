class_name AutomatorNode extends SFXNode


# This *has* to be both @export_storage and @onready, otherwise mysterious errors occur
@export_storage @onready var handle_container: Panel = %HandleContainer
@export_storage @onready var remove_button: Button = %RemoveButton
@export_storage @onready var x_slider: SliderCombo = %XSlider
@export_storage @onready var y_slider: SliderCombo = %YSlider
@export_storage @onready var line_display: Line2D = %LineDisplay


@export_storage var normalized_points: PackedVector2Array
@export_storage var points: PackedVector2Array
@export_storage var handles: Array[Handle]
@export_storage var selected_handle: Handle = null
@export_storage var slider_vals: Vector2:
	set(value):
		x_slider.slider_value = value.x
		y_slider.slider_value = value.y
	get:
		return Vector2(x_slider.slider_value, y_slider.slider_value)


func _ready() -> void:
	print(points)
	for child in handle_container.get_children():
		if child is Handle:
			child.queue_free()
	handles.clear()
	
	await handle_container.resized
	
	for point in points:
		var handle = Handle.new()
		handle_container.add_child(handle)
		handles.append(handle)
		
		handle.pressed.connect(_set_selected.bind(handle))
		handle.moved.connect(_on_handle_moved)
		
		handle.position = point
	_update_points()


func _on_add_button_pressed() -> void:
	_emit_changed()
	var new_handle: Handle = Handle.new()
	handles.append(new_handle)
	
	handle_container.add_child(new_handle, true)
	new_handle.pressed.connect(_set_selected.bind(new_handle))
	new_handle.moved.connect(_on_handle_moved)
	
	new_handle.normalized_position = Vector2.ONE * 0.5
	_update_points()


func _set_selected(handle_to_select: Handle) -> void:
	_emit_changed()
	for handle in handles:
		handle.selected = false
	
	handle_to_select.selected = true
	
	selected_handle = handle_to_select
	slider_vals = handle_to_select.normalized_position
	
	remove_button.disabled = handles.size() == 1
	x_slider.editable = true
	y_slider.editable = true


func _on_remove_button_pressed() -> void:
	_emit_changed()
	handles.remove_at(handles.find(selected_handle))
	selected_handle.queue_free()
	selected_handle = null
	_update_points()
	
	remove_button.disabled = handles.size() == 1
	x_slider.editable = false
	y_slider.editable = false


func _on_handle_moved(new_position: Vector2) -> void:
	slider_vals = new_position
	_update_points()


func _on_x_slider_slider_value_changed(v: float) -> void:
	if selected_handle == null:
		return
	selected_handle.normalized_position.x = v
	_update_points()


func _on_y_slider_slider_value_changed(v: float) -> void:
	if selected_handle == null:
		return
	selected_handle.normalized_position.y = v
	_update_points()


func _update_points() -> void:
	if handles:
		points.clear()
		normalized_points.clear()
		for handle in handles:
			points.append(handle.position)
			normalized_points.append(Vector2(handle.normalized_position.x, 1.0 - handle.normalized_position.y))
		points.sort()
		normalized_points.sort()
		
		line_display.clear_points()
		line_display.points = points
		line_display.add_point(Vector2(0, points[0].y), 0)
		line_display.add_point(Vector2(handle_container.size.x, points[-1].y))
