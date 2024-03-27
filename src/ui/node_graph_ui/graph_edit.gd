extends GraphEdit


var nodes: Dictionary
@export_dir var nodes_folder = "res://src/ui/node_graph_ui/nodes/"

@onready var internal_hbox: HBoxContainer = get_menu_hbox()
@onready var add_node_window: AddNodeWindow = $AddNodeWindow


func _ready() -> void:
	%AddNodeButton.pressed.connect(_add_node)
	for child in $MenuHBoxControls.get_children():
		$MenuHBoxControls.remove_child(child)
		internal_hbox.add_child(child)
	
	_load_nodes()


func _load_nodes(folder: String = nodes_folder) -> void:
	folder = folder.trim_suffix("/")
	for child_folder in DirAccess.get_directories_at(folder):
		_load_nodes(folder + "/" + child_folder)
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() == "tscn":
			var node_name = file.get_basename().replace("_", " ")
			if node_name.trim_suffix(" node") == node_name:
				continue
			var full_path = folder + "/" + file
			nodes[node_name.trim_suffix(" node")] = load(full_path)
			print("loaded %s" % node_name)


func _add_node(new_node_offset: Vector2 = Vector2.ZERO) -> GraphNode:
	add_node_window.show()
	var selected: String = await add_node_window.item_selected_or_canceled
	
	if selected == "":
		return null
	var node: GraphNode = nodes[selected.to_lower()].instantiate()
	node.position_offset = new_node_offset
	
	add_child(node)
	
	return node


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	connect_node(from_node, from_port, to_node, to_port)


func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	var node: GraphNode = await _add_node((release_position + scroll_offset) / zoom)
	
	if node == null:
		return
	
	connect_node(from_node, from_port, node.name, 0)


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	disconnect_node(from_node, from_port, to_node, to_port)


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	#TODO: implement :)
	pass
