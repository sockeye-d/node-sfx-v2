class_name NodeTree extends Resource


var nodes: Array[GraphElement]
var connections: Array[Dictionary]


func _init(_nodes: Array[GraphElement], _connections: Array[Dictionary]) -> void:
	nodes = _nodes
	connections = _connections


func load_tree(graph_edit: GraphEdit) -> void:
	for child in graph_edit.get_children():
		if child is GraphElement:
			child.queue_free()
	
	for node in nodes:
		graph_edit.add_child(node)
	
	for connection in connections:
		graph_edit.connect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)
