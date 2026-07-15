# T20：季节限制种植 + 商店季节过滤

> 通用约束见 [../README.md](../README.md)。批次 D 第 3 个任务。

## 任务目标

实现季节限制：播种时检查当前季节是否允许；商店购买区只显示当季可种的种子（全季节作物始终显示）。不符合季节的种植操作无效且不报错。

## 需要创建/修改的文件

- 修改 `scripts/autoload/farm_manager.gd`：`plant()` 增加季节检查。
- 修改 `scripts/ui/shop_ui.gd`：`_refresh_buy()` 按当前季节过滤种子。

## 不要修改的文件

- `event_bus.gd`、`time_manager.gd`、`inventory_manager.gd`、`save_manager.gd`、数据类、其他 UI 脚本、场景、`player.gd`。

## 实现要求

1. **`FarmManager.plant()`**：
   - 现有检查（tilled / crop_id 空 / 背包有种子）之后，增加季节检查：
     ```gdscript
     var allowed := crop_data.allowed_seasons
     if not allowed.is_empty() and not allowed.has(TimeManager.get_season_name()):
         return  # 季节不符，静默返回
     ```
   - 只有通过季节检查才 `remove_item` + 种植
2. **`ShopUI._refresh_buy()`**：
   - 遍历 `ItemDatabase.get_all_items()` 时，对 `type==SEED` 的物品增加季节过滤：
     ```gdscript
     if item.type == ItemData.Type.SEED:
         var crop := ItemDatabase.get_crop(item.linked_crop_id)
         if crop != null:
             var allowed := crop.allowed_seasons
             if not allowed.is_empty() and not allowed.has(TimeManager.get_season_name()):
                 continue  # 季节不符，跳过
     ```
   - `buy_price > 0` 检查保持不变（产出物不显示）

## 验收标准

- **春季**：
  - 商店购买区显示：绿豆/土豆/草莓种子（番茄不显示）
  - 可种绿豆/土豆/草莓；尝试种番茄种子（如果有）→ 无效果、不扣种子、不报错
- **夏季**（睡觉跨到第 29 天）：
  - 商店购买区显示：绿豆/番茄种子（土豆/草莓消失）
  - 可种绿豆/番茄；尝试种土豆/草莓种子（如果有）→ 无效果
- **秋季**：土豆回归、番茄/草莓消失
- **冬季**：只有绿豆（全季节）
- 存读档后季节限制仍正确。
- 无报错。

## Godot 测试步骤

1. F5 新游戏（春季）→ B 开商店 → 确认只有绿豆/土豆/草莓种子。
2. 买番茄种子（商店不显示，可通过 debug 手动 `add_item` 测试）→ 种植 → 无效果。
3. 睡觉 28 次跨夏 → 商店刷新 → 只有绿豆/番茄种子。
4. 买番茄种子 → 可正常种植。
5. K 存档 → L 读档 → 季节/商店过滤仍正确。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）实现季节限制种植 + 商店过滤。

1) scripts/autoload/farm_manager.gd.plant()：
   在现有检查通过、拿到 crop_data 后，增加：
     var allowed := crop_data.allowed_seasons
     if not allowed.is_empty() and not allowed.has(TimeManager.get_season_name()):
       return
   只有季节检查通过才执行 remove_item + 种植。
2) scripts/ui/shop_ui.gd._refresh_buy()：
   for item in ItemDatabase.get_all_items():
     if item.buy_price <= 0: continue
     if item.type == ItemData.Type.SEED:
       var crop := ItemDatabase.get_crop(item.linked_crop_id)
       if crop != null:
         var allowed := crop.allowed_seasons
         if not allowed.is_empty() and not allowed.has(TimeManager.get_season_name()):
           continue
     buy_list.add_child(_make_buy_row(item))

约束：不要修改 event_bus.gd、time_manager.gd、inventory_manager.gd、save_manager.gd、
数据类、其他 UI 脚本、场景、player.gd。
完成后：春季商店只显示绿豆/土豆/草莓种子，夏季显示绿豆/番茄种子，跨季非法种植无效果，无报错。
```
