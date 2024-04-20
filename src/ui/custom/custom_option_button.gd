@tool
class_name CustomOptionButton extends OptionButton


func _init() -> void:
	_deferred_init.call_deferred()


func _deferred_init() -> void:
	get_popup().transparent = true
	get_popup().transparent_bg = true
