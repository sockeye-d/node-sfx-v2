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
var string_items: Array[String] = []


@onready var search_box: LineEdit = %SearchBox
@onready var tree: Tree = %ItemsTree
@onready var add_button: Button = %AddButton
@onready var cancel_button: Button = %CancelButton
@onready var tree_scroll_container: ScrollContainer = %TreeScrollContainer
@onready var list_scroll_container: ScrollContainer = %ListScrollContainer
@onready var items_list: ItemList = %ItemsList


func _ready() -> void:
	items_list.clear()
	string_items.clear()
	populate_tree()
	item_selected_or_canceled.connect(func(item):
		print(item)
		hide()
		)
	#tree.get_root().set_collapsed_recursive.call_deferred(false)


func populate_tree() -> void:
	if tree == null:
		return
	items_list.clear()
	string_items.clear()
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
		string_items.append(content.name)
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
		if not list_scroll_container.visible:
			add_button.disabled = false
		
		tree_scroll_container.hide()
		list_scroll_container.show()
	else:
		if not tree_scroll_container.visible:
			add_button.disabled = true
		tree.deselect_all()
		tree_scroll_container.show()
		list_scroll_container.hide()
	
	string_items.sort_custom(
			func(a, b):
				return new_text.similarity(a) > new_text.similarity(b)
				)
	
	_set_items_list_items(string_items)
	if items_list.item_count > 0:
		items_list.select(0)


func _set_items_list_items(arr: Array[String]) -> void:
	items_list.clear()
	for item in arr:
		items_list.add_item(item)


func _on_search_box_text_submitted(new_text: String) -> void:
	if new_text == "":
		return
	item_selected_or_canceled.emit(items_list.get_item_text(items_list.get_selected_items()[0]))


func _on_items_list_item_selected(index: int) -> void:
	add_button.disabled = false


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


func _on_about_to_popup() -> void:
	items_list.clear()
	string_items.clear()
	add_button.disabled = true
	search_box.clear()
	tree_scroll_container.show()
	list_scroll_container.hide()
	populate_tree()
	await get_tree().process_frame
	search_box.grab_focus.call_deferred()


func _on_search_box_gui_input(event: InputEvent) -> void:
	if search_box.has_focus() and items_list.visible:
		if event.is_action_pressed("up"):
			var selected: int = items_list.get_selected_items()[0]
			items_list.select(posmod(selected - 1, items_list.item_count))
			search_box.grab_focus.call_deferred()
			set_input_as_handled()
		
		if event.is_action_pressed("down"):
			var selected: int = items_list.get_selected_items()[0]
			items_list.select(posmod(selected + 1, items_list.item_count))
			search_box.grab_focus.call_deferred()
			set_input_as_handled()
