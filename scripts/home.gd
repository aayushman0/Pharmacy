extends Panel

@onready var start_time: HBoxContainer = $MainContainer/LeftContainer/FilterContainer/StartTime
@onready var end_time: HBoxContainer = $MainContainer/LeftContainer/FilterContainer/EndTime
@onready var product_income: SpinBox = $MainContainer/LeftContainer/FilterContainer/ProductIncomeContainer/ProductIncome
@onready var service_income: SpinBox = $MainContainer/LeftContainer/FilterContainer/ServiceIncomeContainer/ServiceIncome


func _ready() -> void:
	start_time.update_datetime(Global.dt_now_str)
	end_time.update_datetime(Global.dt_now_str)
	refresh()

func refresh() -> void:
	Global.db.query(
		"SELECT TOTAL(net_amount) AS total FROM product_bill WHERE is_enabled = 1 AND DATE(bill_date) >= '" +
		 start_time.get_date_str() + "' AND DATE(bill_date) <= '" + 
		end_time.get_date_str() + "';"
	)
	product_income.set_value_no_signal(Global.db.query_result[0].total)
	Global.db.query(
		"SELECT TOTAL(net_amount) AS total FROM service_bill WHERE is_enabled = 1 AND DATE(bill_date) >= '" +
		 start_time.get_date_str() + "' AND DATE(bill_date) <= '" + 
		end_time.get_date_str() + "';"
	)
	service_income.set_value_no_signal(Global.db.query_result[0].total)
