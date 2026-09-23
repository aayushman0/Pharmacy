extends VBoxContainer

@export var is_edit: bool = false
@onready var item_name: LineEdit = $NameContainer/Name
@onready var item_type: OptionButton = $TypeContainer/Type
@onready var item_description: LineEdit = $DescriptionContainer/Description
@onready var item_price: SpinBox = $PriceContainer/Price
@onready var item_unit: SpinBox = $PriceContainer/Unit
@onready var item_best_before: SpinBox = $BestBeforeContainer/BestBefore
@onready var item_shelf: LineEdit = $ShelfContainer/Shelf
@onready var stock_table: Tree = $StockTable
@onready var table: TreeItem = stock_table.create_item()
@onready var delete_button: Button = $DeleteFromDB


func _ready() -> void:
	table.set_text(0, "Batch No.")
	table.set_text(1, "Quantity")
	table.set_text(2, "Expiry")
	stock_table.set_column_expand(1, false)
	stock_table.set_column_custom_minimum_width(1, 100)
	stock_table.set_column_expand(2, false)
	stock_table.set_column_custom_minimum_width(2, 100)
	stock_table.visible = is_edit
	delete_button.visible = is_edit
	refresh()

func save_to_db() -> void:
	if not (Global.alphanumeric(item_name.text) and item_price.value and item_unit.value and item_best_before.value):
		Global.raise_alert("Missing Values!")
		return
	var code: String = Global.product_types[item_type.selected] + Global.alphanumeric(item_name.text).to_lower()
	Global.db.query("SELECT * FROM product WHERE code = '%s';" % [code])
	if Global.db.query_result:
		Global.raise_alert("Item already exists!")
		return
	Global.db.insert_row("product", {
		"name": item_name.text,
		"type": item_type.get_item_text(item_type.selected),
		"code": code,
		"description": item_description.text,
		"price": item_price.value,
		"min_unit": item_unit.value,
		"best_before": item_best_before.value,
		"shelf": item_shelf.text,
		"is_enabled": 1
	})
	refresh()

func update_to_db(item_id: String) -> void:
	if not (Global.alphanumeric(item_name.text) and item_price.value and item_unit.value and item_best_before.value):
		Global.raise_alert("Missing Values!")
		return
	var code: String = Global.product_types[item_type.selected] + Global.alphanumeric(item_name.text).to_lower()
	Global.db.query("SELECT * FROM product WHERE code = '%s' AND id <> %s;" % [code, item_id])
	if Global.db.query_result:
		Global.raise_alert("New name already exists!")
		return
	Global.db.update_rows("product", "id = " + item_id, {
		"name": item_name.text,
		"type": item_type.get_item_text(item_type.selected),
		"code": code,
		"description": item_description.text,
		"price": item_price.value,
		"min_unit": item_unit.value,
		"best_before": item_best_before.value,
		"shelf": item_shelf.text, 
	})

func delete_from_db(item_id: String) -> void:
	Global.db.query("UPDATE product SET is_enabled = NOT is_enabled WHERE id = " + item_id)

func refresh() -> void:
	item_name.text = ""
	item_type.select(0)
	item_description.text = ""
	item_price.value = 0
	item_unit.value = 1
	item_best_before.value = 0
	item_shelf.text = ""
	for child in table.get_children():
		child.free()

func refresh_edit(item_id: String) -> bool:
	for child in table.get_children():
		child.free()
	Global.db.query("SELECT * FROM product WHERE id = " + item_id + ";")
	if not Global.db.query_result:
		return false
	var product:Dictionary = Global.db.query_result[0]
	item_name.text = product.name
	item_type.select(Global.product_types_dict.keys().find(product.type))
	item_description.text = product.description if product.description else ""
	item_price.set_value_no_signal(product.price)
	item_unit.set_value_no_signal(product.min_unit)
	item_best_before.set_value_no_signal(product.best_before)
	item_shelf.text = product.shelf
	Global.db.query("SELECT * FROM batch WHERE product_id = " + item_id + ";")
	for batch in Global.db.query_result:
		var row: TreeItem = stock_table.create_item(table)
		row.set_text(0, batch.batch_no)
		row.set_text(1, str(batch.quantity))
		row.set_text(2, batch.exp_date.substr(0, 7))
	return true
