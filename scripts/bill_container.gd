extends VBoxContainer

@onready var customer_name: LineEdit = $CustomerContainer/Customer
@onready var stock_name: LineEdit = $NameContainer/Name
@onready var stock_batch_no: OptionButton = $BatchContainer/BatchNo
@onready var stock_quantity: SpinBox = $QuantityContainer/Quantity
@onready var stock_unit: SpinBox = $PriceContainer/Unit
@onready var stock_price: SpinBox = $PriceContainer/Price
@onready var stock_total: SpinBox = $TotalContainer/Total
@onready var drop_down_menu: PopupPanel = $NameContainer/Name/DropDownMenu
@onready var choices: Tree = $NameContainer/Name/DropDownMenu/Choices
@onready var choice_list: TreeItem = choices.create_item()
var product_id: String

func _ready() -> void:
	drop_down_menu.unfocusable = true
	choices.columns = 3
	choices.set_column_expand(1, false)
	choices.set_column_custom_minimum_width(1, 0)
	choices.set_column_expand(2, false)
	choices.set_column_custom_minimum_width(2, 0)
	stock_quantity.get_line_edit().text_changed.connect(update_qty)
	refresh()

func _on_name_focus_entered() -> void:
	update_choices(stock_name.text)

func update_choices(new_text: String) -> void:
	if new_text.length() <=2:
		drop_down_menu.hide()
		return
	Global.db.query(
		"SELECT * FROM product where code LIKE LOWER('" + Global.alphanumeric(new_text) + "%')
		 OR code LIKE LOWER('___" + Global.alphanumeric(new_text) + "%')
		 ORDER BY code LIMIT 7;"
	)
	drop_down_menu.popup(
		Rect2(stock_name.global_position + Vector2(0, stock_name.size.y + 2),
		Vector2(stock_name.size.x, max(len(Global.db.query_result) * 35, 100))))
	for child in choice_list.get_children():
		child.free()
	for row in Global.db.query_result:
		var choice: TreeItem = choices.create_item(choice_list)
		choice.set_text(0, Global.product_types_dict.get(row.type, "---") + ". " + row.name)
		choice.set_text(1, str(row.min_unit))
		choice.set_text(2, str(row.id))

func _on_name_gui_input(event: InputEvent) -> void:
	if not choice_list.get_children():
		return
	if event.is_action_released("ui_up") or event.is_action_released("ui_down"):
		choices.set_block_signals(true)
		if not choices.get_selected():
			choice_list.get_child(0).select(0)
		else:
			var next_selection: TreeItem = choices.get_selected().get_prev()\
				if event.is_action("ui_up") else choices.get_selected().get_next()
			if next_selection:
				next_selection.select(0)
		choices.set_block_signals(false)
	elif event.is_action_released("ui_accept"):
		if not choices.get_selected():
			choice_list.get_child(0).select(0)
		else:
			_on_choices_cell_selected()

func _on_choices_cell_selected() -> void:
	var selected: TreeItem = choices.get_selected()
	if not selected:
		return
	set_from_choice(selected)
	stock_name.find_next_valid_focus().grab_focus()

func _on_name_focus_exited() -> void:
	if choice_list.get_children():
		if choices.get_selected():
			set_from_choice(choices.get_selected())
		else:
			set_from_choice(choice_list.get_child(0))
	drop_down_menu.hide()

func set_from_choice(selected: TreeItem) -> void:
	stock_name.text = selected.get_text(0)
	stock_unit.set_value_no_signal(int(selected.get_text(1)))
	product_id = selected.get_text(2)
	Global.db.query("SELECT * FROM batch WHERE product_id = " + product_id + " AND quantity > 0 ORDER BY exp_date;")
	stock_batch_no.clear()
	if not Global.db.query_result:
		stock_price.set_value_no_signal(0)
		stock_quantity.value = 0
		return
	for rows in Global.db.query_result:
		stock_batch_no.add_item(rows.batch_no)
		var img: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
		if rows.exp_date < Global.dt_now_str:
			img.fill(Color.RED)
			stock_batch_no.set_item_icon(-1, ImageTexture.create_from_image(img))
			#stock_batch_no.get_popup().set_item_custom_fg_color(-1, Color.RED)
		elif rows.exp_date < Global.get_future_date(3):
			img.fill(Color.ORANGE)
			stock_batch_no.set_item_icon(-1, ImageTexture.create_from_image(img))
			#stock_batch_no.get_popup().set_item_custom_fg_color(-1, Color.ORANGE)
	stock_batch_no.select(0)
	_on_batch_no_item_selected(0)

func _on_batch_no_item_selected(index: int) -> void:
	stock_batch_no.icon = stock_batch_no.get_item_icon(index)
	Global.db.query("SELECT * FROM batch WHERE product_id = " + product_id + " AND batch_no = '" + stock_batch_no.get_item_text(index) + "';")
	if not Global.db.query_result:
		Global.raise_alert("Internal Error!!! Batch No. not found on database!")
		return
	var selected_batch: Dictionary = Global.db.query_result[0]
	stock_price.set_value_no_signal(selected_batch.price)
	stock_quantity.max_value = selected_batch.quantity
	stock_quantity.value = 0

func update_qty(_new_text: String) -> void:
	stock_quantity.apply()

func calculate_total(_input: float) -> void:
	stock_total.set_value_no_signal(stock_price.value * stock_quantity.value)

func refresh() -> void:
	pass
