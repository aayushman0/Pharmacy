extends VBoxContainer

@export var is_edit: bool = false
@onready var stock_name: LineEdit = $NameContainer/Name
@onready var stock_batch_no: LineEdit = $BatchContainer/BatchNo
@onready var stock_quantity: SpinBox = $QuantityContainer/Quantity
@onready var stock_unit: SpinBox = $PriceContainer/Unit
@onready var stock_price: SpinBox = $PriceContainer/Price
@onready var mfg_container: HBoxContainer = $MfgContainer
@onready var exp_container: HBoxContainer = $ExpContainer
@onready var stock_distributor: LineEdit = $DistributorContainer/Distributor
@onready var drop_down_menu: PopupPanel = $NameContainer/Name/DropDownMenu
@onready var choices: Tree = $NameContainer/Name/DropDownMenu/Choices
@onready var choice_list: TreeItem = choices.create_item()
var best_before: int = 0


func _ready() -> void:
	drop_down_menu.unfocusable = true
	choices.columns = 4
	choices.set_column_expand(1, false)
	choices.set_column_custom_minimum_width(1, 0)
	choices.set_column_expand(2, false)
	choices.set_column_custom_minimum_width(2, 0)
	choices.set_column_expand(3, false)
	choices.set_column_custom_minimum_width(3, 0)
	if is_edit:
		stock_name.editable = false
		stock_name.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
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
		choice.set_text(1, str(row.price))
		choice.set_text(2, str(row.best_before))
		choice.set_text(3, str(row.min_unit))

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
	elif event.is_action_released("ui_accept") and not event.is_action_released("ui_select"):
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
	stock_price.set_value_no_signal(float(selected.get_text(1)))
	best_before = int(selected.get_text(2))
	stock_unit.set_value_no_signal(int(selected.get_text(3)))
	if not is_edit:
		update_date(0)

func save_to_db() -> void:
	Global.db.query("SELECT * FROM product WHERE code = '" + Global.alphanumeric(stock_name.text.to_lower()) + "';")
	if not Global.db.query_result:
		Global.raise_alert("Item doesn't exist!")
		return
	var prod_id: int = Global.db.query_result[0].id
	if not (Global.alphanumeric(stock_batch_no.text) and stock_quantity.value and stock_price.value):
		Global.raise_alert("Missing Values!")
		return
	Global.db.query("SELECT * FROM batch WHERE product_id = " + str(prod_id) + " AND batch_no = '" + stock_batch_no.text + "';")
	if Global.db.query_result:
		Global.db.update_rows("batch", "id = " + str(Global.db.query_result[0].id), {
			"quantity": Global.db.query_result[0].quantity + stock_quantity.value,
			"price": stock_price.value,
			"mfg_date": mfg_container.get_date_str(),
			"exp_date": exp_container.get_date_str(),
			"distributor": stock_distributor.text,
		})
	else:
		Global.db.insert_row("batch", {
			"batch_no": stock_batch_no.text,
			"quantity": stock_quantity.value,
			"price": stock_price.value,
			"mfg_date": mfg_container.get_date_str(),
			"exp_date": exp_container.get_date_str(),
			"distributor": stock_distributor.text,
			"created_at": Global.dt_now_str,
			"product_id": prod_id,
		})
	Global.db.update_rows("product", "id = " + str(prod_id), {
		"price": stock_price.value
	})
	refresh()

func update_to_db(batch_id: String) -> void:
	if not (Global.alphanumeric(stock_batch_no.text) and stock_price.value):
		Global.raise_alert("Missing Values!")
		return
	Global.db.query("SELECT * FROM batch WHERE id = " + batch_id)
	if not Global.db.query_result:
		Global.raise_alert("Internal Error!!! Batch ID not found on Database!!!")
		return
	Global.db.query(
		"SELECT * FROM batch WHERE id <> " + batch_id + " AND product_id = " +
		str(Global.db.query_result[0].product_id) + " AND batch_no = '" + stock_batch_no.text + "';"
	)
	if Global.db.query_result:
		Global.raise_alert("Batch no. already exists!")
		return
	Global.db.update_rows("batch", "id = " + batch_id, {
		"batch_no": stock_batch_no.text,
		"quantity": stock_quantity.value,
		"price": stock_price.value,
		"mfg_date": mfg_container.get_date_str(),
		"exp_date": exp_container.get_date_str(),
		"distributor": stock_distributor.text,
		"created_at": Global.dt_now_str,
	})

func update_date(_value: float) -> void:
	if not is_edit:
		exp_container.update_date(mfg_container.get_date_with_added_months(best_before))

func refresh() -> void:
	best_before = 0
	stock_name.text = ""
	stock_batch_no.text = ""
	stock_quantity.set_value_no_signal(0)
	stock_unit.set_value_no_signal(0)
	stock_price.set_value_no_signal(0)
	mfg_container.update_date(Global.dt_now_str.substr(0, 7) + "-01")
	stock_distributor.text = ""

func refresh_edit(batch_id: String) -> bool:
	Global.db.query("SELECT batch.*, product.name, product.type, product.min_unit, product.shelf FROM batch 
			INNER JOIN product ON batch.product_id = product.id WHERE batch.id = " + batch_id + ";")
	if not Global.db.query_result:
		return false
	var product:Dictionary = Global.db.query_result[0]
	stock_name.text = Global.product_types_dict.get(product.type, "---") + ". " + product.name
	stock_batch_no.text = product.batch_no
	stock_quantity.set_value_no_signal(product.quantity)
	stock_unit.set_value_no_signal(product.min_unit)
	stock_price.set_value_no_signal(product.price)
	mfg_container.update_date(product.mfg_date)
	exp_container.update_date(product.exp_date)
	stock_distributor.text = product.distributor
	return true
