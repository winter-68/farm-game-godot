# Project Sprout 美术规格与素材流程

本文档用于约定 Project Sprout 后期正式美术素材的尺寸、命名、目录和替换流程。当前阶段仍以占位色块为主；正式素材进入项目前，优先按这里的规格准备。

## 1. 总体风格

- 类型：2D 像素风农场经营游戏。
- 画面气质：温暖、清爽、轻松，偏童话小镇感。
- 线条：低分辨率像素边缘，尽量避免抗锯齿。
- 色彩：中高明度、低到中等饱和度；春夏偏鲜亮，秋冬偏柔和。
- 视角：俯视偏正交，不做复杂透视。
- 动画原则：少帧数、清楚读动作。优先保证可读性，不追求过度细节。

## 2. 推荐尺寸

| 类型 | 推荐尺寸 | 说明 |
| --- | --- | --- |
| 地图瓦片 | 16×16 px | 与当前 TileMap 约定一致。 |
| 主角行走小人 | 16×24 px 或 16×32 px | 先用 16×24，若发型/帽子复杂再升到 16×32。 |
| NPC 行走小人 | 16×24 px 或 16×32 px | 与主角保持同规格，方便复用动画。 |
| 对话头像 | 64×64 px | 用于 DialogueUI，后期可加表情变体。 |
| 物品图标 | 16×16 px | 快捷栏、背包、商店共用。 |
| 作物阶段图 | 16×16 px | 每个阶段一张，空贴图可用占位色块替换。 |
| 鱼图标 | 16×16 px | 背包、商店、图鉴共用。 |
| 料理图标 | 16×16 px | 背包、料理图鉴、厨房 UI 共用。 |
| 建筑外观 | 48×48 px 起 | 房子、商店、厨房可按 16px 网格扩展。 |
| 天气粒子 | 2×4 px / 2×2 px | 雨线、雪点优先简单清楚。 |

## 3. 角色外貌拆分建议

正式角色素材建议先做“整张角色图”，不要一开始就做复杂换装系统。后续如果需要换装，再拆层。

第一阶段角色资源：

- 主角：默认外貌 1 套。
- NPC：每个 NPC 1 套行走小人 + 1 张头像。
- 每个角色至少包含：
  - 4 向站立：down / up / left / right
  - 4 向走路：每方向 2～4 帧

后期可扩展拆分层：

- body：身体和肤色
- hair：发型
- outfit：衣服
- accessory：帽子、发夹、眼镜等
- portrait_expression：头像表情

## 4. 命名规则

统一使用小写英文、下划线，不使用中文文件名。

### 角色

```text
player_walk_down.png
player_walk_up.png
player_walk_left.png
player_walk_right.png

npc_villager_a_walk_down.png
npc_villager_a_portrait_neutral.png
npc_villager_a_portrait_happy.png
```

### 物品

```text
item_seed_potato.png
item_produce_potato.png
item_food_baked_potato.png
item_fish_carp.png
item_bait_quality.png
item_rod_iron.png
```

### 作物

```text
crop_potato_stage_0.png
crop_potato_stage_1.png
crop_potato_stage_2.png
crop_tomato_stage_0.png
```

### 地图瓦片

```text
tiles_farm_ground.png
tiles_buildings.png
tiles_water.png
```

### UI

```text
ui_button_normal.png
ui_button_hover.png
ui_panel_wood.png
ui_icon_heart.png
```

## 5. 推荐目录

```text
assets/
  sprites/
    characters/
      player/
      npcs/
    portraits/
    crops/
    items/
    fish/
    food/
    tiles/
    buildings/
    weather/
  ui/
    icons/
    panels/
  source/
    aseprite/
    references/
```

说明：

- `assets/sprites/` 放游戏实际使用的导出 PNG。
- `assets/source/` 放可编辑源文件，例如 Aseprite 文件、分层源文件、参考图说明。
- Godot 资源 `.tres` 仍放在 `resources/`，图片贴图放在 `assets/`。

## 6. Godot 导入设置

像素素材导入后建议：

- Filter：关闭
- Mipmaps：关闭
- Repeat：关闭，除非是明确要平铺的纹理
- Texture compression：避免有损压缩
- 缩放：尽量用整数倍

Project 设置建议继续保持：

- 低分辨率视口。
- 整数缩放。
- 不使用模糊滤镜。

## 7. 替换流程

正式素材进入项目时，按这个顺序替换：

1. 先替换物品图标。
   - 风险最低。
   - 可以快速改善背包、快捷栏、商店、图鉴。

2. 再替换作物阶段图。
   - 每个作物按 stage_0 / stage_1 / stage_2 / stage_3 准备。
   - 确认空贴图不会导致崩溃的逻辑继续保留。

3. 再替换主角和 NPC 小人。
   - 先站立，再走路。
   - 保持碰撞盒不变，先只换 Sprite。

4. 再替换头像。
   - 对话系统只需要 Texture2D。
   - 每个 NPC 先做 neutral，再扩 happy / sad 等表情。

5. 最后替换地图瓦片和建筑。
   - 地图瓦片对玩法影响大，最后集中调整。
   - 保持 16×16 网格，不要随意改 TileMap 尺寸。

## 8. 人物外貌制作建议

主角第一版建议：

- 轮廓：短发、围裙或工作服，农场主题明显。
- 颜色：头发和衣服用较高对比，方便在绿色地面上看清。
- 动作：走路时手脚小幅摆动即可。

NPC 第一版建议：

- 村民 A：绿色系，温和、园艺感。
- 村民 B：蓝色系，沉稳、钓鱼或商店感。
- 每个 NPC 头像要比行走小人更有性格，因为对话时头像是玩家最容易注意到的地方。

## 9. 不建议现在做的事

- 不要现在做复杂换装系统。
- 不要现在画大量最终地图瓦片。
- 不要混用多种像素比例，例如 16px 角色和 48px 高清图标。
- 不要直接把网上图片塞进项目，版权和风格都会变麻烦。
- 不要在玩法没稳定前大量制作一次性动画。

## 10. 推荐下一步

先做一套“正式美术试切片”：

- 主角 1 套：4 向站立 + 4 向走路。
- NPC 2 个：行走小人 + 头像。
- 物品图标 12 个：种子、作物、鱼、料理、鱼饵、鱼竿。
- 作物图 4 组：绿豆、土豆、番茄、草莓。

这批素材足够判断游戏整体观感，不会过早投入太多沉没成本。
