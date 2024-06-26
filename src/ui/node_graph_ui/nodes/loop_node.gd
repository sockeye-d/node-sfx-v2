class_name LoopNode extends SFXNode


static var delete_icon: Texture2D = preload("res://src/assets/icons/delete.png")


func _create_input():
	var vbox = VBoxContainer.new()
	vbox.set_meta("is_input", true)
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBoxContainer"
	
	var timer = Timer.new()
	timer.wait_time = 0.3
	timer.one_shot = true
	
	var line_edit = LineEdit.new()
	line_edit.name = "InputName"
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = "Input name"
	line_edit.context_menu_enabled = false
	line_edit.select_all_on_focus = true
	line_edit.text_changed.connect(func(text): _on_line_edit_text_changed(line_edit, timer))
	
	var button = Button.new()
	button.icon = delete_icon
	button.flat = true
	button.pressed.connect(delete_input.bind(vbox))
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	
	var slider_combo = SliderCombo.new()
	slider_combo.name = "DefaultValueInput"
	slider_combo.prefix = "Default value: "
	slider_combo.changed_begun.connect(_emit_changed)
	
	vbox.add_child(hbox, true)
	vbox.add_child(slider_combo, true)
	hbox.add_child(line_edit, true)
	line_edit.add_child(timer)
	hbox.add_child(button)
	
	add_child(vbox)
	
	set_slot_enabled_left(vbox.get_index(), true)


func _on_add_input_button_pressed() -> void:
	_emit_changed()
	_create_input.call_deferred()


func delete_input(container: Node) -> void:
	_emit_changed()
	
	# Get all the incoming connections *before* disconnecting them temporarily
	var incoming_connections: Array[Dictionary] = get_input_connections()
	var port_disconnected = get_input_slot_port(container.get_index())
	for port in range(port_disconnected, get_input_port_count()):
		disconnect_requested.emit(port)
	
	for connection in incoming_connections:
		if connection.to_port > port_disconnected:
			connection_requested.emit(
					connection.from_node,
					connection.from_port,
					connection.to_node,
					connection.to_port - 1,
					)
	
	
	remove_child(container)
	container.queue_free()
	(func(): size.y = 0.0).call_deferred()


func _on_line_edit_text_changed(line_edit: LineEdit, timer: Timer) -> void:
	if timer.is_stopped():
		_emit_changed()
		timer.start()
		print("h")
