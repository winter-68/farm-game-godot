# T85：地图美术 PNG 导入

## 目标

把 T84 的地图美化从程序绘制占位升级为实际导入的地图背景 PNG。

## 实现

1. 新增室外地图背景：
   - `assets/sprites/world/exterior_map_art.png`
2. 新增家内部背景：
   - `assets/sprites/world/home_interior_art.png`
3. 新增厨房内部背景：
   - `assets/sprites/world/kitchen_interior_art.png`
4. `World` 使用 `Sprite2D` 显示室外地图背景。
5. 隐藏旧的 `GroundLayer` 绿色底图，仅保留它作为坐标/农田逻辑参考。
6. 家内部/厨房内部使用 `Sprite2D` 显示导入背景。
7. 保留原交互入口、空气墙、农田逻辑和 UI。

## 验收

- 进入游戏后看到导入后的完整室外地图美术，而不是纯色块/绿色格子底图。
- 家门按 E 进入家内部，显示导入后的家内部背景。
- 厨房门按 E 进入厨房内部，显示导入后的厨房背景。
- 农田、钓鱼、打水、商店、睡觉、烹饪等交互仍正常。
