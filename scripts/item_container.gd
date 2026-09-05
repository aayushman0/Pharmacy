extends VBoxContainer

@export var is_edit: bool = false
@onready var item_name: LineEdit = $NameContainer/Name
@onready var item_type: OptionButton = $TypeContainer/Type
@onready var item_price: SpinBox = $PriceContainer/Price
@onready var item_unit: SpinBox = $PriceContainer/Unit
@onready var item_best_before: SpinBox = $BestBeforeContainer/BestBefore
@onready var item_shelf: LineEdit = $ShelfContainer/Shelf
@onready var stock_table: Tree = $StockTable
@onready var table: TreeItem = stock_table.create_item()


func _ready() -> void:
	table.set_text(0, "Batch No.")
	table.set_text(1, "Quantity")
	table.set_text(2, "Expiry")
	stock_table.visible = is_edit
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
		"price": item_price.value,
		"min_unit": item_unit.value,
		"best_before": item_best_before.value,
		"shelf": item_shelf.text,
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
		"price": item_price.value,
		"min_unit": item_unit.value,
		"best_before": item_best_before.value,
		"shelf": item_shelf.text, 
	})

func refresh() -> void:
	item_name.text = ""
	item_type.select(0)
	item_price.value = 0
	item_unit.value = 1
	item_best_before.value = 0
	item_shelf.text = ""
	for child in table.get_children():
		child.free()

func refresh_edit(item_id: String) -> bool:
	Global.db.query("SELECT * FROM product WHERE id = " + item_id + ";")
	if not Global.db.query_result:
		return false
	var product:Dictionary = Global.db.query_result[0]
	item_name.text = product.name
	item_type.select(Global.product_types_dict.keys().find(product.type))
	item_price.set_value_no_signal(product.price)
	item_unit.set_value_no_signal(product.min_unit)
	item_best_before.set_value_no_signal(product.best_before)
	item_shelf.text = product.shelf
	return true
