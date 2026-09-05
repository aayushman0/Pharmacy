extends Panel

@onready var item_create: VBoxContainer = $MainContainer/LeftContainer/ItemContainer
@onready var item_update: VBoxContainer = $MainContainer/RightContainer/ItemContainer
@onready var item_list: VBoxContainer = $MainContainer/ListContainer/ListContainer
@onready var item_table: Tree = $MainContainer/ListContainer/ListContainer/Table
@onready var id_field: LineEdit = $MainContainer/RightContainer/IDContainer/IDField
@onready var container_animation: AnimationPlayer = $MainContainer/ContainerAnimation
var edit_visible: bool

func _ready() -> void:
	edit_visible = false

func save_to_db() -> void:
	item_create.save_to_db()
	item_list.refresh()

func update_to_db() -> void:
	if not id_field.text:
		return
	item_update.update_to_db(id_field.text)
	item_list.refresh()

func _on_table_item_activated() -> void:
	var selected_item: TreeItem = item_table.get_selected()
	if not selected_item or selected_item == item_list.table:
		return
	if item_update.refresh_edit(selected_item.get_text(0)):
		id_field.text = selected_item.get_text(0)
		if edit_visible:
			return
		container_animation.play("container_animation")
		edit_visible = true

func _on_back_button_pressed() -> void:
	id_field.text = ""
	if edit_visible:
		container_animation.play_backwards("container_animation")
		edit_visible = false
