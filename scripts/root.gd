extends Control

@onready var message_box: AcceptDialog = $MessageBox


func _ready() -> void:
	Global.message_box = message_box
	var label = message_box.get_label()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
