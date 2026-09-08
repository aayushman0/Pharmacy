extends HBoxContainer

@export var show_time: bool = true
@export var custom_label: String = ""
@onready var label: Label = $Label
@onready var year: SpinBox = $Year
@onready var month: SpinBox = $Month
@onready var day: SpinBox = $Day
@onready var seperator: Label = $Seperator
@onready var hour: SpinBox = $Hour
@onready var minute: SpinBox = $Minute
var days_in_months: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]


func _ready() -> void:
	seperator.visible = show_time
	hour.visible = show_time
	minute.visible = show_time
	if custom_label == "Hide":
		label.visible = false
	elif custom_label:
		label.text = custom_label

func get_max_day_of_month(y: int, m: int) -> int:
	if m == 2 and ((y % 4 == 0 and y % 100 != 0) or (y % 400 == 0)):
		return 29
	return days_in_months[m - 1]

func set_max_day_of_month(_input: float) -> void:
	day.max_value = get_max_day_of_month(int(year.value), int(month.value))

func get_dt_str() -> String:
	var dt_str: String = "-".join([str(int(year.value)), double_digit(month.value), double_digit(day.value)])
	dt_str = dt_str + " " + ":".join([double_digit(hour.value), double_digit(minute.value), "00"])
	return dt_str

func get_date_str() -> String:
	return "-".join([str(int(year.value)), double_digit(month.value), double_digit(day.value)])

func update_datetime(dt_str: String) -> void:
	var dt_arr: PackedStringArray = dt_str.split(" ")
	year.value = float(dt_arr[0].split("-")[0])
	month.value = float(dt_arr[0].split("-")[1])
	day.value = float(dt_arr[0].split("-")[2])
	hour.value = float(dt_arr[1].split(":")[0])
	minute.value = float(dt_arr[1].split(":")[1])

func update_datetime_no_signal(dt_str: String) -> void:
	var dt_arr: PackedStringArray = dt_str.split(" ")
	year.set_value_no_signal(float(dt_arr[0].split("-")[0]))
	month.set_value_no_signal(float(dt_arr[0].split("-")[1]))
	day.set_value_no_signal(float(dt_arr[0].split("-")[2]))
	hour.set_value_no_signal(float(dt_arr[1].split(":")[0]))
	minute.set_value_no_signal(float(dt_arr[1].split(":")[1]))

func update_date(date_str: String) -> void:
	var date_arr: PackedStringArray = date_str.split("-")
	year.value = float(date_arr[0])
	month.value = float(date_arr[1])
	day.value = float(date_arr[2])

func get_date_with_added_months(months: int) -> String:
	var new_month: int = int(month.value) + months - 1
	@warning_ignore("integer_division")
	return "-".join([str(year.value + new_month / 12), double_digit(new_month % 12 + 1), double_digit(day.value)])

func refresh() -> void:
	year.value = Global.dt_now.year
	month.value = Global.dt_now.month
	day.value = Global.dt_now.day
	hour.value = Global.dt_now.hour
	minute.value = Global.dt_now.minute

func double_digit(x: float) -> String:
	if x < 10:
		return "0" + str(int(x))
	else:
		return str(int(x))
