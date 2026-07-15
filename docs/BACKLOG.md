# 第一阶段开发 Backlog — Project Sprout

按依赖顺序排列，**每个任务做完项目都应能运行**。分成 3 个批次交给 Codex。

## 批次 A：地基与可移动世界 ✅（任务卡已就绪）

| ID | 任务 | 交付后可验证 | 任务卡 |
|----|------|-------------|--------|
| **T0** | 项目初始化 + 目录 + Autoload 占位 + EventBus | 空项目能运行，无报错 | [T0](./tasks/T0_project_init.md) |
| **T1** | 数据类骨架（ItemData/CropData/FarmTile）+ ItemDatabase 加载 | 控制台打印已加载物品数 | [T1](./tasks/T1_data_classes.md) |
| **T2** | 玩家移动 + 相机跟随 | 方块能上下左右移动，相机跟随 | [T2](./tasks/T2_player_movement.md) |
| **T3** | 世界瓦片地图（地面层 + 农田层占位） | 有一块可见地面网格 | [T3](./tasks/T3_tilemap.md) |
| **T4** | TimeManager 时间系统 + HUD 显示时间/天 | HUD 显示时间在走、可睡觉进下一天 | [T4](./tasks/T4_time_hud.md) |
| **T5** | 目标瓦片指示 + 翻地（锄头） | 站在地上按键把一格变耕地 | [T5](./tasks/T5_till.md) |

**里程碑 A**：可移动、有时间流逝、能睡觉进下一天、能把地翻成耕地。项目始终可运行、可测试。

## 批次 B：核心农事循环 ✅（任务卡已就绪）

| ID | 任务 | 任务卡 |
|----|------|--------|
| T6 | InventoryManager（金币 + 背包槽 + 选中项）+ HUD 金币 | [T6](./tasks/T6_inventory_money.md) |
| T7 | 快捷栏 Hotbar UI（选中工具/种子）→ 替换 T5 中硬编码工具 | [T7](./tasks/T7_hotbar.md) |
| T8 | 播种（消耗种子 → 生成 Crop 实例） | [T8](./tasks/T8_planting.md) |
| T9 | 浇水 | [T9](./tasks/T9_watering.md) |
| T10 | 作物跨天成长（day_passed → 推进 stage） | [T10](./tasks/T10_crop_growth.md) |
| T11 | 收获（产出进背包）+ 睡觉入口收敛到 debug_sleep 键 | [T11](./tasks/T11_harvest.md) |

**里程碑 B**：完成「翻地→播种→浇水→跨天成长→收获」完整农事闭环。

## 批次 C：经济、UI 与存档 ✅（已完成）

| ID | 任务 | 任务卡 |
|----|------|--------|
| T12 | 背包 UI 面板（查看/整理） | [T12](./tasks/T12_inventory_panel.md) |
| T13 | 商店 UI：出售产出物 | [T13](./tasks/T13_shop_sell.md) |
| T14 | 商店：购买种子 | [T14](./tasks/T14_shop_buy.md) |
| T15 | SaveManager 保存全部状态 | [T15](./tasks/T15_save.md) |
| T16 | 读取存档并重建世界/UI | [T16](./tasks/T16_load.md) |
| T17 | 主菜单：新游戏 / 继续 / 退出（收尾） | [T17](./tasks/T17_main_menu.md) |

## 批次 D：更多作物 + 季节系统 ✅（已完成）

| ID | 任务 | 任务卡 |
|----|------|--------|
| T18 | 四季循环 + HUD 显示季节 | [T18](./tasks/T18_season_system.md) |
| T19 | 新作物数据（土豆/番茄/草莓） | [T19](./tasks/T19_new_crops.md) |
| T20 | 季节限制种植 + 商店季节过滤 | [T20](./tasks/T20_season_filter.md) |
| T21 | 跨季提示 + 快捷栏新物品显示 | [T21](./tasks/T21_season_notice.md) |
| T22 | 背包 UI 新物品显示 | [T22](./tasks/T22_inventory_new_items.md) |
| T23 | 经济平衡调整 + 起始资源 | [T23](./tasks/T23_balance.md) |

**里程碑 C（MVP 完成）**：完整核心循环 + 经济 + 存档，达成 GDD 第 9 节 Vertical Slice 验收。

## 批次 E：天气系统 🌧️✅（已完成）

按季节概率每天随机天气；唯一玩法效果=雨天自动浇水（纯正向、无惩罚）。

| ID | 任务 | 任务卡 |
|----|------|--------|
| T24 | WeatherManager（随机+信号+存档）+ HUD 显示天气 | [T24](./tasks/T24_weather_system.md) |
| T25 | 雨天自动浇灌所有耕地（接成长闭环） | [T25](./tasks/T25_rain_autowater.md) |
| T26 | 雨/雪视觉 overlay + 今日天气提示 | [T26](./tasks/T26_weather_visuals.md) |

**架构铁律**：WeatherManager autoload 必须注册在 FarmManager **之后**（保证雨水在 FarmManager 清浇水标记之后补上）；tile 所有权仍归 FarmManager（`water_all_tilled()`）；天气数据/overlay 表现分离，靠 `weather_changed` 信号解耦。

## 批次 F：收集系统 📖✅（已完成）

图鉴（首次收获解锁）+ 成就（里程碑长线目标）。收集类长线动力。

| ID | 任务 | 任务卡 |
|----|------|--------|
| T27 | CollectionManager（图鉴/统计/成就+信号+存档+读档守卫） | [T27](./tasks/T27_collection_manager.md) |
| T28 | 收集面板 UI（图鉴网格 + 成就列表）+ 按键 C | [T28](./tasks/T28_collection_panel.md) |
| T29 | 解锁提示 toast（发现新作物 / 达成成就） | [T29](./tasks/T29_collection_toast.md) |

**架构铁律**：CollectionManager autoload 注册在 WeatherManager 后、SaveManager 前；只读 ItemDatabase/TimeManager、只监听 EventBus，不搜树、不改别的管理器；图鉴按 `type==PRODUCE` 从 `get_all_items()` 枚举，**不动 ItemDatabase**；**读档守卫**——`crop_harvested/money_changed/season_changed` 在读档时也会 emit，CollectionManager 靠 `save_load_started`→`_loading` 期间挂起响应，避免误弹成就。
