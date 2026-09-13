extends Panel

@onready var date_filter: HBoxContainer = $MainContainer/LeftContainer/FilterContainer/DateFilter
@onready var history: Tree = $MainContainer/LeftContainer/History
@onready var history_table: TreeItem = history.create_item()
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
	history.set_column_custom_minimum_width(2, 80)
	history.set_column_expand(3, false)
	history.set_column_custom_minimum_width(3, 75)
	history.set_column_expand(4, false)
	history.set_column_custom_minimum_width(4, 0)
	Global.set_column_alignment(history_table, [0, 2, 3])
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

func refresh(_input: Variant = null) -> void:
	for child in history_table.get_children():
		child.free()
	change_fiscal_year()
	Global.db.query("SELECT * FROM product_bill WHERE is_enabled = true AND DATE(bill_date) = '" + date_filter.get_date_str() + "' ORDER BY id DESC;")
	for rows in Global.db.query_result:
		var row: TreeItem = history.create_item(history_table)
		row.set_text(0, str(rows.id - start_id))
		row.set_text(1, rows.name)
		row.set_text(2, "%.1f"%[rows.net_amount])
		row.set_text(3, rows.bill_date.substr(11, 5))
		row.set_text(4, str(rows.id))
		Global.set_column_alignment(row, [0, 2, 3])

func change_fiscal_year() -> void:
	if date_filter.get_date_str() >= (date_filter.get_date_str().substr(0, 4) + "-07-17"):
		start_date = date_filter.get_date_str().substr(0, 4) + "-07-17"
	else:
		start_date = str(int(date_filter.get_date_str().substr(0, 4)) - 1) + "-07-17"
	Global.db.query("SELECT * FROM product_bill WHERE DATE(bill_date) < '" + start_date + "' ORDER BY id DESC LIMIT 1;")
	if not Global.db.query_result:
		start_id = 0
	else:
		start_id = Global.db.query_result[0].id
