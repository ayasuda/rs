class_name Metric
extends RefCounted
## ラーメンの評価軸（spec/recipe.md）。評価ベクトルは Key の順に並んだ PackedInt32Array で持つ。
## 先頭 FEATURE_COUNT 個が特徴 8 軸（0〜65535、顧客ごとに理想値がある）、
## 残りが出来 2 軸（0〜255、誰にとっても高いほど良い）。

enum Key {
	UMAMI,       # 旨味
	AROMA,       # 香り
	SALT,        # 塩味
	FAT,         # 脂の量
	SWEET,       # 甘味
	SPICY,       # 刺激
	APPEARANCE,  # 見た目の美しさ
	VOLUME,      # ボリューム感
	CREATIVE,    # 創作性（出来）
	HARMONY,     # 調和性（出来）
}

const COUNT := 10
const FEATURE_COUNT := 8
const QUALITY_KEYS: Array[int] = [Key.CREATIVE, Key.HARMONY]
const MAX_VALUE := 65535  # 特徴 8 軸：uint16
const QUALITY_MAX := 255  # 出来 2 軸：uint8

const IDS: Array[String] = [
	"umami", "aroma", "salt", "fat", "sweet",
	"spicy", "appearance", "volume", "creative", "harmony",
]
const LABELS: Array[String] = [
	"旨味", "香り", "塩味", "脂の量", "甘味",
	"刺激", "見た目", "ボリューム", "創作性", "調和性",
]


static func zeros() -> PackedInt32Array:
	var v := PackedInt32Array()
	v.resize(COUNT)
	v.fill(0)
	return v


static func is_feature(key: int) -> bool:
	return key < FEATURE_COUNT


## {"umami": 6000, ...} 形式の辞書をベクトルに変換する。無い軸は 0。
## 値はデータ上の生の値のまま（出来 2 軸も 0〜255 に縮めない）。
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
