extends VBoxContainer

@export_enum("product", "batch") var table_name: String = "product"
@onready var type_filter: OptionButton = $FilterContainer/TypeFilter
@onready var name_filter: LineEdit = $FilterContainer/NameFilter
@onready var description_label: Label = $FilterContainer/DescriptionLabel
@onready var description_filter: LineEdit = $FilterContainer/DescriptionFilter
@onready var shelf_filter: LineEdit = $FilterContainer/ShelfFilter
@onready var distributor_label: Label = $FilterContainer/DistributorLabel
@onready var distributor_filter: LineEdit = $FilterContainer/DistributorFilter
@onready var quantity_filter: CheckBox = $FilterContainer/QuantityFilter
@onready var main_table: Tree = $Table
@onready var table: TreeItem = main_table.create_item()


func _ready() -> void:
	if table_name == "product":
		distributor_label.visible = false
		distributor_filter.visible = false
		quantity_filter.visible = false
		main_table.columns = 7
		table.set_text(0, "     ID")
		table.set_text(1, "  Name")
		table.set_text(2, "Type")
		table.set_text(3, "Description")
		table.set_text(4, "Price/Unit ")
		table.set_text_alignment(4, HORIZONTAL_ALIGNMENT_RIGHT)
		table.set_text(5, " Months")
		table.set_text(6, "Shelf")
		main_table.set_column_expand(0, false)
		main_table.set_column_custom_minimum_width(0, 60)
		main_table.set_column_expand(2, false)
		main_table.set_column_custom_minimum_width(2, 80)
		main_table.set_column_expand(3, false)
		main_table.set_column_custom_minimum_width(3, 150)
		main_table.set_column_expand(4, false)
		main_table.set_column_custom_minimum_width(4, 150)
		main_table.set_column_expand(5, false)
		main_table.set_column_custom_minimum_width(5, 70)
		main_table.set_column_expand(6, false)
		main_table.set_column_custom_minimum_width(6, 50)
	else:
		description_label.visible = false
		description_filter.visible = false
		main_table.columns = 8
		table.set_text(0, "     Name")
		table.set_text(1, "Batch No.")
		table.set_text(2, "Price/Unit")
		table.set_text(3, "Qty ")
		table.set_text(4, "Expiry  ")
		table.set_text(5, "Shelf ")
		table.set_text(6, " Distributor")
		table.set_text(7, "ID")
		main_table.set_column_custom_minimum_width(0, 150)
		main_table.set_column_expand(2, false)
		main_table.set_column_custom_minimum_width(2, 100)
		main_table.set_column_expand(3, false)
		main_table.set_column_custom_minimum_width(3, 70)
		main_table.set_column_expand(4, false)
		main_table.set_column_custom_minimum_width(4, 75)
		main_table.set_column_expand(5, false)
		main_table.set_column_custom_minimum_width(5, 50)
		main_table.set_column_expand(6, false)
		main_table.set_column_custom_minimum_width(6, 100)
		main_table.set_column_expand(7, false)
		main_table.set_column_custom_minimum_width(7, 0)

		Global.set_column_alignment(table, [2, 3, 4, 5])
	refresh()

func refresh(_input: Variant = null) -> void:
	for child in table.get_children():
		child.free()
	var filter_query: Array[String] = []
	var filter_string: String = ""
	if type_filter.selected > 0:
		filter_query.append("type = '" + type_filter.get_item_text(type_filter.selected) + "'")
	if name_filter.text:
		filter_query.append("code LIKE LOWER('%" + Global.alphanumeric(name_filter.text) + "%')")
	if description_filter.text:
		filter_query.append("LOWER(description) LIKE LOWER('%" + Global.alphanumeric(description_filter.text) + "%')")
	if shelf_filter.text:
		filter_query.append("LOWER(shelf) LIKE LOWER('%" + shelf_filter.text + "%')")
	if distributor_filter.text:
		filter_query.append("LOWER(distributor) LIKE LOWER('%" + distributor_filter.text + "%')")
	if table_name == "batch":
		filter_query.append("quantity <= 0" if quantity_filter.button_pressed else "quantity > 0")
	if filter_query:
		filter_string = "WHERE " + " AND ".join(filter_query)
	if table_name == "product":
		Global.db.query("SELECT * FROM product " + filter_string + " ORDER BY id DESC;")
	else:
		Global.db.query(
			"SELECT batch.*, product.name, product.type, product.min_unit, product.shelf FROM batch 
			INNER JOIN product ON batch.product_id = product.id " + filter_string + 
			(" ORDER BY batch.id DESC;" if quantity_filter.button_pressed else " ORDER BY exp_date;")
		)
	for row in Global.db.query_result:
		var rows: TreeItem = main_table.create_item(table)
		if table_name == "product":
			rows.set_text(0, str(row.id))
			rows.set_text(1, "  " + row.name)
			rows.set_text(2, row.type)
			rows.set_text(3, row.description if row.description else "")
			rows.set_text(4, "%.2f/%02d " % [row.price, row.min_unit])
			rows.set_text(5, " " + str(row.best_before))
			rows.set_text(6, row.shelf)
			Global.set_column_alignment(rows, [0, 4])
		else:
			rows.set_text(0, Global.product_types_dict.get(row.type, "---") + ". " + row.name)
			rows.set_text(1, row.batch_no)
			rows.set_text(2, "%.2f/%02d" %[row.price, row.min_unit])
			rows.set_text(3, str(row.quantity) + "  ")
			rows.set_text(4, row.exp_date.substr(0,7))
			rows.set_text(5, row.shelf + " ")
			rows.set_text(6, " " + row.distributor)
			rows.set_text(7, str(row.id))
			if row.exp_date < Global.dt_now_str:
				rows.set_custom_color(4, Color.RED)
			elif row.exp_date < Global.get_future_date(3):
				rows.set_custom_color(4, Color.ORANGE)
			Global.set_column_alignment(rows, [2, 3, 4, 5])
