extends Panel

@onready var bill_container: VBoxContainer = $MainContainer/LeftContainer/BillContainer
@onready var bill_list: Tree = $MainContainer/ListContainer/ListContainer/BillList
@onready var customer_name: LineEdit = $MainContainer/LeftContainer/BillContainer/CustomerContainer/Customer
@onready var discount: SpinBox = $MainContainer/LeftContainer/DiscountContainer/Discount
@onready var sum_total: SpinBox = $MainContainer/ListContainer/ListContainer/PriceContainer/SumTotalContainer/SumTotal
@onready var net_total: SpinBox = $MainContainer/ListContainer/ListContainer/PriceContainer/NetTotal/NetTotal


func _ready() -> void:
	bill_container.bill_list = bill_list

func add_to_list() -> void:
	var values: Dictionary = bill_container.send_values()
	if not values:
		Global.raise_alert("Missing Values!")
		return
	Global.db.query("SELECT * FROM batch WHERE product_id = " + values.product_id + " AND batch_no = '" + values.batch_no + "';")
	if not Global.db.query_result:
		Global.raise_alert("Internal Error!!! Batch No. not found on database!")
		return
	bill_list.add_to_list([
		values.name,
		values.batch_no,
		Global.db.query_result[0].exp_date.substr(0, 7),
		str(values.quantity),
		str(values.total),
		str(Global.db.query_result[0].id)
	])
	bill_container.refresh()

func update_sum_total(sum: float) -> void:
	sum_total.set_value_no_signal(sum)
	update_net_total()

func update_net_total(_input: Variant = null) -> void:
	net_total.value = sum_total.value - discount.value

func save_to_db() -> void:
	var bill_str: String = bill_list.get_bill_str()
	if not bill_str:
		Global.raise_alert("No items added to bill!")
		return
	Global.db.insert_row("product_bill", {
		"name": customer_name.text,
		"bill": bill_str,
		"total_amount": str(sum_total.value),
		"discount": str(discount.value),
		"net_amount": str(net_total.value),
		"bill_date": Global.dt_now_str,
		"is_enabled": 1,
	})
	refresh()

func refresh() -> void:
	customer_name.text = ""
	discount.set_value_no_signal(0)
	sum_total.set_value_no_signal(0)
	net_total.set_value_no_signal(0)
	bill_container.refresh()
	bill_list.refresh()
