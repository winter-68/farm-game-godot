# T51：正式美术替换预留接口

## 目标

在不引入外部美术素材的前提下，让现有系统具备“有正式贴图就显示正式贴图，没有贴图就安全显示占位色块”的能力，为后续主角、NPC、作物、物品图标替换做准备。

## 实现

1. 新增 `scripts/art/art_defaults.gd`
   - 提供统一的占位贴图生成方法。
   - 提供物品、作物、NPC 的默认占位颜色。
   - 提供 `item_texture()` / `crop_stage_texture()` / `npc_texture()` 入口。

2. 扩展数据类
   - `CropData` 新增 `placeholder_color`。
   - `NPCData` 新增 `sprite_texture` 和 `placeholder_color`。

3. 更新显示逻辑
   - 作物显示优先使用 `stage_textures`；为空时使用占位贴图。
   - NPC 世界小人优先使用 `sprite_texture`；没有时可退回 `portrait`；再没有时使用占位贴图。
   - 图鉴已发现卡片显示物品图标；没有图标时使用占位图标。

## 验收

- 没有正式贴图时，作物、NPC、图鉴不会崩溃。
- 后续给 `.tres` 填入贴图字段后，不需要改逻辑代码即可显示。
- 不新增外部图片、音频或第三方插件。
