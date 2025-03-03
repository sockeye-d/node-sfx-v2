class_name NodeTree
## Provides an easy way to serialize the SFXGraphEdit to JSON-compatible format


static func serialize(graph_edit: SFXGraphEdit) -> Variant:
	var d: Variant = {
		"nodes": [],
		"connections": [],
	}
	
	var node_names: Dictionary[StringName, int]
	
	var unique_id := 0
	for node in graph_edit.get_graphnodes():
		d.nodes.append({
			"position": node.position_offset,
			"size": node.size,
			"type": node.type,
			"id": unique_id,
			"properties": node.serialize(),
		})
		
		node_names[node.name] = unique_id
		
		# very unique
		unique_id += 1
	
	for connection in graph_edit.connections:
		# add the node IDs generated before to be more robust
		d.connections.append(connection.merged({
			"from_node_id": node_names[connection.from_node],
			"to_node_id": node_names[connection.to_node],
		}))
	
	return d


static func deserialize(graph_edit: SFXGraphEdit, data: Variant) -> void:
	graph_edit.clear_connections()
	for child in graph_edit.get_children():
		if child is GraphElement:
			graph_edit.remove_child(child)
	
	var node_names: Dictionary[int, StringName]
	for node_data in data.nodes:
		var node := SFXNode.create_node(node_data.type)
		node.position_offset = node_data.position
		node.size = node_data.size
		node.deserialize(node_data.properties)
		
		graph_edit.add_node(node, false)
		
		node_names[node_data.id] = node.name
	
	for connection in data.connections:
		graph_edit.connect_node(
			node_names[connection.from_node_id],
			connection.from_port,
			node_names[connection.to_node_id],
			connection.to_port,
		)
