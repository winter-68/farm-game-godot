# T37：钓鱼等级与经验系统

> 在 T36 钓鱼闭环（鱼→背包→出售→图鉴）基础上，新增钓鱼经验和等级系统。

## 任务目标

实现钓鱼经验累积和等级成长，让钓鱼有长线成长感。钓到鱼获得经验值，积累到阈值升级；等级影响可钓到的鱼种范围和小游戏难度。

## 前置条件

- T36 已完成：鱼能进入背包、出售、图鉴
- `FishData` 有 `rarity` 字段（0.0–1.0）
- `EventBus` 已有 `fish_caught(fish_data)` 信号
- `fishing_minigame.gd` 负责钓鱼小游戏逻辑

## 需要新增的文件

| 文件 | 说明 |
|------|------|
| `scripts/autoload/fishing_manager.gd` | 钓鱼等级/经验管理器（autoload） |

## 需要修改的文件

| 文件 | 改动 |
|------|------|
| `scripts/autoload/event_bus.gd` | 新增信号：`fishing_leveled_up(new_level: int)`、`fishing_xp_gained(amount: int, source: StringName)` |
| `scripts/ui/fishing_minigame.gd` | 成功钓鱼后调用 `FishingManager.add_xp()`；鱼种选择受等级影响（高级鱼需等级达标才能出现）；等级越高，鱼移动速度上限适当增加（难度随等级提升） |
| `scripts/autoload/inventory_manager.gd` | 无改动（保持原有 fish_caught 监听） |
| `scenes/ui/hud.tscn` + `scripts/ui/hud.gd` | HUD 上显示钓鱼等级和经验条（小图标 + 数字 + 进度条） |
| `scripts/autoload/save_manager.gd` | 存档/读档包含 `fishing_level` 和 `fishing_xp` |
| `resources/data/fish/` 下 5 个鱼 .tres | 每个鱼新增 `min_level: int` 字段（默认 0，高稀有度鱼设更高） |

## 需要修改的 Resource

| 文件 | 改动 |
|------|------|
| `scripts/data/fish_data.gd` | 新增 `@export var min_level: int = 0` 和 `@export var xp_reward: int = 0`（为空时按稀有度自动算） |

## 详细设计

### 1. FishingManager（新 autoload）

```
class_name: 无（extends Node）
autoload 名: FishingManager

状态:
  level: int = 1
  xp: int = 0

常量:
  LEVEL_THRESHOLDS: Array[int] = [0, 20, 50, 100, 170, 260, 380, 530, 720, 960]
  （共 10 级，每级所需累计经验递增）

方法:
  add_xp(amount: int) -> void
    xp += amount
    检查是否升级（while xp >= threshold for next level）
    每升一级: emit EventBus.fishing_leveled_up(level)

  get_level() -> int
  get_xp() -> int
  get_xp_for_next_level() -> int （返回距离下一级还需多少经验）
  get_xp_progress() -> float （0.0–1.0，当前经验在本级进度）

信号监听:
  fish_caught -> 根据 fish_data.xp_reward（或按 rarity 计算）调用 add_xp()

存档:
  to_save_dict() -> {"fishing_level": level, "fishing_xp": xp}
  load_from_dict(dict: Dictionary) -> void
```

### 2. 经验值计算

优先使用 `FishData.xp_reward`（如果 > 0），否则按稀有度自动算：
- rarity 0.0–0.3（普通）: 5 XP
- rarity 0.3–0.6（少见）: 10 XP
- rarity 0.6–0.8（稀有）: 20 XP
- rarity 0.8–1.0（传说）: 40 XP

### 3. 等级对钓鱼的影响

**鱼种出现条件**：`_pick_fish()` 选择鱼时，跳过 `min_level > 当前等级` 的鱼。

**小游戏难度**（鱼移动速度）：
- 当前：`_rng.randf_range(45.0, 95.0)`
- 修改为：`_rng.randf_range(45.0 + level * 3, 80.0 + level * 5)`
  - 等级 1: 48–85（比现在略难）
  - 等级 5: 60–105
  - 等级 9: 72–125

### 4. 鱼的 min_level 设置

| 鱼 | rarity | min_level | xp_reward |
|----|--------|-----------|-----------|
| 鲫鱼 (crucian) | 0.1 | 0 | 5 |
| 鲤鱼 (carp) | 0.2 | 0 | 5 |
| 鲈鱼 (bass) | 0.4 | 2 | 10 |
| 金鱼 (goldfish) | 0.6 | 4 | 20 |
| 河豚 (pufferfish) | 0.8 | 6 | 40 |

### 5. HUD 显示

在 HUD 右侧（时间/天气下方或旁边）新增小型钓鱼等级显示：
- 标签: Lv.X
- 经验条: 窄进度条（宽度约 40px）
- 仅在钓鱼相关活动时或始终显示（建议始终显示，简洁一行）

### 6. 存档兼容

- `fishing_level` 和 `fishing_xp` 为可选字段
- 读档时若缺失，默认 level=1, xp=0（老存档兼容）

## 实现原则

- FishingManager 作为新 autoload，注册在 InventoryManager 之后、CollectionManager 之前
- 只监听 EventBus，不直接持有其他管理器引用
- 不改变现有 EventBus 已有信号的签名
- 保持占位色块，不引入外部美术或音频
- 不修改 `item_data.gd`、`item_database.gd`、`inventory_manager.gd` 的核心逻辑

## 验收标准

1. Godot 启动无红色报错
2. 钓到鱼后 HUD 显示经验增加动画（或数字变化）
3. 累积足够经验后自动升级，HUD 等级数字更新
4. 等级不够时，高级鱼不会出现在 `_pick_fish()` 结果中
5. 等级越高，钓鱼小游戏鱼移动越快
6. 存档→读档后钓鱼等级和经验恢复正确
7. 新建游戏从 Level 1、0 XP 开始

## 给 Codex 的执行提示词

```
在 Project Sprout 中实现 T37 钓鱼等级与经验系统。

新增 FishingManager autoload，追踪 level 和 xp。
修改 fish_data.gd 新增 min_level 和 xp_reward 字段。
修改 fishing_minigame.gd：钓到鱼时调用 FishingManager.add_xp()，鱼种选择过滤 min_level 不达标的鱼，鱼移动速度随等级增加。
修改 event_bus.gd 新增 fishing_leveled_up 和 fishing_xp_gained 信号。
在 HUD 显示钓鱼等级 Lv.X 和经验进度条。
fish .tres 资源设置 min_level 和 xp_reward（鲫鱼鲤鱼Lv0，鲈鱼Lv2，金鱼Lv4，河豚Lv6）。
存档/读档包含 fishing_level 和 fishing_xp，缺失时默认 Lv1/0xp。
FishingManager 注册在 InventoryManager 之后、CollectionManager 之前。
完成后在 Godot 中启动确认无红色报错。
```
