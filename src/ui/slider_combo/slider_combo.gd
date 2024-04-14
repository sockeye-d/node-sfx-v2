@tool
class_name SliderCombo extends Range


signal slider_value_changed(v: float)
signal slider_value_changed_without_set(v: float)
signal changed_begun()


enum DraggingStates {
	NONE,
	CLICKED,
	DRAGGING,
}


@export var prefix: String = "":
	set(v):
		line_edit.text = prefix + str(slider_value)
		prefix = v
	get:
		return prefix
@export var mouse_draggable: bool = true
@export var mouse_threshold: float = 3
@export var mouse_drag_scale: float = 0.001
@export var editable: bool = true:
	set(v):
		line_edit.editable = v
		slider.editable = v
		editable = v
	get:
		return editable

@export var slider_visible: bool = true:
	set(v):
		slider.visible = v
		slider_visible = v
		_resize()
	get:
		return slider_visible
@export var slider_value: float:
	set(v):
		v = _constrain(v)
		slider.value = v
		line_edit.text = "%s%.*f" % [prefix, max(ceil(log(1.0 / step) / log(10.0)), 0.0), v]
		slider_value_changed.emit(v)
		slider_value = v
		set_value_no_signal(v)
	get:
		return slider_value


var line_edit: LineEdit
var slider: Slider
var outer_container: PanelContainer
var margin_container: MarginContainer
var container: VBoxContainer
var _old_slider_visible: bool

var dragging_state: DraggingStates = DraggingStates.NONE
var drag_mouse_pos: Vector2


func _init() -> void:
	if outer_container == null:
		outer_container = PanelContainer.new()
		outer_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(outer_container)
	else:
		remove_child(outer_container)
		outer_container = outer_container.duplicate()
		add_child(outer_container)
	
	if margin_container == null:
		margin_container = MarginContainer.new()
		margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin_container.add_theme_constant_override("margin_left",   4)
		margin_container.add_theme_constant_override("margin_right",  4)
		margin_container.add_theme_constant_override("margin_top",    4)
		margin_container.add_theme_constant_override("margin_bottom", 4)
		outer_container.add_child(margin_container)
	
	if container == null:
		container = VBoxContainer.new()
		container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		container.resized.connect(_resize)
		container.add_theme_constant_override("separation", 0)
		
		margin_container.add_child(container)
	
	if line_edit == null:
		line_edit = LineEdit.new()
		line_edit.size_flags_horizontal = Control.SIZE_FILL
		line_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
		line_edit.text_submitted.connect(_on_text_submitted)
		line_edit.gui_input.connect(_on_line_edit_input)
		line_edit.flat = true
		line_edit.context_menu_enabled = false
		line_edit.caret_blink = true
		line_edit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		container.add_child(line_edit)
	
	if slider == null:
		slider = HSlider.new()
		slider.value_changed.connect(_on_value_changed)
		slider.drag_started.connect(func(): changed_begun.emit())
		slider.min_value = min_value
		slider.max_value = max_value
		slider.step = step
		container.add_child(slider)
	
	if not value_changed.is_connected(_on_value_changed):
		value_changed.connect(_on_value_changed)
	
	if not changed.is_connected(_on_changed):
		changed.connect(_on_changed)
	
	slider_value = value


func _ready() -> void:
	line_edit.text = "%s%.*f" % [prefix, max(ceil(log(1.0 / step) / log(10.0)), 0.0), slider_value]


func _on_changed() -> void:
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step


func _on_text_submitted(new_text: String) -> void:
	var val = new_text.trim_prefix(prefix).to_float()
	
	val = _constrain(val)
	
	line_edit.release_focus()
	changed_begun.emit()
	slider_value = val


func _on_line_edit_focus_exited() -> void:
	var val = line_edit.text.trim_prefix(prefix).to_float()
	
	val = _constrain(val)
	
	slider_value = val
	changed_begun.emit()


func _on_value_changed(v: float) -> void:
	slider_value = v
	slider_value_changed_without_set.emit(slider_value)


func _on_line_edit_input(event: InputEvent) -> void:
	if not editable:
		return
	if mouse_draggable:
		if event is InputEventMouseButton:
			var e = event as InputEventMouseButton
			
			if e.pressed:
				dragging_state = DraggingStates.CLICKED
				drag_mouse_pos = e.global_position
			
			if not e.pressed and dragging_state == DraggingStates.DRAGGING:
				dragging_state = DraggingStates.NONE
				line_edit.editable = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				Input.warp_mouse(drag_mouse_pos)
		
		if event is InputEventMouseMotion:
			var e = event as InputEventMouseMotion
			
			if e.button_mask & MOUSE_BUTTON_MASK_LEFT and abs(e.global_position.x - drag_mouse_pos.x) > mouse_threshold and dragging_state == DraggingStates.CLICKED:
				dragging_state = DraggingStates.DRAGGING
				drag_mouse_pos = e.global_position
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				line_edit.editable = false
				changed_begun.emit()
			
			if dragging_state == DraggingStates.DRAGGING:
				slider_value += e.relative.x * mouse_drag_scale * (max_value - min_value)
				slider_value_changed_without_set.emit(slider_value)


func _resize() -> void:
	custom_minimum_size.y = outer_container.get_minimum_size().y


func _constrain(v: float) -> float:
	if not allow_lesser:
		v = maxf(v, min_value)
	if not allow_greater:
		v = minf(v, max_value)
	return snappedf(v, step)


func _value_changed(new_value: float) -> void:
	slider_value = _constrain(new_value)
	slider_value_changed_without_set.emit(slider_value)
