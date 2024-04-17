@tool
class_name SFXNode extends GraphNode


signal changed


@export var type: String = self.title


func _ready() -> void:
	for child in get_children():
		if child is SliderCombo:
			child.changed_begun.connect(_emit_changed)
			child.set_meta("is_slider_combo", true)


func _emit_changed() -> void:
	changed.emit()


func _emit_changed_arg(v) -> void:
	changed.emit()
