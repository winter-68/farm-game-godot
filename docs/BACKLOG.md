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

## 批次 C：经济、UI 与存档 ✅（任务卡已就绪）

| ID | 任务 | 任务卡 |
|----|------|--------|
| T12 | 背包 UI 面板（查看/整理） | [T12](./tasks/T12_inventory_panel.md) |
| T13 | 商店 UI：出售产出物 | [T13](./tasks/T13_shop_sell.md) |
| T14 | 商店：购买种子 | [T14](./tasks/T14_shop_buy.md) |
| T15 | SaveManager 保存全部状态 | [T15](./tasks/T15_save.md) |
| T16 | 读取存档并重建世界/UI | [T16](./tasks/T16_load.md) |
| T17 | 主菜单：新游戏 / 继续 / 退出（收尾） | [T17](./tasks/T17_main_menu.md) |

**里程碑 C（MVP 完成）**：完整核心循环 + 经济 + 存档，达成 GDD 第 9 节 Vertical Slice 验收。
