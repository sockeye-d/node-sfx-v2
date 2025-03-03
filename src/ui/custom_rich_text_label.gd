@tool
class_name CustomRichTextLabel extends RichTextLabel


@onready var bold_font = theme.get_font(&"bold_font", &"RichTextLabel").get_rid()
@onready var bold_italics_font = theme.get_font(&"bold_italics_font", &"RichTextLabel").get_rid()
@onready var italics_font = theme.get_font(&"italics_font", &"RichTextLabel").get_rid()


class WarningRichTextEffect extends RichTextEffect:
	var bbcode = "warning"
	var owner: CustomRichTextLabel
	
	func _init(_owner: CustomRichTextLabel):
		owner = _owner
		print(owner.bold_font)
	
	func _process_custom_fx(char_fx: CharFXTransform) -> bool:
		char_fx.color = Color.RED
		if owner.bold_font:
			char_fx.font = owner.bold_font
		return true


func _init() -> void:
	install_effect(WarningRichTextEffect.new(self))
