@tool
class_name SFXNode extends GraphNode


signal changed
signal connection_requested(from_node: StringName, from_port: int, to_node: StringName, to_port: int)
signal disconnect_requested(port: int)


@export var type: String = self.title
var graph_edit: GraphEdit


func _ready() -> void:
	for child in get_children():
		if child is SliderCombo:
			child.changed_begun.connect(_emit_changed)
			child.set_meta("is_slider_combo", true)


func _emit_changed() -> void:
	changed.emit()


func _emit_changed_arg(v) -> void:
	changed.emit()


## Returns the corresponding port index of the input port with the given slot_idx.
func get_input_slot_port(slot_idx: int) -> int:
	var port = 0
	# Loop over the slots before slot_idx. If it's enabled that means it's also a port
	for i in slot_idx:
		if is_slot_enabled_left(i):
			port += 1
	return port


func get_input_connections() -> Array[Dictionary]:
	var connections: Array[Dictionary] = []
	for connection in graph_edit.get_connection_list():
		if connection.to_node == name:
			connections.append(connection)
	return connections


func get_output_connections() -> Array[Dictionary]:
	var connections: Array[Dictionary] = []
	for connection in graph_edit.get_connection_list():
		if connection.from_node == name:
			connections.append(connection)
	return connections
