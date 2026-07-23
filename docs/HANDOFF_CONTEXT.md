# Project Sprout 开发交接文档

更新日期：2026-07-21  
项目根目录：`C:\Users\24623\project-sprout`  
引擎：Godot 4.x（当前本机运行的是 Godot 4.7.1 Steam 版；项目设计目标为 Godot 4.3+）  
语言：GDScript  
项目类型：原创 2D 像素农场游戏

## 给新对话的启动信息

这是一个已经完成 MVP、季节、天气、收集、NPC、钓鱼和多轮可玩性/美术优化的 Godot 项目。继续开发前：

1. 先读取 `docs/README.md`、`docs/TECH_DESIGN.md`、`docs/BACKLOG.md` 和本文件。
2. 当前工作树不是干净状态，必须保留用户已有改动；不要执行 `git reset --hard`、`checkout --` 或批量删除。
3. 最近任务通常只允许修改任务卡列出的文件；若没有任务卡，先创建简短任务说明再改动。
4. 使用占位色块或项目内已有素材，不引入第三方插件和未授权外部资源。
5. 修改后用 Godot headless 加载主场景检查，再让用户在 Godot 中做需要人工操作的验收。

常用启动检查：

```powershell
$godot = 'E:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe'
& $godot --headless --path 'C:\Users\24623\project-sprout' --scene 'res://scenes/main/main.tscn' --quit-after 3
```

F5 的主场景是 `res://scenes/ui/main_menu.tscn`，需要从主菜单进入新游戏或继续游戏。

## 已完成的功能

### 核心农场循环（T0-T23）

- 项目初始化、目录结构、Autoload、EventBus、数据类和资源数据库。
- 玩家 WASD 移动、相机跟随、朝向保持、工具目标格高亮。
- TileMap 地面/农田层，耕地、浇水、播种、作物阶段成长和收获。
- 时间、天数、四季循环；季节限制种植和商店过滤。
- 背包、快捷栏、金币、商店出售/购买、种子与作物显示。
- Enter 睡觉、空格交互/收获、K 存档、L 读档。
- 存档包含时间、季节、背包、金币、农田、作物和玩家位置。
- 主菜单：新游戏、继续、退出；没有存档时继续按钮置灰。

### 天气和收集（T24-T29）

- `WeatherManager`：晴、多云、雨、雪，按季节概率每日随机。
- 雨天自动浇灌耕地，作物可依靠雨水成长。
- 雨/雪视觉 overlay 和今日天气提示。
- `CollectionManager`：作物、鱼类、统计、成就、存档和读档守卫。
- 收集面板用 C 打开；解锁 toast 按队列串行显示。

### NPC 与对话（T30-T33）

- NPC 数据、生成、随机漫游、碰撞避障、方向翻转和走路帧。
- 靠近 NPC 显示对话提示；对话 UI 有头像、名字、打字机效果。
- 对话期间冻结玩家；对话完成增加好感度。
- 好感度阶段信号、Toast、存档读档。

### 钓鱼（T34-T39）

- 鱼塘/钓鱼点、5 种鱼数据、钓鱼小游戏和成功/失败反馈。
- 鱼获进入背包、商店可出售、鱼类图鉴记录。
- 钓鱼等级和经验、稀有鱼等级门槛、等级效果。
- 鱼饵系统：基础/优质/传说鱼饵，经验和稀有率加成。
- 鱼竿升级：初始、铁竿、金竿，商店购买后自动装备。

### 可玩性、UI 和美术优化（T50-T86）

- 项目内素材接口、作物/鱼/物品图标、玩家和 NPC 像素素材导入。
- 全屏显示、暂停菜单、Esc 打开菜单并可退出全屏/返回游戏。
- HUD 体力、水壶余量、天气、金币、季节时间和快捷栏布局优化。
- 面板互斥和输入锁，避免背包/商店/料理/图鉴同时打开或穿透操作。
- 地标、路径、房屋、厨房、池塘和农田的可读性优化。
- 玩家/NPC alpha 裁切修复，解决透明洞和向左正常但其他方向半透明的问题。
- 房屋、商店、厨房、池塘和农田的空气墙/碰撞体。
- NPC 随机可行走路线，避免一直对着墙走。
- 家和厨房室内场景：靠近入口按 E 进入，室内出口返回室外。
- 地图背景美术 PNG：
  - `assets/sprites/world/exterior_map_art.png`
  - `assets/sprites/world/home_interior_art.png`
  - `assets/sprites/world/kitchen_interior_art.png`
- 背包 Tab 输入修复：Tab 使用正确的 Godot `keycode`，脚本也有直接 Tab 兜底识别。
- 背包槽位支持鼠标拖拽：拖到空槽或其他槽位可交换物品；双击食物可食用。

## 关键目录和职责

```text
project-sprout/
├─ project.godot                 # 主场景、显示设置、输入映射、Autoload
├─ docs/                         # 设计文档、Backlog、任务卡、本交接文档
├─ assets/sprites/               # 项目内像素素材和地图背景 PNG
├─ resources/                    # .tres 数据资源（作物、鱼、NPC、配方等）
├─ scenes/
│  ├─ main/main.tscn             # 游戏运行容器
│  ├─ ui/main_menu.tscn          # F5 进入的主菜单
│  ├─ ui/                        # HUD、Hotbar、背包、商店、图鉴、Toast 等
│  ├─ world/world.tscn           # 室外世界
│  ├─ world/interiors/            # 家和厨房室内场景
│  ├─ world/player/player.tscn   # 玩家场景
│  └─ npc/npc.tscn               # NPC 场景
└─ scripts/
   ├─ autoload/                  # 管理器单例
   ├─ data/                      # Resource 数据类
   ├─ world/                     # 世界、玩家、入口、作物视图、室内等
   ├─ npc/                       # NPC 控制和生成
   └─ ui/                        # UI 脚本和背包槽位拖拽脚本
```

### Autoload 顺序（不要随意调整）

`EventBus → ItemDatabase → BaitDatabase → RodDatabase → RecipeDatabase → TimeManager → InventoryManager → StaminaManager → WaterManager → UIStateManager → BuffManager → FishingManager → FarmManager → WeatherManager → CollectionManager → FriendshipManager → SaveManager → GameManager`

架构重点：

- FarmManager 只负责农田数据和信号；作物实例由 CropView 监听信号生成。
- FarmManager 的图层引用由 `world.gd` 的 `register_layers()` 注入，不要在管理器中搜索场景树。
- CropView 的 ground 引用由 `world.gd` 注入。
- UI 只读管理器状态，状态修改走管理器公开方法或 EventBus。
- 读档时先恢复 FarmManager 等数据，再 emit `game_loaded`，确保 CropView 重建使用新数据。

## 当前 Git 状态

已提交的稳定基线：

- `73dacfe` / tag `v0.5-gameplay-polish`：完成至 T68 的玩法和优化。
- 早期标签：`v0.1-mvp`（T0-T17）、`v0.4-collection`（T18-T29）。

T69-T86 的优化、美术导入、室内和背包拖拽目前仍在工作树中，尚未合并到新的 Git 提交。工作树中还会有 Godot 自动生成的 `.import`、`.uid` 以及 `tmp/` 文件；它们不要被误删。下一次准备打快照时，建议先人工检查并单独提交这些后续改动。

## 已知问题和注意事项

1. **需要人工回归测试的输入流程**：Tab 背包、Enter 睡觉、空格收获、E 对话/进入建筑、B 商店、C 图鉴、K/L 存读档。Headless 检查不能替代这些操作。
2. **地图背景仍是项目内生成/导入的整图 PNG**：地图上已有可行走区域和碰撞，但如果继续美术化，应优先将背景拆成可重复 Tile/装饰层，避免整图和动态农田、作物显示层发生遮挡关系。
3. **室外 GroundLayer 当前由 `world.gd` 构建后隐藏**，主要使用 `ExteriorDecor` 地图背景 PNG；调整地图尺寸或更换背景时要同步相机边界、农田坐标和碰撞体。
4. **农田入口是顶部中央的物理缺口和标记**，不是独立室内场景入口；如果未来要做独立农田区域，再新增场景/切换逻辑。
5. **部分旧资源/文档曾出现中文编码显示异常**。如果 Godot 编辑器或运行时出现乱码，统一把对应文本文件转换为 UTF-8，并核对场景中的 `text` 属性；不要仅凭 PowerShell 的错误编码判断文件损坏。
6. **当前工作树有大量来自美术导入的 PNG 修改**。继续替换人物素材前，先确认 Sprite2D 的纹理路径、裁切尺寸和左右/上下方向，避免再次出现人物透明洞或闪烁。
7. **背包拖拽当前实现的是整槽交换**，不是同类堆叠合并；如需合并堆叠，应在 `scripts/ui/inventory_ui.gd::swap_slots()` 增加同物品数量合并规则并尊重 `ItemData.max_stack`。
8. **新对话不要直接把 T40-T41 烹饪/料理当作已完成**。当前已完成的是料理数据库、料理 UI 的既有部分和钓鱼 T37-T39；若要继续扩展食物 Buff、食谱图鉴或解锁，先检查实际文件和任务卡。

## 推荐下一步（按优先级）

### 1. 先做一次人工回归和问题清单

从 F5 开始验证：新游戏 → 移动 → 翻地 → 播种 → 浇水/打水 → Enter 睡觉 → 收获 → Tab 背包拖拽 → B 商店 → C 图鉴 → E 进入家/厨房 → Esc 暂停菜单 → K/L 存读档。发现问题先记录复现步骤，不要同时改多个系统。

### 2. 建立新的 Git 快照

在确认上述流程稳定后，把 T69-T86 的改动整理成一个清晰提交，例如“visual polish, interiors and inventory drag”，并创建新 tag。提交前检查不要把临时截图或无关 `tmp/` 文件带进去。

### 3. 优先做地图分层美术化

把当前整图背景逐步拆成地面 Tile、房屋/池塘/树木装饰、农田动态层和碰撞层。这样季节色调、作物显示、NPC 移动和地图扩展会更稳，也更容易替换素材。

### 4. 补齐角色选择和 NPC 内容

当前已有男女主角素材方向，但还没有正式的开局角色选择流程。若确定男女主都可玩，新增一个独立任务：主菜单“新游戏”→角色选择→写入玩家外观配置→进入世界；不要把外观选择散落到 Player 脚本中。

### 5. 最后再做料理/食物扩展

确认 T40-T41 的实际任务卡和现有 Recipe/Item/Buff 结构后，再实现食用、Buff HUD、食谱解锁和存档，避免与当前 UIStateManager、背包拖拽和商店面板冲突。

## 交接时建议的第一句话

> 继续开发 `C:\Users\24623\project-sprout`。先读取 `docs/HANDOFF_CONTEXT.md`、`docs/README.md`、`docs/TECH_DESIGN.md`、`docs/BACKLOG.md`，保留当前未提交改动；先做输入和主流程回归，再按优先级处理下一项，不要重置工作树。
