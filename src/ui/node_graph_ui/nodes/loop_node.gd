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
	_create_input()


func delete_input(container: Node) -> void:
	_emit_changed()
	#var index = container.get_index()
	#for i in range(index, get_child_count()):
		#pass
	container.queue_free()


func _on_line_edit_text_changed(line_edit: LineEdit, timer: Timer) -> void:
	if timer.is_stopped():
		_emit_changed()
		timer.start()
		print("h")
