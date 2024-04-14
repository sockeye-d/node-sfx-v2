@tool
class_name TextEditPopup extends Window


signal text_submitted(text: String)


@onready var line_edit: LineEdit = %LineEdit
@onready var add_button: Button = %AddButton
@onready var cancel_button: Button = %CancelButton


@export var button_text: String:
	set(value):
		if add_button == null:
			return
		
		add_button.text = value
	get:
		if add_button == null:
			return ""
		
		return add_button.text
@export var text: String:
	set(value):
		if line_edit == null:
			return
		
		line_edit.text = value
	get:
		if line_edit == null:
			return ""
		
		return line_edit.text


func _ready() -> void:
	line_edit.text_changed.connect(_on_line_edit_text_changed)
	line_edit.text_submitted.connect(_on_line_edit_text_submitted)
	
	add_button.pressed.connect(_on_add_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)


func _on_line_edit_text_changed(new_text: String) -> void:
	add_button.disabled = new_text == ""


func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text == "":
		return
	
	text_submitted.emit(new_text)
	hide()


func _on_add_button_pressed() -> void:
	text_submitted.emit(line_edit.text)
	hide()


func _on_cancel_button_pressed() -> void:
	text_submitted.emit("")
	hide()


func _on_visibility_changed() -> void:
	if visible and line_edit:
		line_edit.grab_focus()
