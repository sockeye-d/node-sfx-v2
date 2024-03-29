extends GraphEdit


signal auto_refresh_changed(state: bool)
signal refresh


var nodes: Dictionary
@export_dir var nodes_folder = "res://src/ui/node_graph_ui/nodes/"
@export var player: AudioStreamPlayer

@onready var internal_hbox: HBoxContainer = get_menu_hbox()
@onready var add_node_window: AddNodeWindow = $AddNodeWindow
@onready var del_node_button: Button = %DeleteNodeButton
@onready var volume_slider: SliderCombo = %VolumeSlider


var connections: Array[Dictionary]:
	get:
		return get_connection_list()


func _ready() -> void:
	%AddNodeButton.pressed.connect(_add_node)
	for child in $MenuHBoxControls.get_children():
		$MenuHBoxControls.remove_child(child)
		internal_hbox.add_child(child)
	del_node_button.pressed.connect(_on_delete_node_button_pressed)
	volume_slider.slider_value_changed.connect(_change_volume)
	
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


func _add_node(new_node_offset: Vector2 = (scroll_offset + size / 2.0) / zoom) -> GraphNode:
	add_node_window.show()
	var selected: String = await add_node_window.item_selected_or_canceled
	
	if selected == "":
		return null
	var node: GraphNode = nodes[selected.to_lower()].instantiate()
	node.position_offset = new_node_offset
	
	add_child(node, true)
	
	return node


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	for con in get_connection_list():
		if con.to_node == to_node and con.to_port == to_port:
			disconnect_node(con.from_node, con.from_port, con.to_node, con.to_port)
	connect_node(from_node, from_port, to_node, to_port)


func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	var node: GraphNode = await _add_node((release_position + scroll_offset) / zoom)
	
	if node == null:
		return
	
	connect_node(from_node, from_port, node.name, 0)


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	disconnect_node(from_node, from_port, to_node, to_port)


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	var disconnections: Array[Dictionary] = []
	var connections = get_connection_list()
	for node in nodes:
		if node == &"OutputNode":
			continue
	
		for con in connections:
			if con.to_node == node or con.from_node == node:
				disconnections.append(con)
	
	for disc in disconnections:
		disconnect_node(disc.from_node, disc.from_port, disc.to_node, disc.to_port)
	
	for node in nodes:
		if node == &"OutputNode":
			continue
		get_node(NodePath(node)).queue_free()


func _on_delete_node_button_pressed() -> void:
	var nodes: Array[StringName] = []
	for node in get_children():
		if node is GraphElement:
			if node.selected:
				nodes.append(node.name)
	
	_on_delete_nodes_request(nodes)


func _on_node_selected(node: Node) -> void:
	del_node_button.disabled = false


func _on_node_deselected(node: Node) -> void:
	del_node_button.disabled = true


func _on_connection_from_empty(to_node: StringName, to_port: int, release_position: Vector2) -> void:
	var node: GraphNode = await _add_node((release_position + scroll_offset) / zoom)
	
	if node == null:
		return
	
	connect_node(node.name, 0, to_node, to_port)


func _change_volume(new_volume: float) -> void:
	player.volume_db = linear_to_db(new_volume / 100.0)


func _on_update_tree_toggle_toggled(toggled_on: bool) -> void:
	auto_refresh_changed.emit(toggled_on)


func _on_force_refresh_tree_pressed() -> void:
	refresh.emit()
