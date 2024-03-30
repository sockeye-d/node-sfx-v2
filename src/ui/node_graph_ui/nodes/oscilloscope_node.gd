class_name OscilloscopeNode extends SFXNode


func _physics_process(delta: float) -> void:
	$Surface.queue_redraw()
