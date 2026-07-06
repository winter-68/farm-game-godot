# T3：世界瓦片地图（地面层 + 农田层占位）

> 通用约束见 [../README.md](../README.md)。若引擎为 4.2 无 `TileMapLayer`，改用 `TileMap` 的两个 layer 并在注释说明。

## 任务目标

给 `world.tscn` 加入两层 `TileMapLayer`：`GroundLayer`（绿色地面）与 `FarmLayer`（初始空，供后续显示耕地/浇水）。铺一块可见的地面区域，并加一个 `CropsRoot` 空节点用于放作物。

## 需要创建/修改的文件

- 修改 `scenes/world/world.tscn`：增加 `GroundLayer`、`FarmLayer`（TileMapLayer）、`CropsRoot`（Node2D）。
- 创建占位 `TileSet` 资源 `resources/tiles/placeholder_tileset.tres`（至少：地面绿、耕地棕、湿耕地深棕 三种图元）。

## 不要修改的文件

- `player.gd`、autoload、数据类。

## 实现要求

1. `GroundLayer` 铺一片地面（如 `20×12` cell，`16×16` 像素）。
2. `FarmLayer` 在 `GroundLayer` 之上（渲染顺序更高），初始不放任何 cell。
3. TileSet 至少 3 个图元，并**约定 atlas 坐标常量**（在注释里写明）：`GROUND=(0,0)`、`TILLED=(1,0)`、`WATERED=(2,0)`，供 T5/T9 使用。
4. 层级顺序：`GroundLayer`(底) < `FarmLayer` < `CropsRoot` < `Player`。

## 验收标准

- 运行可见一块绿色网格地面，玩家在其上移动。
- `FarmLayer` 存在且为空；`CropsRoot` 存在。
- 无报错。

## Godot 测试步骤

1. 运行，确认地面显示、玩家可在地面范围移动。
2. 在编辑器检查节点树含 `GroundLayer/FarmLayer/CropsRoot`。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3）为 world 场景加入瓦片地图。

1) 创建占位 TileSet：resources/tiles/placeholder_tileset.tres，tile 尺寸16x16，
   至少含3个图元：地面(绿)、耕地(棕)、湿耕地(深棕)。可用纯色 PlaceholderTexture2D 或
   一张自建的小色块图集。明确 atlas 坐标：GROUND=(0,0)、TILLED=(1,0)、WATERED=(2,0)。
2) 修改 scenes/world/world.tscn，在 World(Node2D) 下增加：
   - GroundLayer(TileMapLayer)：使用该 TileSet，铺满约20x12格的地面(GROUND)。
   - FarmLayer(TileMapLayer)：同一 TileSet，初始为空。渲染在 GroundLayer 之上。
   - CropsRoot(Node2D)：空节点，供后续放作物。
   保证节点顺序为 Ground < Farm < CropsRoot < Player，使 Player 显示在最上层。

约束：不要修改 player.gd 或任何 autoload/数据类。若 Godot 版本为4.2无 TileMapLayer，
则改用 TileMap 的两个 layer 并在注释说明。运行后可见绿色地面网格，玩家可在其上移动，无报错。
```
