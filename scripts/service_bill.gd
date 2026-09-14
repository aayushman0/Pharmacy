extends Panel

@onready var customer_name: LineEdit = $MainContainer/LeftContainer/BillContainer/CustomerContainer/Customer
@onready var service_name: LineEdit = $MainContainer/LeftContainer/BillContainer/NameContainer/Name
@onready var service_price: SpinBox = $MainContainer/LeftContainer/BillContainer/PriceContainer/Price
@onready var discount: SpinBox = $MainContainer/LeftContainer/DiscountContainer/Discount
@onready var bill_list: Tree = $MainContainer/ListContainer/ListContainer/BillList
@onready var sum_total: SpinBox = $MainContainer/ListContainer/ListContainer/PriceContainer/SumTotalContainer/SumTotal
@onready var net_total: SpinBox = $MainContainer/ListContainer/ListContainer/PriceContainer/NetTotalContainer/NetTotal


func _ready() -> void:
	pass

func add_to_list() -> void:
	var entry_name: String = service_name.text.replace(":", "").replace(",", "")
	if not entry_name or not service_price.value:
		Global.raise_alert("Missing values!")
		return
	bill_list.add_to_list([entry_name, str(service_price.value)])
	refresh_entry()

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
	Global.db.insert_row("service_bill", {
		"name": customer_name.text,
		"bill": bill_str,
		"total_amount": str(sum_total.value),
		"discount": str(discount.value),
		"net_amount": str(net_total.value),
		"bill_date": Global.dt_now_str,
		"is_enabled": 1,
	})
	refresh()

func refresh_entry() -> void:
	service_name.text = ""
	service_price.set_value_no_signal(0)

func refresh() -> void:
	customer_name.text = ""
	refresh_entry()
	discount.set_value_no_signal(0)
	sum_total.set_value_no_signal(0)
	net_total.set_value_no_signal(0)
	bill_list.refresh()
