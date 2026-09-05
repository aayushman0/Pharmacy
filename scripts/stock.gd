extends Panel

@onready var stock_create: VBoxContainer = $MainContainer/LeftContainer/StockContainer
@onready var stock_update: VBoxContainer = $MainContainer/RightContainer/StockContainer
@onready var stock_list: VBoxContainer = $MainContainer/ListContainer/ListContainer
@onready var stock_table: Tree = $MainContainer/ListContainer/ListContainer/Table
@onready var id_field: LineEdit = $MainContainer/RightContainer/IDContainer/IDField
@onready var container_animation: AnimationPlayer = $MainContainer/ContainerAnimation
var edit_visible: bool

func _ready() -> void:
	edit_visible = false

func save_to_db() -> void:
	stock_create.save_to_db()
	stock_list.refresh()

func update_to_db() -> void:
	if not id_field.text:
		return
	stock_update.update_to_db(id_field.text)
	stock_list.refresh()

func _on_table_item_activated() -> void:
	var selected_item: TreeItem = stock_table.get_selected()
	if not selected_item or selected_item == stock_list.table:
		return
	if stock_update.refresh_edit(selected_item.get_text(7)):
		id_field.text = selected_item.get_text(7)
		if edit_visible:
			return
		container_animation.play("container_animation")
		edit_visible = true

func _on_back_button_pressed() -> void:
	id_field.text = ""
	if edit_visible:
		container_animation.play_backwards("container_animation")
		edit_visible = false
