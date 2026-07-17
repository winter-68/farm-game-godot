# T38：鱼饵系统

> 在 T37 钓鱼等级基础上，新增鱼饵机制——用农作物制作鱼饵，鱼饵影响钓鱼经验加成和稀有鱼出现概率。

## 任务目标

让农场产出（作物）与钓鱼系统联动，形成"种地→收鱼饵→钓鱼更强→卖鱼"的完整循环。鱼饵分为 3 个等级，高级鱼饵需要稀有作物合成。

## 前置条件

- T36 完成：鱼能进背包、出售、图鉴
- T37 完成：钓鱼等级和经验系统
- 现有作物：土豆、番茄、草莓 + 基础作物（通过 ItemDatabase）
- `InventoryManager` 有 `add_item()` / `remove_item()` / `has_item()` 方法

## 需要新增的文件

| 文件 | 说明 |
|------|------|
| `scripts/data/bait_data.gd` | 鱼饵数据类 |
| `scripts/autoload/bait_database.gd` | 鱼饵数据库（autoload） |
| `resources/bait/bait_basic.tres` | 基础鱼饵 |
| `resources/bait/bait_quality.tres` | 优质鱼饵 |
| `resources/bait/bait_legend.tres` | 传说鱼饵 |

## 需要修改的文件

| 文件 | 改动 |
|------|------|
| `scripts/data/item_data.gd` | `Type` 枚举新增 `BAIT` |
| `scripts/autoload/item_database.gd` | 加载鱼饵资源，新增 `get_bait()` 方法 |
| `scripts/autoload/event_bus.gd` | 新增信号 `bait_used(bait_id: StringName)` |
| `scripts/ui/fishing_minigame.gd` | 开始钓鱼时检查背包中当前选中物品是否为鱼饵，消耗 1 个鱼饵，应用加成效果 |
| `scripts/ui/shop_ui.gd` | 商店购买列表新增 3 种鱼饵（买入价格分别为 20/60/150 金币） |
| `scripts/ui/inventory_ui.gd` | 背包中鱼饵物品显示中文名称和鱼饵图标 |
| `scripts/ui/hud.gd` + `scenes/ui/hud.tscn` | 钓鱼小游戏中显示当前使用的鱼饵名称 |

## 详细设计

### 1. BaitData（数据类）

```
class_name BaitData extends Resource

@export var bait_id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var buy_price: int = 0
@export var sell_price: int = 0
@export var xp_multiplier: float = 1.0     # 经验倍率
@export var rare_bonus: float = 0.0        # 稀有鱼出现概率加成（0.0–0.3）
@export var description: String = ""
```

### 2. 鱼饵数值

| 鱼饵 | buy_price | sell_price | xp_multiplier | rare_bonus | 制作材料（可选扩展） |
|------|-----------|------------|---------------|------------|---------------------|
| 基础鱼饵 | 20 | 8 | 1.0 | 0.0 | — |
| 优质鱼饵 | 60 | 25 | 1.3 | 0.1 | — |
| 传说鱼饵 | 150 | 60 | 1.8 | 0.25 | — |

> 注：T38 先做商店购买，制作配方留接口（`craft_recipe: Dictionary`）后续扩展。

### 3. 钓鱼小游戏修改

在 `fishing_minigame.gd` 的 `_on_fishing_started()` 中：

```
1. 检查 InventoryManager.get_selected() 的 item_id
2. 如果是鱼饵类型（ItemData.type == BAIT）:
   - 消耗 1 个: InventoryManager.remove_item(item_id, 1)
   - 记录当前鱼饵的 xp_multiplier 和 rare_bonus
   - 显示"使用：[鱼饵名]"提示
3. 如果不是鱼饵:
   - 使用默认值 xp_multiplier=1.0, rare_bonus=0.0
```

在 `_finish_success()` 中：
```
1. 正常 emit fish_caught
2. 额外 emit bait_used(bait_id) 信号
3. FishingManager.add_xp() 时乘以 xp_multiplier
4. _pick_fish() 时 rare_bonus 叠加到稀有鱼权重上
```

### 4. 鱼饵选择权（快捷栏）

鱼饵通过快捷栏选中：玩家在快捷栏切换到鱼饵物品，钓鱼时自动使用。

**不需要**单独的鱼饵 UI 或装备槽——复用现有快捷栏选中机制。

### 5. 商店

在 shop_ui.gd 的 `_refresh_buy()` 中，商店列表新增 3 种鱼饵（buy_price > 0 即自动出现）。

### 6. 存档

鱼饵作为背包物品自然存档（通过 `InventoryManager.slots`），无需额外存档字段。

### 7. 签名兼容

- 不修改 `fish_caught` 信号签名
- `bait_used` 为新增信号，不影响现有逻辑
- `fishing_manager.gd` 的 `add_xp()` 新增可选参数 `multiplier: float = 1.0`

## 实现原则

- BaitDatabase 作为新 autoload，注册在 ItemDatabase 之后
- 只监听 EventBus，不直接引用其他管理器
- 不改变现有 EventBus 已有信号签名
- 保持占位色块，不引入外部美术或音频
- `craft_recipe` 字段预留但 T38 不实现制作逻辑

## 验收标准

1. Godot 启动无红色报错
2. 商店能买到 3 种鱼饵，价格正确
3. 背包中鱼饵显示中文名称和类型
4. 快捷栏选中鱼饵后去钓鱼，HUD 显示"使用：xxx"
5. 使用鱼饵钓鱼成功后，经验值按 xp_multiplier 倍率增加
6. 使用优质/传说鱼饵时，稀有鱼出现概率明显提高
7. 鱼饵消耗正确（每次钓鱼用掉 1 个）
8. 不使用鱼饵（快捷栏选中非鱼饵物品）时，钓鱼正常但无加成
9. 存档→读档后背包中的鱼饵保留

## 给 Codex 的执行提示词

```
在 Project Sprout 中实现 T38 鱼饵系统。

1. 新增 bait_data.gd 数据类，字段：bait_id, display_name, icon, buy_price, sell_price, xp_multiplier, rare_bonus, description。
2. 新增 bait_database.gd autoload，加载 3 个鱼饵 .tres 资源（bait_basic/bait_quality/bait_legend），注册在 ItemDatabase 之后。
3. item_data.gd 的 Type 枚举新增 BAIT。
4. item_database.gd 加载鱼饵资源，新增 get_bait(bait_id) 方法。
5. event_bus.gd 新增 bait_used(bait_id) 信号。
6. 修改 fishing_minigame.gd：开始钓鱼时检查快捷栏选中是否为鱼饵，是则消耗 1 个并记录加成；成功钓鱼时经验乘以 xp_multiplier，鱼种选择叠加 rare_bonus。
7. fishing_manager.gd 的 add_xp 新增 multiplier 参数（默认 1.0）。
8. shop_ui.gd 商店购买列表自动显示鱼饵（buy_price > 0）。
9. inventory_ui.gd 对鱼饵显示中文名称。
10. hud.gd 在钓鱼小游戏中显示当前使用的鱼饵名称。

鱼饵数值：基础(买20, 1x经验, 0加成)、优质(买60, 1.3x, 0.1加成)、传说(买150, 1.8x, 0.25加成)。
完成后在 Godot 中确认无红色报错。
```
