@tool
class_name AutomatorNode extends GraphNode


@export var type: String = self.title


@onready var handle_container: Panel = %HandleContainer
@onready var remove_button: Button = %RemoveButton
@onready var x_slider: SliderCombo = %XSlider
@onready var y_slider: SliderCombo = %YSlider
@onready var line_display: Line2D = %LineDisplay


var points: PackedVector2Array
var handle_scene: PackedScene = preload("./handle.tscn")
var handles: Array[Handle]
var selected_handle: Handle = null
var slider_vals: Vector2:
	set(value):
		x_slider.slider_value = value.x
		y_slider.slider_value = value.y
	get:
		return Vector2(x_slider.slider_value, y_slider.slider_value)


func _ready() -> void:
	_on_add_button_pressed()
	await handle_container.resized
	_update_points()


func _process(delta: float) -> void:
	remove_button.disabled = selected_handle == null or handles.size() == 1
	x_slider.editable = not selected_handle == null
	y_slider.editable = not selected_handle == null


func _on_add_button_pressed() -> void:
	var new_handle: Handle = handle_scene.instantiate()
	handles.append(new_handle)
	
	handle_container.add_child(new_handle)
	new_handle.pressed.connect(_set_selected.bind(new_handle))
	new_handle.moved.connect(_on_handle_moved)
	
	new_handle.normalized_position = Vector2.ONE * 0.5
	_update_points()


func _set_selected(handle_to_select: Handle) -> void:
	for handle in handles:
		handle.selected = false
	
	handle_to_select.selected = true
	
	selected_handle = handle_to_select
	slider_vals = handle_to_select.normalized_position


func _on_remove_button_pressed() -> void:
	handles.remove_at(handles.find(selected_handle))
	selected_handle.queue_free()
	selected_handle = null
	_update_points()


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
	points.clear()
	for handle in handles:
		points.append(handle.position)
	points.sort()
	
	line_display.clear_points()
	line_display.points = points
	line_display.add_point(Vector2(0, points[0].y), 0)
	line_display.add_point(Vector2(handle_container.size.x, points[-1].y))
