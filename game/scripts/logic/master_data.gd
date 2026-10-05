class_name MasterData
extends RefCounted
## data/*.json のマスターデータを読み込んで保持する。

const COMPONENT_TYPES: Array[String] = ["noodle", "soup", "tare", "oil", "topping", "plating"]
const COMPONENT_TYPE_LABELS := {
	"noodle": "麺", "soup": "スープ", "tare": "かえし",
	"oil": "香味油", "topping": "具材", "plating": "盛り付け",
}

static var _loaded := false
static var components := {}              # id -> {id, type, label, cost, contribution}
static var component_ids_by_type := {}   # type -> Array[String]
static var customers: Array[Dictionary] = []
static var customers_by_id := {}
static var locations: Array[Dictionary] = []
static var sides: Array[Dictionary] = []


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true

	for type in COMPONENT_TYPES:
		component_ids_by_type[type] = []
	for raw in _read_json("res://data/components.json"):
		var c := {
			"id": str(raw["id"]),
			"type": str(raw["type"]),
			"label": str(raw["label"]),
			"cost": int(raw["cost"]),
			"contribution": Metric.ints_from_dict(raw.get("contribution", {})),
		}
		components[c["id"]] = c
		component_ids_by_type[c["type"]].append(c["id"])

	for raw in _read_json("res://data/customers.json"):
		var rhythm: Array[float] = []
		for v in raw["rhythm"]:
			rhythm.append(float(v))
		var c := {
			"id": str(raw["id"]),
			"name": str(raw["name"]),
			"desc": str(raw["desc"]),
			"rhythm": rhythm,
			"budget": int(raw["budget"]),
			"price_sensitivity": float(raw["price_sensitivity"]),
			"fullness": float(raw["fullness"]),
			"side_affinity": float(raw["side_affinity"]),
			"weekday_mult": float(raw["weekday_mult"]),
			"weekend_mult": float(raw["weekend_mult"]),
			"pref": Metric.ints_from_dict(raw["pref"]),
			"weight": Metric.floats_from_dict(raw["weight"], 0.5),
		}
		customers.append(c)
		customers_by_id[c["id"]] = c

	for raw in _read_json("res://data/locations.json"):
		var pool := {}
		for cid in raw["customers"]:
			var entry: Dictionary = raw["customers"][cid]
			pool[cid] = {
				"potential": int(entry["potential"]),
				"base_rate": float(entry["base_rate"]),
			}
		locations.append({
			"id": str(raw["id"]),
			"name": str(raw["name"]),
			"desc": str(raw["desc"]),
			"rent": int(raw["rent"]),
			"seats": int(raw["seats"]),
			"deposit": int(raw["deposit"]),
			"customers": pool,
		})

	for raw in _read_json("res://data/sides.json"):
		sides.append({
			"id": str(raw["id"]),
			"label": str(raw["label"]),
			"cost": int(raw["cost"]),
			"price": int(raw["price"]),
			"volume": float(raw["volume"]),
		})


static func location(id: String) -> Dictionary:
	for loc in locations:
		if loc["id"] == id:
			return loc
	return {}


static func component_label(id: String) -> String:
	var c = components.get(id)
	return "（不明な素材）" if c == null else str(c["label"])


static func _read_json(path: String) -> Array:
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if data == null or not (data is Array):
		push_error("マスターデータの読み込みに失敗: %s" % path)
		return []
	return data
