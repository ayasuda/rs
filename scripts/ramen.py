from collections import defaultdict

# 評価軸（10軸）
EVAL_KEYS = [
    "umami", "aroma", "saltiness", "fat", "sweetness",
    "spiciness", "originality", "visual", "volume", "harmony"
]

# 寄与値マスタ例（構成要素 → 評価軸への影響）
INGREDIENT_EFFECTS = {
    "chicken_broth": {
        "umami": 14000, "fat": 8000
    },
    "momi_ji": {
        "umami": 10000, "fat": 12000
    },
    "niboshi": {
        "umami": 9000, "aroma": 5000
    },
    "black_garlic_oil": {
        "aroma": 18000, "fat": 10000, "originality": 8000
    },
    "thick_char_siu": {
        "volume": 15000, "umami": 6000, "fat": 8000
    },
    "ajitama": {
        "sweetness": 5000, "visual": 7000
    },
    "yuzu_peel": {
        "aroma": 12000, "originality": 10000
    },
    "pretty_bowl": {
        "visual": 15000
    }
}

# ラーメンレシピ構成（構成要素のIDを並べる）
ramen_recipe = [
    "chicken_broth", "momi_ji", "black_garlic_oil",
    "thick_char_siu", "ajitama", "pretty_bowl"
]

# 評価値を生成（uint16上限は65535でクリップ）


def evaluate_ramen(recipe):
    scores = defaultdict(int)

    for item in recipe:
        effects = INGREDIENT_EFFECTS.get(item, {})
        for key, value in effects.items():
            scores[key] += value

    # 未定義軸は0、上限でクリップ
    return {
        key: min(scores.get(key, 0), 65535) for key in EVAL_KEYS
    }


# 評価実行
result = evaluate_ramen(ramen_recipe)
for key, val in result.items():
    print(f"{key:>12}: {val}")
