# T2：玩家移动与相机跟随

> 通用约束见 [../README.md](../README.md)。

## 任务目标

实现玩家 `CharacterBody2D` 的 4 方向移动、记录**面朝方向**（供后续目标瓦片用），相机跟随。用占位方块显示，含一个表示朝向的小指示。

## 需要创建/修改的文件

- 创建 `scenes/world/player/player.tscn`（`CharacterBody2D` + `Sprite2D` 占位 + 朝向指示 + `Camera2D`）。
- 创建 `scripts/world/player.gd`。
- 创建 `scenes/world/world.tscn`（`Node2D`，先只放 `Player` 实例）。
- 修改 `scenes/main/main.tscn`：实例化 `world.tscn`。

## 不要修改的文件

- 任何 autoload 脚本、数据类、`event_bus.gd`。

## 实现要求

1. 移动用 `Input.get_vector("move_left","move_right","move_up","move_down")` + `move_and_slide()`，速度导出变量（默认 `80.0`）。
2. 维护 `facing: Vector2i`（上下左右之一），移动时更新；静止保留上次朝向；默认朝下。
3. 占位：`Sprite2D` 用 `PlaceholderTexture2D`（如 `24×24`）；朝向指示用更小的子 `ColorRect`/`Sprite2D` 放到 `facing` 方向。
4. `Camera2D` 作为 Player 子节点，`enabled = true`，可开启位置平滑。
5. **暂不发任何 use_tool 信号**（T5 再做）。

## 验收标准

- WASD 能上下左右移动，速度稳定，相机跟随。
- 停止移动后 `facing` 保持最后方向；朝向指示随移动方向改变。
- 无报错。

## Godot 测试步骤

1. 运行 `main.tscn`，用 WASD 移动方块，观察相机跟随与朝向指示。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3, GDScript）实现玩家移动与相机。

1) scenes/world/player/player.tscn：根 CharacterBody2D(名 Player)，子节点：
   Sprite2D(用 PlaceholderTexture2D，尺寸24x24，作为占位)、
   一个小的朝向指示子节点(ColorRect 或小 Sprite2D)、Camera2D(enabled)。
2) scripts/world/player.gd 挂到 Player：
   - @export var speed: float = 80.0
   - var facing: Vector2i = Vector2i.DOWN
   - _physics_process: velocity = Input.get_vector("move_left","move_right",
     "move_up","move_down") * speed; move_and_slide()
   - 根据输入方向更新 facing（优先取较大分量；无输入时保持上次 facing）
   - 让朝向指示子节点根据 facing 移到对应偏移位置
3) scenes/world/world.tscn：根 Node2D(名 World)，实例化 Player，放在原点附近。
4) 修改 scenes/main/main.tscn：在 Main 下实例化 world.tscn。

约束：不要修改任何 autoload/数据类/event_bus.gd；这一步不要发送任何 EventBus 信号；
占位贴图用 PlaceholderTexture2D，不引入外部图片。运行后 WASD 可移动、相机跟随、无报错。
```
