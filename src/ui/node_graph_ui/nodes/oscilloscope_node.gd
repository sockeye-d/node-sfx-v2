class_name OscilloscopeNode extends SFXNode


func _process(delta: float) -> void:
	$Surface.queue_redraw()
