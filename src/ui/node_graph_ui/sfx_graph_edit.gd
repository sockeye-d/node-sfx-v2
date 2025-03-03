class_name SFXGraphEdit extends GraphEdit


enum ConnectionLineType {
	CURVE,
	WIRE,
	HORIZONTAL_VERTICAL,
	TRACES,
	STRAIGHT,
}


signal paused
signal played
signal rewound
signal stopped
signal connection_changed


var nodes: Dictionary
@export_dir var nodes_folder = "res://src/ui/node_graph_ui/nodes/"
@export var player: AudioStreamPlayer
@export var connection_line_type: ConnectionLineType = ConnectionLineType.CURVE

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


var undo_ptr: int = 0
## array of the data returned by [member NodeTree.serialize]
var undo_stack: Array[Variant]


func _ready() -> void:
	%AddNodeButton.pressed.connect(_add_node)
	for child in $MenuHBoxControls.get_children():
		$MenuHBoxControls.remove_child(child)
		internal_hbox.add_child(child)
	del_node_button.pressed.connect(_on_delete_node_button_pressed)
	volume_slider.slider_value_changed.connect(_change_volume)
	rename_node_button.pressed.connect(_on_rename_node_button_pressed)
	ui_toggle_button.state_changed.connect(
		func(state): ui_layer.scale = Vector2.ONE if state else Vector2.ZERO
	)
	


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("undo"):
		pop_undo_frame()


func _get_connection_line(from_position: Vector2, to_position: Vector2) -> PackedVector2Array:
	match connection_line_type:
		ConnectionLineType.CURVE:
			return _get_connection_line_curve(from_position, to_position)
		ConnectionLineType.WIRE:
			return _get_connection_line_wire(from_position, to_position)
		ConnectionLineType.HORIZONTAL_VERTICAL:
			return _get_connection_line_hori_vert(from_position, to_position)
		ConnectionLineType.TRACES:
			return _get_connection_line_traces(from_position, to_position)
	return [from_position, to_position]


func _get_connection_line_curve(from_position: Vector2, to_position: Vector2) -> PackedVector2Array:
	var x_diff: float = (to_position.x - from_position.x)
	var cp_offset: float = abs(x_diff * connection_lines_curvature)

	var curve: Curve2D = Curve2D.new()
	
	curve.add_point(from_position);
	curve.set_point_out(0, Vector2(cp_offset, 0));
	curve.add_point(to_position);
	curve.set_point_in(1, Vector2(-cp_offset, 0));

	if connection_lines_curvature > 0:
		return curve.tessellate(5, 2.0);
	else:
		return curve.tessellate(1);


func _get_connection_line_wire(from_position: Vector2, to_position: Vector2) -> PackedVector2Array:
	from_position /= zoom
	to_position /= zoom
	if from_position.x > to_position.x:
		var temp = from_position
		from_position = to_position
		to_position = temp
	
	var curve: Curve2D = Curve2D.new()
	var dist = 300.0
	var drop: float = (dist * dist) / (from_position.distance_to(to_position) + dist)
	
	curve.add_point(from_position, Vector2.ZERO, (to_position - from_position) / 2.0 + Vector2(0, drop))
	curve.add_point(to_position)
	
	var points: PackedVector2Array = []
	for point in curve.tessellate(5, 2):
		points.append(point * zoom)
	
	return points


func _get_connection_line_hori_vert(from_position: Vector2, to_position: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = []
	
	points.append(from_position)
	points.append(Vector2((from_position.x + to_position.x) / 2.0, from_position.y))
	points.append(Vector2((from_position.x + to_position.x) / 2.0, to_position.y))
	points.append(to_position)
	
	return points


func _get_connection_line_traces(from_position: Vector2, to_position: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = []
	var offset = abs(from_position.y - to_position.y) / 2.0
	
	points.append(from_position)
	
	if (from_position.x + to_position.x) / 2.0 - offset > from_position.x:
		points.append(Vector2((from_position.x + to_position.x) / 2.0 - offset, from_position.y))
		points.append(Vector2((from_position.x + to_position.x) / 2.0 + offset, to_position.y))
	
	points.append(to_position)
	
	return points


func get_selected_nodes() -> Array[GraphNode]:
	var nodes: Array[GraphNode] = []
	for child in get_children():
		if child is GraphNode:
			if child.selected:
				nodes.append(child)
	return nodes


func get_graphnodes() -> Array[SFXNode]:
	var nodes: Array[SFXNode] = []
	for child in get_children():
		if child is SFXNode:
			nodes.append(child)
	return nodes


func push_undo_frame() -> void:
	undo_stack.push_back(NodeTree.serialize(self))
	#_print_nodes()


func pop_undo_frame() -> void:
	if undo_stack.size() > 0:
		print("undo frame popped")
		_print_nodes()
		NodeTree.deserialize(self, undo_stack.pop_back())
		_print_nodes()
		connection_changed.emit()


#func redo() -> void:
	#undo_ptr += 1
	#pop_undo_frame()


func add_node(child: Node, push_undo_frame: bool = true) -> void:
	if push_undo_frame:
		push_undo_frame()
	if child is SFXNode:
		child.changed.connect(func(): push_undo_frame())
		child.connection_requested.connect(
			func(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
				connect_node(from_node, from_port, to_node, to_port)
		)
		child.disconnect_requested.connect(func(port: int): _on_node_disconnect_request(port, child))
		child.graph_edit = self
		child.resize_request.connect(
			func(new_size: Vector2i):
				#push_undo_frame()
				#if child is SFXNode:
				if child.resize_mode & SFXNode.RESIZE_ALLOW_X:
					child.size.x = new_size.x
				if child.resize_mode & SFXNode.RESIZE_ALLOW_Y:
					child.size.y = new_size.y
				#else:
					#child.size = new_minsize
		)
		child.resize_end.connect(
			func(new_size: Vector2i) -> void:
				push_undo_frame()
		)
	add_child(child)


func connect_node(from_node: StringName, from_port: int, to_node: StringName, to_port: int, keep_alive := false) -> Error:
	var node: GraphNode = get_node(NodePath(to_node))
	var input = node.get_child(node.get_input_port_slot(to_port))
	if input is SliderCombo:
		input.editable = false
	return super.connect_node(from_node, from_port, to_node, to_port)


func disconnect_node(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var node: GraphNode = get_node(NodePath(to_node))
	var input = node.get_child(node.get_input_port_slot(to_port))
	if input is SliderCombo:
		input.editable = true
	super.disconnect_node(from_node, from_port, to_node, to_port)


func _add_node(new_node_offset: Vector2 = (scroll_offset + size / 2.0) / zoom) -> SFXNode:
	add_node_window.popup()
	var selected: String = await add_node_window.item_selected_or_canceled
	
	if selected == "":
		return null
	var node: SFXNode = SFXNode.create_node(selected)
	node.position_offset = new_node_offset
	
	add_node(node, true)
	
	return node


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	for con in get_connection_list():
		if con.to_node == to_node and con.to_port == to_port:
			self.disconnect_node(con.from_node, con.from_port, con.to_node, con.to_port)
	
	push_undo_frame()
	self.connect_node(from_node, from_port, to_node, to_port)
	connection_changed.emit()


func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	var node: GraphNode = await _add_node((release_position + scroll_offset) / zoom)
	
	if node == null:
		return
	
	push_undo_frame()
	
	if node.get_input_port_count() > 0:
		self.connect_node(from_node, from_port, node.name, 0)
		connection_changed.emit()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	push_undo_frame()
	self.disconnect_node(from_node, from_port, to_node, to_port)
	connection_changed.emit()


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	push_undo_frame()
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
	
	push_undo_frame()
	
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
	connection_changed.emit()


func _on_stop_button_pressed() -> void:
	stopped.emit()
	play_pause_button.state = false
	rewind_button.disabled = true
	stop_button.disabled = true


func _on_begin_node_move() -> void:
	push_undo_frame()


func _on_duplicate_nodes_request() -> void:
	var selected_nodes = get_selected_nodes()
	
	for node in selected_nodes:
		add_node(node.duplicate())
		node.selected = false


func _on_node_disconnect_request(port: int, node: SFXNode) -> void:
	for connection in connections:
		if connection.to_node == node.name:
			disconnect_node(connection.from_node, connection.from_port, node.name, port)


func _print_nodes() -> void:
	for child in get_children():
		if child is SFXNode:
			print(child.title)
			for control in child.get_children():
				if control is SliderCombo:
					print("\t%s = %s" % [control.name, control.slider_value])
