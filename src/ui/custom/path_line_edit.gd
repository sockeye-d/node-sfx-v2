@tool
class_name PathLineEdit extends HBoxContainer


static var folder_icon: Texture2D = preload("res://src/assets/icons/folder.png")


@export var file_mode: FileDialog.FileMode = FileDialog.FILE_MODE_OPEN_FILE:
	set(value):
		file_mode = value
		if file_dialog:
			file_dialog.file_mode = file_mode
	get:
		return file_mode
@export var path: String = "":
	set(value):
		path = value
		if line_edit:
			line_edit.text = path
	get:
		return path
@export var placeholder_text: String = "":
	set(value):
		placeholder_text = value
		if line_edit:
			line_edit.placeholder_text = placeholder_text
	get:
		return placeholder_text
@export var filters: PackedStringArray:
	set(value):
		filters = value
		if file_dialog:
			file_dialog.filters = filters
	get:
		return filters


var line_edit: LineEdit
var button: Button
var file_dialog: FileDialog


func _init() -> void:
	if not line_edit:
		line_edit = LineEdit.new()
		line_edit.text = path
		line_edit.placeholder_text = placeholder_text
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(line_edit)
	
	if not button:
		button = Button.new()
		button.icon = folder_icon
		button.pressed.connect(_on_button_pressed)
		add_child(button)
	
	if not file_dialog:
		file_dialog = FileDialog.new()
		file_dialog.filters = filters
		file_dialog.file_mode = file_mode
		file_dialog.use_native_dialog = true
		file_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_KEYBOARD_FOCUS
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.dir_selected.connect(func(dir: String): path = dir)
		file_dialog.file_selected.connect(func(_path: String): path = _path)
		file_dialog.files_selected.connect(func(paths: String): path = paths[0])
		add_child(file_dialog)
	


func _on_button_pressed() -> void:
	file_dialog.show()
