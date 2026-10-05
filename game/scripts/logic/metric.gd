class_name Metric
extends RefCounted
## ラーメンの評価軸（10軸）。評価ベクトルは Key の順に並んだ PackedInt32Array で持つ。

enum Key {
	UMAMI,       # 旨味強度
	AROMA,       # 香りの強さ
	SALT,        # 塩味の強さ
	FAT,         # 脂の量（こってり感）
	SWEET,       # 甘味の存在感
	SPICY,       # 刺激・辛味
	CREATIVE,    # 個性・創作性
	APPEARANCE,  # 見た目の美しさ
	VOLUME,      # ボリューム感
	HARMONY,     # 調和性
}

const COUNT := 10
const MAX_VALUE := 65535  # 仕様上は uint16

const IDS: Array[String] = [
	"umami", "aroma", "salt", "fat", "sweet",
	"spicy", "creative", "appearance", "volume", "harmony",
]
const LABELS: Array[String] = [
	"旨味", "香り", "塩味", "脂の量", "甘味",
	"刺激", "創作性", "見た目", "ボリューム", "調和性",
]


static func zeros() -> PackedInt32Array:
	var v := PackedInt32Array()
	v.resize(COUNT)
	v.fill(0)
	return v


## {"umami": 6000, ...} 形式の辞書を評価ベクトルに変換する。無い軸は 0。
static func ints_from_dict(d: Dictionary) -> PackedInt32Array:
	var v := zeros()
	for i in COUNT:
		v[i] = clampi(int(d.get(IDS[i], 0)), 0, MAX_VALUE)
	return v


static func floats_from_dict(d: Dictionary, default_value: float = 0.0) -> PackedFloat64Array:
	var v := PackedFloat64Array()
	v.resize(COUNT)
	for i in COUNT:
		v[i] = float(d.get(IDS[i], default_value))
	return v
