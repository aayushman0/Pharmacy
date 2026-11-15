extends Panel

@onready var date_filter: HBoxContainer = $MainContainer/LeftContainer/FilterContainer/DateFilter
@onready var history: Tree = $MainContainer/LeftContainer/History
@onready var history_table: TreeItem = history.create_item()
@onready var customer_name: LineEdit = $MainContainer/RightContainer/RightContainer/IDContainer/CustomerName
@onready var bill_list: Tree = $MainContainer/RightContainer/RightContainer/BillList
@onready var daily_total: SpinBox = $MainContainer/LeftContainer/DailyTotalContainer/DailyTotal
@onready var bill_id: LineEdit = $MainContainer/RightContainer/RightContainer/IDContainer/BillID
@onready var sum_total: SpinBox = $MainContainer/RightContainer/RightContainer/SumTotal/SumTotal
@onready var net_total: SpinBox = $MainContainer/RightContainer/RightContainer/NetTotal/NetTotal
@onready var discount: SpinBox = $MainContainer/RightContainer/RightContainer/SumTotal/Discount
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog
@export_enum("product", "service") var bill_type = "product"
var start_id: int
var start_date: String


func _ready() -> void:
	date_filter.update_datetime_no_signal(Global.dt_now_str)
	history_table.set_text(0, "     ID")
	history_table.set_text(1, "Customer's Name")
	history_table.set_text(2, "Amount")
	history_table.set_text(3, "  Time")
	history.set_column_expand(0, false)
	history.set_column_custom_minimum_width(0, 60)
	history.set_column_expand(2, false)
	history.set_column_custom_minimum_width(2, 90)
	history.set_column_expand(3, false)
	history.set_column_custom_minimum_width(3, 75)
	history.set_column_expand(4, false)
	history.set_column_custom_minimum_width(4, 0)
	Global.set_column_alignment(history_table, [0, 2, 3])

	var label = confirmation_dialog.get_label()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)

	refresh()

func _on_left_button_pressed() -> void:
	change_day(-1)

func _on_right_button_pressed() -> void:
	change_day(1)

func change_day(day: int) -> void:
	var unix_date: int = Time.get_unix_time_from_datetime_string(date_filter.get_date_str())
	unix_date += 86400 * day
	date_filter.update_datetime_no_signal(Time.get_date_string_from_unix_time(unix_date) + " 00:00:00")
	refresh()

func _on_history_item_selected() -> void:
	var selected: TreeItem = history.get_selected()
	if not selected or selected == history_table:
		return
	Global.db.query("SELECT * FROM " + bill_type + "_bill WHERE id = " + selected.get_text(4))
	if not Global.db.query_result:
		Global.raise_alert("Internal Error!!! Bill not found!")
		return
	bill_list.refresh()
	var bill: Dictionary = Global.db.query_result[0]
	customer_name.text = bill.name
	bill_id.text = str(bill.id)
	sum_total.set_value_no_signal(bill.total_amount)
	net_total.set_value_no_signal(bill.net_amount)
	discount.set_value_no_signal(bill.discount)

	if bill_type == "service":
		for bill_entry in bill.bill.split(","):
			bill_list.add_to_list(Array(bill_entry.split("::")))
		return

	var entry_values: PackedStringArray
	var product: Dictionary
	for bill_entry in bill.bill.split(","):
		entry_values = bill_entry.split(":")
		Global.db.query(
			"SELECT batch.*, product.name, product.type, product.min_unit FROM batch
			 INNER JOIN product ON batch.product_id = product.id
			 WHERE batch.id = " + entry_values[0]
		)
		if not Global.db.query_result:
			product = {
				"type": "---",
				"name": "Deleted",
				"batch_no": "Deleted",
				"exp_date": "20XX-XX-XX"
			}
		else:
			product = Global.db.query_result[0]
		bill_list.add_to_list([
			Global.product_types_dict.get(product.type, "---") + ". " + product.name,
			product.batch_no,
			product.exp_date.substr(0, 7),
			"%.1f/%02d" %[product.price, product.min_unit],
			entry_values[1],
			entry_values[2],
		])

func raise_confirmation() -> void:
	if not bill_id.text:
		Global.raise_alert("Please select a bill first!")
		return
	confirmation_dialog.popup_centered()

func delete_from_db() -> void:
	Global.db.query("SELECT * FROM " + bill_type + "_bill WHERE id = " + bill_id.text)
	if not Global.db.query_result:
		Global.raise_alert("Bill not found!")
		return
	var bill_str: String = Global.db.query_result[0].bill
	Global.db.update_rows(bill_type + "_bill", "id = " + bill_id.text, {
		"is_enabled": 0
	})
	if bill_type == "product":
		var item_arr: PackedStringArray
		for item_str in bill_str.split(","):
			item_arr = item_str.split(":")
			Global.db.query(
				"UPDATE batch SET quantity = quantity + " + item_arr[1] + ",
				 created_at = '" + Global.dt_now_str + "'
				 WHERE id = " + item_arr[0]
			)
	refresh()

func print_bill() -> void:
	var python_path: String
	var full_path: String
	if OS.get_name() == "Windows":
		python_path = "print/venv/Scripts/python.exe"
	else:
		python_path = "print/venv/bin/python"
	if OS.has_feature("editor"):
		full_path = "res://" + python_path
	else:
		full_path = OS.get_executable_path().get_base_dir().path_join(python_path)
	if not FileAccess.file_exists(full_path):
		Global.raise_alert("Printing module not installed!")
		return
	Global.db.query("SELECT * FROM " + bill_type + "_bill WHERE id = " + bill_id.text)
	if not Global.db.query_result:
		Global.raise_alert("Bill not found!")
		return
	var bill: Dictionary = Global.db.query_result[0]
	var bill_string: String = "\n"
	var entry_values: PackedStringArray
	var product: Dictionary
	var particular: String
	var batch_no: String
	var sn: int = 1
	if bill_type == "service":
		for bill_entry in bill.bill.split(","):
			entry_values = bill_entry.split("::")
			particular = entry_values[0]
			if particular.length() < 10:
				particular += "\t\t\t"
			elif particular.length() < 16:
				particular += "\t\t"
			elif particular.length() < 24:
				particular += "\t"
			elif particular.length() < 30:
				pass
			else:
				particular = particular.substr(0, 29)
			bill_string += "%02d " % [sn] + particular + "\t\t\t\t" + entry_values[1].lpad(9) + "\n"
			sn += 1
	else:
		for bill_entry in bill.bill.split(","):
			entry_values = bill_entry.split(":")
			Global.db.query(
				"SELECT batch.*, product.name, product.type, product.min_unit FROM batch
				 INNER JOIN product ON batch.product_id = product.id
				 WHERE batch.id = " + entry_values[0]
			)
			if not Global.db.query_result:
				product = {
					"type": "---",
					"name": "Deleted",
					"batch_no": "Deleted",
					"exp_date": "20XX-XX-XX"
				}
			else:
				product = Global.db.query_result[0]
			particular = Global.product_types_dict.get(product.type, "---") + ". " + product.name
			if particular.length() < 10:
				particular += "\t\t"
			elif particular.length() < 16:
				particular += "\t"
			else:
				particular = particular.substr(0, 15) + "\t"
			batch_no = product.batch_no
			if batch_no.length() < 7:
				batch_no += "\t\t"
			elif batch_no.length() < 12:
				batch_no += "\t"
			else:
				batch_no = batch_no.substr(0, 11) + "\t"
			bill_string += "%02d " % [sn] + particular + batch_no + product.exp_date.substr(5, 2) + "/" + product.exp_date.substr(2, 2) + "\t"
			bill_string += entry_values[1].rpad(5) + "%.2f" % [product.price] + "\t" + entry_values[2].lpad(9) + "\n"
			sn += 1
	var argument_array: Array[String] = [
		"print/print.py",
		"product",
		str(bill.id - start_id),
		bill.bill_date.substr(0, 10),
		bill.name if bill.name else "---",
		bill_string,
		"%8.2f" % [bill.total_amount],
		"%8.2f" % [bill.discount],
		"%8.2f" % [bill.net_amount],
	]
	OS.execute(python_path, argument_array)

func refresh(_input: Variant = null) -> void:
	for child in history_table.get_children():
		child.free()
	change_fiscal_year()
	Global.db.query("SELECT * FROM " + bill_type + "_bill WHERE is_enabled = true AND DATE(bill_date) = '" + date_filter.get_date_str() + "' ORDER BY id DESC;")
	var daily_total_calc: float = 0
	for rows in Global.db.query_result:
		var row: TreeItem = history.create_item(history_table)
		row.set_text(0, str(rows.id - start_id))
		row.set_text(1, rows.name)
		row.set_text(2, "%.1f"%[rows.net_amount])
		row.set_text(3, rows.bill_date.substr(11, 5))
		row.set_text(4, str(rows.id))
		Global.set_column_alignment(row, [0, 2, 3])
		daily_total_calc += rows.net_amount
	daily_total.set_value_no_signal(daily_total_calc)

	customer_name.text = ""
	bill_id.text = ""
	bill_list.refresh()
	sum_total.set_value_no_signal(0)
	net_total.set_value_no_signal(0)
	discount.set_value_no_signal(0)

func change_fiscal_year() -> void:
	if date_filter.get_date_str() >= (date_filter.get_date_str().substr(0, 4) + "-07-17"):
		start_date = date_filter.get_date_str().substr(0, 4) + "-07-17"
	else:
		start_date = str(int(date_filter.get_date_str().substr(0, 4)) - 1) + "-07-17"
	Global.db.query("SELECT * FROM " + bill_type + "_bill WHERE DATE(bill_date) < '" + start_date + "' ORDER BY id DESC LIMIT 1;")
	if not Global.db.query_result:
		start_id = 0
	else:
		start_id = Global.db.query_result[0].id
