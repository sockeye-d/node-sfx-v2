class_name NodeItem extends Resource


@export var name: String = ""
@export_multiline var description: String = name
@export var children: Array[NodeItem] = []
var is_category: bool:
	get:
		return children.size() > 0


func _init() -> void:
	name = ""
	children = []
