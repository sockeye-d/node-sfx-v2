class_name NodeTree extends Resource


class Connection:
	extends RefCounted
	
	var from_node: GraphNode
	var from_port: int
	
	var to_node: GraphNode
	var to_port: int
	
	func _init(_from_node: GraphNode, _from_port: int, _to_node: GraphNode, _to_port: int) -> void:
		from_node = _from_node
		from_port = _from_port
		
		to_node = _to_node
		to_port = _to_port


var nodes: Array[GraphElement]
var connections: Array[Connection]


func _init(graph_edit: GraphEdit) -> void:
	nodes = []
	connections = []
	var name_map: Dictionary = {}
	for child in graph_edit.get_children():
		if child is GraphElement:
			var new_child = child.duplicate()
			name_map[StringName(new_child.name)] = new_child
			nodes.append(new_child)
	
	for connection in graph_edit.get_connection_list():
		connections.append(Connection.new(
				name_map[connection.from_node],
				connection.from_port,
				name_map[connection].to_node,
				connection.to_port
				))


func load_tree(graph_edit: GraphEdit) -> void:
	for child in graph_edit.get_children():
		if child is GraphElement:
			graph_edit.remove_child(child)
	
	for node in nodes:
		if node.get_parent() == null:
			graph_edit.add_child(node)
		else:
			node.reparent(graph_edit)
	
	for connection in connections:
		graph_edit.connect_node(connection.from_node.name, connection.from_port, connection.to_node.name, connection.to_port)
