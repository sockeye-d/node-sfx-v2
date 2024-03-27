class_name NodeItem extends Resource


@export var name: String = ""
@export var children: Array[NodeItem] = []
var is_category: bool:
	get:
		return children.size() > 0


func _init() -> void:
	name = ""
	children = []
