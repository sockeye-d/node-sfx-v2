@tool
class_name AddNodeWindow extends Window


signal item_selected_or_canceled(item: String)


@export var populate_tree_action: bool = false:
	set(value):
		populate_tree_action = false
		populate_tree.call_deferred()
@export var items: NodeItem:
	set(value):
		items = value
		populate_tree.call_deferred()
	get:
		return items
var string_items: Array[WeightedText] = []
var item_descriptions: Dictionary = {}


@onready var description_container: Container = %DescriptionContainer
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var search_box: LineEdit = %SearchBox
@onready var tree: Tree = %ItemsTree
@onready var add_button: Button = %AddButton
@onready var cancel_button: Button = %CancelButton
@onready var items_list: ItemList = %ItemsList


func _ready() -> void:
	populate_tree()
	item_selected_or_canceled.connect(
			func(item):
				hide()
				)
	#tree.get_root().set_collapsed_recursive.call_deferred(false)


func _process(delta: float) -> void:
	if add_button:
		description_container.visible = not add_button.disabled


func populate_tree() -> void:
	if tree == null:
		return
	items_list.clear()
	string_items.clear()
	item_descriptions.clear()
	tree.clear()
	_create_item_from_content(null, items)


func _create_item_from_content(parent: TreeItem, content: NodeItem) -> void:
	var item: TreeItem = tree.create_item(parent)
	item.set_text(0, content.name)
	if content.children.size() > 0:
		item.set_selectable(0, false)
		for i in content.children:
			_create_item_from_content(item, i)
	else:
		item.set_tooltip_text(0, " ")
		string_items.append(WeightedText.new(0.0, content.name))
		item_descriptions[content.name] = content.description
		items_list.add_item(content.name)


func _is_item_visible(item: TreeItem) -> bool:
	if item.get_parent() == null:
		return item.visible and not (item.collapsed and item.get_child_count() > 0)
	return item.visible and not (item.collapsed and item.get_child_count() > 0) and _is_item_visible(item.get_parent())


func _on_items_tree_item_activated() -> void:
	item_selected_or_canceled.emit(tree.get_selected().get_text(0))


func _on_button_pressed() -> void:
	if tree.visible:
		item_selected_or_canceled.emit(tree.get_selected().get_text(0))
	else:
		item_selected_or_canceled.emit(items_list.get_item_text(items_list.get_selected_items()[0]))


func _on_close_requested() -> void:
	item_selected_or_canceled.emit("")


func _on_search_box_text_changed(new_text: String) -> void:
	if new_text:
		if not items_list.visible:
			add_button.disabled = false
		
		tree.hide()
		items_list.show()
	else:
		if not tree.visible:
			add_button.disabled = true
		tree.deselect_all()
		tree.show()
		items_list.hide()
		return
	
	string_items.sort_custom(
			func(a: WeightedText, b: WeightedText):
				if not a.query_text == new_text:
					a.query_text = new_text
					a.weight = _search_ranking(new_text, a.text)
				
				if not b.query_text == new_text:
					b.query_text = new_text
					b.weight = _search_ranking(new_text, b.text)
				return a.weight > b.weight
				)
	
	_set_items_list_items(string_items)
	if items_list.item_count > 0:
		items_list.select(0)
		_on_items_list_item_selected(0)


func _set_items_list_items(arr: Array[WeightedText]) -> void:
	items_list.clear()
	for item in arr:
		items_list.add_item(item.text)


func _on_search_box_text_submitted(new_text: String) -> void:
	if new_text == "":
		return
	item_selected_or_canceled.emit(items_list.get_item_text(items_list.get_selected_items()[0]))


func _on_items_list_item_selected(index: int) -> void:
	add_button.disabled = false
	description_label.text = item_descriptions[items_list.get_item_text(items_list.get_selected_items()[0])]


func _on_items_list_item_activated(index: int) -> void:
	item_selected_or_canceled.emit(items_list.get_item_text(index))


func _on_items_tree_item_collapsed(item: TreeItem) -> void:
	if tree.get_selected() == null:
		return
	
	if not _is_item_visible(tree.get_selected()):
		tree.deselect_all()
		add_button.disabled = true


func _on_items_tree_item_selected() -> void:
	add_button.disabled = false
	description_label.text = item_descriptions[tree.get_selected().get_text(0)]


func _on_about_to_popup() -> void:
	items_list.clear()
	string_items.clear()
	add_button.disabled = true
	description_container.hide()
	search_box.clear()
	tree.show()
	items_list.hide()
	populate_tree()
	await get_tree().process_frame
	search_box.grab_focus.call_deferred()


func _on_search_box_gui_input(event: InputEvent) -> void:
	if event is InputEventWithModifiers:
		if search_box.has_focus() and items_list.visible:
			if event.get_modifiers_mask() & KEY_MODIFIER_MASK:
				return
			
			if event.is_action_pressed("up"):
				var selected: int = items_list.get_selected_items()[0]
				items_list.select(posmod(selected - 1, items_list.item_count))
				_on_items_list_item_selected(items_list.get_selected_items()[0])
				search_box.grab_focus.call_deferred()
				set_input_as_handled()
			
			if event.is_action_pressed("down"):
				var selected: int = items_list.get_selected_items()[0]
				items_list.select(posmod(selected + 1, items_list.item_count))
				_on_items_list_item_selected(items_list.get_selected_items()[0])
				search_box.grab_focus.call_deferred()
				set_input_as_handled()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.as_text_key_label() in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
			search_box.grab_focus()


func _on_items_tree_empty_clicked(position: Vector2, mouse_button_index: int) -> void:
	tree.deselect_all()
	add_button.disabled = true


func _on_items_list_empty_clicked(at_position: Vector2, mouse_button_index: int) -> void:
	items_list.deselect_all()
	add_button.disabled = true


func _search_ranking(query: String, text: String) -> float:
	query = query.to_lower()
	text = text.to_lower()
	var weight: float = 0.0
	var weight_weight: float = 1.0
	for text_i in text.length():
		for query_i in query.length():
			if query_i + text_i > text.length() - 1:
				break
			
			#if query[query_i] in text:
				#weight += weight_weight / text.length()
			
			if query[query_i] == text[text_i + query_i]:
				weight += weight_weight * 4.0
			
		weight_weight *= 0.5
	
	return weight / text.length()
			
class WeightedText extends RefCounted:
	var weight: float
	var text: String
	var query_text: String = ""
	
	func _init(_weight: float, _text: String) -> void:
		weight = _weight
		text = _text
