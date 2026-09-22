extends Node

@onready var message_box: AcceptDialog = null

var row_count: int = 100
var regex = RegEx.new()
var dt_now: Dictionary:
	get:
		return Time.get_datetime_dict_from_system()
var dt_now_str: String:
	get:
		return Time.get_datetime_string_from_system(false, true)
var db = SQLite.new()
var product_types: Array[String] = ["tab", "cap", "srp", "drp", "ont", "crm", "gel", "pwd", "inj", "oth"]
var product_types_dict: Dictionary[String, String] = {
	"Tablet": "Tab",
	"Capsule": "Cap",
	"Syrup": "Srp",
	"Drops": "Drp",
	"Ointment": "Ont",
	"Cream": "Crm",
	"Gel": "Gel",
	"Powder": "Pwd",
	"Injection": "Inj",
	"Other": "Oth",
}


func alphanumeric(input: String) -> String:
	regex.compile("[^A-Za-z0-9]")
	return regex.sub(input, "", true)

func get_future_date(months: int) -> String:
	var month: int = dt_now.month
	var year: int = dt_now.year
	month += months
	@warning_ignore("integer_division")
	year += (month - 1) / 12
	month = (month - 1) % 12 + 1
	return "%d-%02d-02" % [year, month]

func _ready() -> void:
	db.path = "res://database.db"
	db.open_db()

	db.query(
		"CREATE TABLE IF NOT EXISTS product (
			id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
			name VARCHAR NOT NULL,
			type VARCHAR NOT NULL,
			code VARCHAR NOT NULL,
			description VARCHAR,
			price FLOAT,
			min_unit INTEGER,
			best_before INTEGER,
			shelf VARCHAR
		);"
	)
	db.query("CREATE INDEX IF NOT EXISTS ix_product_name ON product (name);")
	db.query("CREATE INDEX IF NOT EXISTS ix_product_type ON product (type);")
	db.query("CREATE INDEX IF NOT EXISTS ix_product_code ON product (code);")
	db.query("CREATE INDEX IF NOT EXISTS ix_product_description ON product (description);")
	db.query("CREATE INDEX IF NOT EXISTS ix_product_shelf ON product (shelf);")

	db.query(
		"CREATE TABLE IF NOT EXISTS batch (
			id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
			batch_no VARCHAR NOT NULL,
			quantity INTEGER,
			price FLOAT,
			mfg_date DATE,
			exp_date DATE,
			distributor VARCHAR,
			created_at DATETIME,
			
			product_id INTEGER NOT NULL,
			CONSTRAINT fk_product
			FOREIGN KEY (product_id)
			REFERENCES products(id)
			ON DELETE CASCADE
		);"
	)
	db.query("CREATE INDEX IF NOT EXISTS ix_batch_batch_no ON batch (batch_no);")
	db.query("CREATE INDEX IF NOT EXISTS ix_batch_exp_date ON batch (exp_date);")
	db.query("CREATE INDEX IF NOT EXISTS ix_batch_distributor ON batch (distributor);")
	db.query("CREATE INDEX IF NOT EXISTS ix_batch_created_at ON batch (created_at);")

	db.query(
		"CREATE TABLE IF NOT EXISTS product_bill (
			id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
			name VARCHAR,
			bill VARCHAR,
			total_amount FLOAT,
			discount FLOAT,
			net_amount FLOAT,
			bill_date DATETIME,
			is_enabled BOOLEAN
		);"
	)
	db.query("CREATE INDEX IF NOT EXISTS ix_product_bill_bill_date ON product_bill (bill_date);")

	db.query(
		"CREATE TABLE IF NOT EXISTS service_bill (
			id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
			name VARCHAR,
			bill VARCHAR,
			total_amount FLOAT,
			discount FLOAT,
			net_amount FLOAT,
			bill_date DATETIME,
			is_enabled BOOLEAN
		);"
	)
	db.query("CREATE INDEX IF NOT EXISTS ix_service_bill_bill_date ON service_bill (bill_date);")

func raise_alert(msg: String) -> void:
	message_box.dialog_text = msg
	message_box.popup_centered()

func set_column_alignment(row: TreeItem, cols: Array[int]):
	for i in cols:
		row.set_text_alignment(i, HORIZONTAL_ALIGNMENT_RIGHT)
