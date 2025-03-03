@tool
class_name OscilloscopeNode extends SFXNode


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	$Surface.queue_redraw()
