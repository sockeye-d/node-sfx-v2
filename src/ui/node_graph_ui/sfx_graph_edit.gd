class_name SFXGraphEdit extends GraphEdit


signal paused
signal played
signal rewound
signal stopped
signal connection_changed


var nodes: Dictionary
@export_dir var nodes_folder = "res://src/ui/node_graph_ui/nodes/"
@export var player: AudioStreamPlayer

@onready var internal_hbox: HBoxContainer = get_menu_hbox()
@onready var add_node_window: AddNodeWindow = $AddNodeWindow
@onready var rename_node_window: TextEditPopup = $RenameNodeWindow
@onready var del_node_button: Button = %DeleteNodeButton
@onready var rename_node_button: Button = %RenameNodeButton
@onready var volume_slider: SliderCombo = %VolumeSlider
@onready var rewind_button: Button = %RewindButton
@onready var play_pause_button: TextureToggleButton = %PlayPauseButton
@onready var stop_button: Button = %StopButton
@onready var ui_toggle_button: TextureToggleButton = %UIToggleButton
@onready var ui_layer: Control = $"@Control@2"


var thingy: NodeTree


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
	rename_node_button.pressed.connect(_on_rename_node_button_pressed)
	ui_toggle_button.state_changed.connect(
			func(state): ui_layer.visible = state
			)
	
	_load_nodes()
	


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("save"):
		var nodes: Array[GraphElement] = []
		for child in get_children():
			if child is GraphElement:
				nodes.append(child.duplicate())
		thingy = NodeTree.new(self)
		print("saved")
	if Input.is_action_just_pressed("load"):
		thingy.load_tree(self)
		print("loaded")


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
			self.disconnect_node(con.from_node, con.from_port, con.to_node, con.to_port)
	self.connect_node(from_node, from_port, to_node, to_port)
	connection_changed.emit()


func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	var node: GraphNode = await _add_node((release_position + scroll_offset) / zoom)
	
	if node == null:
		return
	if node.get_input_port_count() > 0:
		self.connect_node(from_node, from_port, node.name, 0)
		connection_changed.emit()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	self.disconnect_node(from_node, from_port, to_node, to_port)
	connection_changed.emit()


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
		self.disconnect_node(disc.from_node, disc.from_port, disc.to_node, disc.to_port)
	
	for node in nodes:
		if node == &"OutputNode":
			continue
		get_node(NodePath(node)).queue_free()
	connection_changed.emit()


func _on_delete_node_button_pressed() -> void:
	var nodes: Array[StringName] = []
	for node in get_children():
		if node is GraphElement:
			if node.selected:
				nodes.append(node.name)
	
	_on_delete_nodes_request(nodes)


func _on_rename_node_button_pressed() -> void:
	var first_name: String = ""
	var selected_nodes: Array[GraphNode] = []
	for node in get_children():
		if node is GraphNode:
			if node.selected:
				selected_nodes.append(node)
	
	if selected_nodes.size() == 0:
		return
	
	first_name = selected_nodes[0].title
	
	rename_node_window.text = first_name
	rename_node_window.show()
	var new_name = await rename_node_window.text_submitted
	
	if new_name == "":
		return
	
	for node in selected_nodes:
		node.title = new_name


func _on_node_selected(_node: Node) -> void:
	del_node_button.disabled = false
	rename_node_button.disabled = false


func _on_node_deselected(_node: Node) -> void:
	del_node_button.disabled = true
	rename_node_button.disabled = true


func _on_connection_from_empty(to_node: StringName, to_port: int, release_position: Vector2) -> void:
	var node: GraphNode = await _add_node((release_position + scroll_offset) / zoom)
	
	if node == null:
		return
	
	self.connect_node(node.name, 0, to_node, to_port)
	connection_changed.emit()


func _change_volume(new_volume: float) -> void:
	player.volume_db = linear_to_db(new_volume / 100.0)


func _on_play_pause_button_state_changed(playing: bool) -> void:
	if playing:
		played.emit()
		stop_button.disabled = false
		rewind_button.disabled = false
	else:
		paused.emit()
		stop_button.disabled = true
		rewind_button.disabled = true


func _on_rewind_button_pressed() -> void:
	rewound.emit()


func _on_stop_button_pressed() -> void:
	stopped.emit()
	play_pause_button.playing = false
	rewind_button.disabled = true
	stop_button.disabled = true


func connect_node(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> Error:
	var node: GraphNode = get_node(NodePath(to_node))
	node.get_child(node.get_input_port_slot(to_port)).editable = false
	return super.connect_node(from_node, from_port, to_node, to_port)


func disconnect_node(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var node: GraphNode = get_node(NodePath(to_node))
	node.get_child(node.get_input_port_slot(to_port)).editable = true
	super.disconnect_node(from_node, from_port, to_node, to_port)
