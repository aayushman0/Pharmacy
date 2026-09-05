extends Control


@onready var sidebar_animation: AnimationPlayer = $"../../SidebarAnimation"
var is_sidebar_extended: bool = false


func _on_mouse_entered() -> void:
	$Background.color = "#000000"

func _on_mouse_exited() -> void:
	$Background.color = "#232323"

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.get_button_index() == 1 and not event.pressed:
			if not is_sidebar_extended:
				sidebar_animation.play("sidebar_animation")
			else:
				sidebar_animation.play_backwards("sidebar_animation")
			is_sidebar_extended = not is_sidebar_extended
