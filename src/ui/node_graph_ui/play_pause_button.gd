class_name PlayPauseButton extends Button


signal play_pause_changed(playing: bool)


@export var pause_icon: Texture = preload("res://src/assets/icons/pause.png")
@export var play_icon: Texture = preload("res://src/assets/icons/play.png")


var playing: bool:
	set(value):
		icon = pause_icon if value else play_icon
		playing = value
	get:
		return playing


func _ready() -> void:
	playing = false


func _on_pressed() -> void:
	playing = not playing
	play_pause_changed.emit(playing)


func _on_resized() -> void:
	custom_minimum_size.x = size.y
