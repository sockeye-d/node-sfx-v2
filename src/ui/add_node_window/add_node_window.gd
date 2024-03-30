@tool
class_name AddNodeWindow extends Window


signal item_selected_or_canceled(item: String)


@export var populate_tree_action: bool = false:
	set(value):
		populate_tree()
		populate_tree_action = false
@export var items: NodeItem:
	set(value):
		items = value
		populate_tree()
	get:
		return items


@onready var tree: Tree = %ItemsTree as Tree
@onready var btn: Button = %AddButton as Button
@onready var cancel_button: Button = %CancelButton as Button


func show():
	super()
	populate_tree()
	tree.get_root().set_collapsed_recursive(true)
	tree.get_root().uncollapse_tree()


func _ready() -> void:
	populate_tree()
	tree.get_root().set_collapsed_recursive(true)
	tree.get_root().uncollapse_tree()
	


func _process(delta: float) -> void:
	btn.disabled = tree.get_selected() == null
	if not tree.get_selected() == null:
		if not _is_item_visible(tree.get_selected()):
			tree.deselect_all()


func populate_tree() -> void:
	if tree == null:
		return
	tree.clear()
	_create_item_from_content(null, items)


func _create_item_from_content(parent: TreeItem, content: NodeItem) -> void:
	var item: TreeItem = tree.create_item(parent)
	item.set_text(0, content.name)
	if content.children.size() > 0:
		item.set_selectable(0, false)
		for i in content.children:
			_create_item_from_content(item, i)


func _is_item_visible(item: TreeItem) -> bool:
	if item.get_parent() == null:
		return item.visible and not (item.collapsed and item.get_child_count() > 0)
	return item.visible and not (item.collapsed and item.get_child_count() > 0) and _is_item_visible(item.get_parent())


func _on_items_tree_item_activated() -> void:
	item_selected_or_canceled.emit(tree.get_selected().get_text(0))
	hide()


func _on_button_pressed() -> void:
	item_selected_or_canceled.emit(tree.get_selected().get_text(0))
	hide()


func _on_close_requested() -> void:
	item_selected_or_canceled.emit("")
	hide()
