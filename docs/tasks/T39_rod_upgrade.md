# T39：钓鱼竿升级系统

> 在 T37 钓鱼等级 + T38 鱼饵基础上，新增钓鱼竿购买/升级机制。更好的鱼竿降低小游戏难度、提升经验加成，与等级和鱼饵形成三重成长叠加。

## 任务目标

玩家可在商店购买更好的钓鱼竿，鱼竿影响：①鱼移动速度（降低难度）②经验倍率 ③稀有鱼出现概率。鱼竿与等级、鱼饵三者叠加，让钓鱼有丰富的成长维度。

## 前置条件

- T37 完成：钓鱼等级、FishingManager
- T38 完成：鱼饵系统、bait_data.gd
- 商店系统（shop_ui.gd）已支持 buy_price 购买

## 需要新增的文件

| 文件 | 说明 |
|------|------|
| `scripts/data/rod_data.gd` | 鱼竿数据类 |
| `scripts/autoload/rod_database.gd` | 鱼竿数据库（autoload） |
| `resources/rod/rod_basic.tres` | 初始鱼竿 |
| `resources/rod/rod_iron.tres` | 铁竿 |
| `resources/rod/rod_gold.tres` | 金竿 |

## 需要修改的文件

| 文件 | 改动 |
|------|------|
| `scripts/data/item_data.gd` | `Type` 枚举新增 `ROD` |
| `scripts/autoload/item_database.gd` | 加载鱼竿资源 |
| `scripts/autoload/event_bus.gd` | 新增信号 `rod_changed(new_rod_id: StringName)` |
| `scripts/autoload/fishing_manager.gd` | 新增 `current_rod_id: StringName` 字段，存档/读档包含，`new_game()` 重置为初始鱼竿 |
| `scripts/ui/fishing_minigame.gd` | 读取当前鱼竿数据，应用鱼竿的速度修正、经验倍率和稀有加成（与鱼饵加成叠加） |
| `scripts/ui/shop_ui.gd` | 商店购买列表显示鱼竿（买过/已拥有的竿不重复显示） |
| `scripts/ui/hud.gd` + `scenes/ui/hud.tscn` | 钓鱼小游戏中显示当前使用的鱼竿名称 |
| `scripts/autoload/save_manager.gd` | 存档包含 `current_rod_id` |

## 详细设计

### 1. RodData（数据类）

```
class_name RodData extends Resource

@export var rod_id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var buy_price: int = 0
@export var sell_price: int = 0
@export var speed_modifier: float = 1.0    # 鱼速度乘数（<1 = 鱼更慢 = 更容易）
@export var xp_multiplier: float = 1.0    # 经验倍率（与鱼饵叠加）
@export var rare_bonus: float = 0.0       # 稀有鱼概率加成（与鱼饵叠加）
@export var required_level: int = 0       # 购买所需钓鱼等级（0=无限制）
@export var description: String = ""
```

### 2. 鱼竿数值

| 鱼竿 | buy_price | speed_modifier | xp_multiplier | rare_bonus | required_level |
|------|-----------|----------------|---------------|------------|----------------|
| 初始鱼竿 | 0（免费） | 1.0 | 1.0 | 0.0 | 0 |
| 铁竿 | 300 | 0.75 | 1.2 | 0.05 | 3 |
| 金竿 | 800 | 0.55 | 1.5 | 0.15 | 6 |

### 3. FishingManager 扩展

```
var current_rod_id: StringName = &"rod_basic"

func set_rod(rod_id: StringName) -> void:
    current_rod_id = rod_id
    EventBus.rod_changed.emit(rod_id)

func get_current_rod() -> RodData:
    return RodDatabase.get_rod(current_rod_id)

to_save_dict() 新增: "current_rod_id": String(current_rod_id)
load_from_dict() 新增: current_rod_id = StringName(data.get("current_rod_id", "rod_basic"))
new_game() 新增: current_rod_id = &"rod_basic"
```

### 4. 钓鱼小游戏修改

在 `_on_bite_timer_timeout()` 中（鱼速度初始化时）：

```
var rod = RodDatabase.get_rod(FishingManager.current_rod_id)
var bait = _get_current_bait()  # T38 已有

# 鱼速度 = 基础值 × 等级修正 × 鱼竿修正
_fish_velocity = _rng.randf_range(45.0 + level * 3.0, 80.0 + level * 5.0) * rod.speed_modifier
```

在 `_finish_success()` 中：

```
var rod = RodDatabase.get_rod(FishingManager.current_rod_id)
var bait = _get_current_bait()

# 经验 = 基础 × 鱼竿倍率 × 鱼饵倍率
FishingManager.add_xp(base_xp, &"fish", rod.xp_multiplier * bait.xp_multiplier)

# 稀有加成 = 鱼竿 + 鱼饵
total_rare_bonus = rod.rare_bonus + bait.rare_bonus
```

在 `_pick_fish()` 中：

```
# 鱼的权重 = 基础权重 + total_rare_bonus（按稀有度加权）
```

### 5. 商店逻辑

shop_ui.gd 的 `_refresh_buy()` 中：
- 显示所有 `buy_price > 0` 的鱼竿
- 如果鱼竿 `required_level > FishingManager.get_level()`，显示为灰色并标注"需要 Lv.X"
- 已购买过的鱼竿（`current_rod_id == rod.rod_id`）不显示或显示"已装备"

### 6. 鱼竿切换

**不做装备界面**，简化设计：
- 商店购买鱼竿后自动装备（替换当前鱼竿）
- 同一时间只能拥有一根鱼竿（新买自动替换旧的）
- 旧鱼竿不退回金币（鼓励规划购买）

> 后续如果需要多鱼竿持有/切换，可以扩展为背包物品。

### 7. HUD 显示

钓鱼小游戏中 HUD 显示：
```
鱼 Lv.X | [鱼竿名] | 使用：[鱼饵名]
```

### 8. 存档兼容

- `current_rod_id` 为可选字段
- 老存档缺失时默认 `rod_basic`

## 实现原则

- RodDatabase 作为新 autoload，注册在 BaitDatabase 之后
- 只监听 EventBus，不直接引用其他管理器
- 不修改已有信号签名
- 保持占位色块，不引入外部美术或音频

## 验收标准

1. Godot 启动无红色报错
2. 商店显示鱼竿列表，等级不够时灰色标注
3. 购买鱼竿后自动装备，HUD 显示新鱼竿名
4. 使用铁竿/金竿时，鱼移动明显变慢
5. 使用鱼竿 + 鱼饵时，经验倍率和稀有加成正确叠加
6. 存档→读档后鱼竿保持不变
7. 新游戏从初始鱼竿开始

## 给 Codex 的执行提示词

```
在 Project Sprout 中实现 T39 钓鱼竿升级系统。

1. 新增 rod_data.gd 数据类，字段：rod_id, display_name, icon, buy_price, sell_price, speed_modifier, xp_multiplier, rare_bonus, required_level, description。
2. 新增 rod_database.gd autoload，加载 3 个鱼竿 .tres 资源（rod_basic/rod_iron/rod_gold），注册在 BaitDatabase 之后。
3. item_data.gd 的 Type 枚举新增 ROD。
4. item_database.gd 加载鱼竿资源。
5. event_bus.gd 新增 rod_changed(rod_id) 信号。
6. fishing_manager.gd 新增 current_rod_id 字段，默认 "rod_basic"，存档/读档包含，new_game 重置。
7. 修改 fishing_minigame.gd：读取当前鱼竿的 speed_modifier 影响鱼速，xp_multiplier 和 rare_bonus 与鱼饵叠加。
8. shop_ui.gd 显示鱼竿（required_level > 当前等级时灰色不可买，已装备不重复显示）。
9. hud.gd 钓鱼小游戏中显示当前鱼竿名。
10. fish .tres 中 _pick_fish 的权重计算叠加鱼竿 rare_bonus。

鱼竿数值：初始(免费, 1x速度, 1x经验, 0加成)、铁竿(300金, 0.75x速度, 1.2x经验, 0.05加成, 需Lv3)、金竿(800金, 0.55x速度, 1.5x经验, 0.15加成, 需Lv6)。
完成后在 Godot 中确认无红色报错。
```
