extends Tree

@onready var table: TreeItem = self.create_item()
@export_enum("product", "service") var bill_type = "product"
@export var bill_history: bool = false

signal list_updated(sum: float)

func _ready() -> void:
	if bill_type == "product":
		table.set_text(0, "   Particular")
		table.set_text(1, "Batch No.")
		table.set_text(2, "Expiry  ")
		table.set_text(3, "Qty ")
		table.set_text(4, "Total   ")
		self.set_column_expand(1, false)
		self.set_column_custom_minimum_width(1, 170)
		self.set_column_expand(2, false)
		self.set_column_custom_minimum_width(2, 75)
		self.set_column_expand(3, false)
		self.set_column_custom_minimum_width(3, 70)
		self.set_column_expand(4, false)
		self.set_column_custom_minimum_width(4, 150)
		self.set_column_expand(5, false)
		self.set_column_custom_minimum_width(5, 0)
		Global.set_column_alignment(table, [2, 3, 4])
	else:
		self.columns = 2
		table.set_text(0, "    Service Name")
		table.set_text(1, "Price    ")
		Global.set_column_alignment(table, [1])

func add_to_list(values: Array) -> void:
	var table_item: TreeItem = self.create_item(table)
	for i in range(values.size()):
		table_item.set_text(i, values[i])
	if bill_type == "product":
		Global.set_column_alignment(table_item, [2, 3, 4])
	else:
		Global.set_column_alignment(table_item, [1])
	get_sum_total()

func _on_item_activated() -> void:
	if bill_history:
		return
	var selected_item: TreeItem = self.get_selected()
	if not selected_item or selected_item == table:
		return
	selected_item.free()
	get_sum_total()

func get_sum_total() -> void:
	var sum: float = 0
	for child in table.get_children():
		sum += float(child.get_text(4 if bill_type == "product" else 1))
	list_updated.emit(sum)

func get_batches_from_list(product_name: String) -> Array[String]:
	var batches: Array[String] = []
	for row in table.get_children():
		if row.get_text(0) == product_name:
			batches.append(row.get_text(1))
	return batches

func get_bill_str() -> String:
	var bill_arr: Array[String] = []
	if bill_type == "service":
		for row in table.get_children():
			bill_arr.append(row.get_text(0) + "::" + row.get_text(1))
		return ",".join(bill_arr)

	for row in table.get_children():
		bill_arr.append(row.get_text(5) + ":" + row.get_text(3) + ":" + row.get_text(4))
		Global.db.query(
			"UPDATE batch SET quantity = quantity - " + row.get_text(3) + ",
			 created_at = '" + Global.dt_now_str + "'
			 WHERE id = " + row.get_text(5)
		)
	return ",".join(bill_arr)

func refresh() -> void:
	for child in table.get_children():
		child.free()
