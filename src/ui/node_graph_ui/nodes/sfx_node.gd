@tool
class_name SFXNode extends GraphNode


enum {
	RESIZE_ALLOW_X = 1,
	RESIZE_ALLOW_Y = 2,
}


signal changed
signal connection_requested(from_node: StringName, from_port: int, to_node: StringName, to_port: int)
signal disconnect_requested(port: int)


const NODES_FOLDER = "res://src/ui/node_graph_ui/nodes/"


static var nodes: Dictionary[String, PackedScene]


@export var type: String = self.title
@export_flags("Allow X", "Allow Y") var resize_mode: int = 0:
	set(value):
		resizable = value
		resize_mode = value
	get:
		return resize_mode
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


func serialize() -> Dictionary[String, Variant]:
	var data: Dictionary[String, Variant]
	for child in get_children():
		if child is Range:
			data[child.name] = child.value
		if child is OptionButton:
			data[child.name] = child.selected
	return data


func deserialize(data: Dictionary[String, Variant]) -> void:
	for child in get_children():
		if not child.name in data:
			continue
		if child is Range:
			child.value = data[child.name]
		if child is OptionButton:
			child.selected = data[child.name]


static func load_nodes(folder: String = NODES_FOLDER) -> void:
	folder = folder.trim_suffix("/")
	for child_folder in DirAccess.get_directories_at(folder):
		load_nodes(folder.path_join(child_folder))
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() == "tscn":
			var node_name = file.get_basename().replace("_", " ")
			if node_name.trim_suffix(" node") == node_name:
				continue
			var full_path = folder + "/" + file
			nodes[node_name.trim_suffix(" node")] = load(full_path)


static func create_node(type: String) -> SFXNode:
	if not nodes:
		load_nodes()
	return nodes[type.to_lower()].instantiate() as SFXNode
