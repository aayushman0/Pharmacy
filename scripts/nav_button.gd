extends Control

@export var icon: Texture2D
@export var label: String
@export var active: bool = false
@export var content: PackedScene
@onready var curr_content = %Content


func _ready() -> void:
	$Icon.texture = icon
	$Label.text = label
	update_elements()

func set_active():
	active = true
	update_elements()

func set_inactive():
	active = false
	update_elements()

func update_elements():
	$Active.visible = active
	for child in curr_content.get_children():
		curr_content.remove_child(child)
		child.queue_free()
	if active and content:
		curr_content.add_child(content.instantiate())

func _on_mouse_entered() -> void:
	$Background.color = "#000000"

func _on_mouse_exited() -> void:
	$Background.color = "#232323"

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.get_button_index() == 1 and not event.pressed:
			var nav_buttons = get_tree().get_nodes_in_group("NavButtons")
			for button in nav_buttons:
				button.set_inactive()
			set_active()
