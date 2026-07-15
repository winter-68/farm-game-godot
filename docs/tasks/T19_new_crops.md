# T19：新作物数据（土豆/番茄/草莓）

> 通用约束见 [../README.md](../README.md)。批次 D 第 2 个任务。

## 任务目标

新增 3 种作物（土豆/番茄/草莓）的数据资源，包含季节限制、不同成长周期、再生属性。修改 `CropData` 增加 `allowed_seasons` 字段。绿豆改为全季节可种。

## 需要创建/修改的文件

- 修改 `scripts/data/crop_data.gd`：增加 `@export var allowed_seasons: Array[String] = []`（空=全季节）。
- 修改 `resources/crops/crop_greenbean.tres`：设置 `allowed_seasons = []`（全季节）。
- 创建 `resources/crops/crop_potato.tres` + 对应物品资源。
- 创建 `resources/crops/crop_tomato.tres` + 对应物品资源。
- 创建 `resources/crops/crop_strawberry.tres` + 对应物品资源。
- 修改 `scripts/autoload/item_database.gd`：`_setup_items()` 增加新物品预加载。

## 不要修改的文件

- `event_bus.gd`、管理器脚本、UI 脚本、场景、`player.gd`、`FarmTile`。

## 实现要求

1. **`CropData.gd`**：
   - 新增 `@export var allowed_seasons: Array[String] = []`
   - 注释：空数组表示全季节可种；非空则只能在列表内季节种植（如 `["春", "秋"]`）
2. **作物资源**（参数见下表）：
   | 作物 ID | 显示名 | 阶段数 | 每阶段天数 | 产出 ID | 产出量 | 再生 | 回退阶段 | 允许季节 |
   |---------|--------|--------|------------|---------|--------|------|----------|----------|
   | crop_greenbean | 绿豆 | 3 | 2 | produce_greenbean | 1 | false | 0 | [] |
   | crop_potato | 土豆 | 4 | 2 | produce_potato | 2 | false | 0 | ["春","秋"] |
   | crop_tomato | 番茄 | 4 | 3 | produce_tomato | 1 | **true** | 1 | ["夏"] |
   | crop_strawberry | 草莓 | 5 | 2 | produce_strawberry | 1 | false | 0 | ["春"] |
3. **对应物品资源**（种子 + 产出物，共 6 个 `.tres`）：
   | 物品 ID | 类型 | 显示名 | 购买价 | 出售价 | 关联作物 |
   |---------|------|--------|--------|--------|----------|
   | seed_potato | SEED | 土豆种子 | 50 | 12 | crop_potato |
   | produce_potato | PRODUCE | 土豆 | 0 | 80 | (无) |
   | seed_tomato | SEED | 番茄种子 | 30 | 7 | crop_tomato |
   | produce_tomato | PRODUCE | 番茄 | 0 | 60 | (无) |
   | seed_strawberry | SEED | 草莓种子 | 100 | 25 | crop_strawberry |
   | produce_strawberry | PRODUCE | 草莓 | 0 | 120 | (无) |
4. **`ItemDatabase._setup_items()`**：
   - 增加 `preload` 新 6 个资源，`add_item` 注册（照绿豆格式）
   - 种子的 `linked_crop_id` 正确指向作物
5. **占位视觉**：作物 `.tscn` 已有的 `PlaceholderTexture2D` 颜色可以沿用，或自行微调（番茄=红、土豆=褐、草莓=粉），不强制要求。

## 验收标准

- 新游戏 → 打开商店 → 购买区出现 4 种种子（绿豆/土豆/番茄/草莓），价格正确。
- 春季可买土豆/草莓种子；夏季可买番茄种子（T20 会加季节过滤，本任务先不管，全部可买即可）。
- 种下土豆/番茄/草莓 → 浇水睡觉 → 成长阶段数/天数符合表格；番茄成熟收获后**回到阶段 1**（再生），土豆/草莓收获后消失。
- 收获产出物 → 商店出售 → 价格正确。
- 无报错。

## Godot 测试步骤

1. F5 新游戏 → B 开商店 → 确认 4 种种子都在，价格对。
2. 买土豆种子 → 种下 → 浇水睡觉 6 天（2×3）→ 收获 → 背包土豆×2，出售验证 80/个。
3. 买番茄种子 → 种下 → 浇水睡觉 9 天（3×3）→ 收获 → 作物回到小（阶段 1）不消失，再浇水 6 天再收一次。
4. 买草莓种子 → 种下 → 浇水睡觉 8 天（2×4）→ 收获 → 背包草莓×1，出售验证 120。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）增加 3 种新作物数据。

1) scripts/data/crop_data.gd：增加 @export var allowed_seasons: Array[String] = []
   # 空=全季节，非空=限定季节列表
2) 修改 resources/crops/crop_greenbean.tres：allowed_seasons=[]
3) 创建 resources/crops/crop_potato.tres：
   crop_id="crop_potato", display_name="土豆", stage_count=4, days_per_stage=2,
   produce_item_id="produce_potato", produce_amount=2, regrows=false, regrow_to_stage=0,
   allowed_seasons=["春","秋"]
4) 创建 resources/crops/crop_tomato.tres：
   crop_id="crop_tomato", display_name="番茄", stage_count=4, days_per_stage=3,
   produce_item_id="produce_tomato", produce_amount=1, regrows=true, regrow_to_stage=1,
   allowed_seasons=["夏"]
5) 创建 resources/crops/crop_strawberry.tres：
   crop_id="crop_strawberry", display_name="草莓", stage_count=5, days_per_stage=2,
   produce_item_id="produce_strawberry", produce_amount=1, regrows=false, regrow_to_stage=0,
   allowed_seasons=["春"]
6) 创建 6 个物品资源（参见任务卡表格）：
   resources/items/seed_potato.tres, produce_potato.tres,
   seed_tomato.tres, produce_tomato.tres,
   seed_strawberry.tres, produce_strawberry.tres
7) scripts/autoload/item_database.gd._setup_items()：
   preload 新 6 个资源 + add_item 注册（照绿豆格式）

约束：不要修改 event_bus.gd、管理器脚本、UI 脚本、场景、player.gd、FarmTile。
完成后：商店有 4 种种子，种植/成长/收获/再生/出售均正确，无报错。
```
