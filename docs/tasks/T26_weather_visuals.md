# T26：天气视觉表现（overlay）+ 今日天气提示

> 通用约束见 [../README.md](../README.md)。批次 E（天气系统）第 3 个任务（收尾）。依赖 [T24](./T24_weather_system.md)。

## 任务目标

给天气加**屏幕表现**：下雨/下雪时全屏 overlay 显示占位雨幕/雪花 + 轻微色调；并在每天天气变化时弹出「今日天气」提示（复用季节提示的淡入淡出手法）。纯表现，不碰任何玩法/数据逻辑。

## 架构要点

- overlay 是**表现层**，只监听 `EventBus.weather_changed`，不读写任何管理器状态、不搜别的节点。
- 放在 `UI`（CanvasLayer）下、作为 **HUD 之前的第一个子节点**（先绘制 = 在 HUD 之下），保证雨幕盖住世界但不挡 HUD 文字。
- 视口是 320×180（见 `project.godot`），overlay 用满屏锚点。
- 占位美术：用 `CPUParticles2D`（代码里配置）当雨线/雪点，`ColorRect` 当色调层。正式美术后续替换、不改逻辑。

## 需要创建/修改的文件

- **新建** `scenes/ui/weather_overlay.tscn`
- **新建** `scripts/ui/weather_overlay.gd`
- 修改 `scenes/main/main.tscn`：在 `UI`(CanvasLayer) 下、`HUD` 之前实例化 `WeatherOverlay`

## 不要修改的文件

- 所有 autoload、数据类、其他 UI 脚本/场景、`player.gd`、`world.tscn`。

## 实现要求

### 1) `scenes/ui/weather_overlay.tscn`

极简结构（其余在脚本里代码构建，降低场景手改风险）：

```
WeatherOverlay: Control          # 满屏：anchors 0,0,1,1；mouse_filter = 2 (Ignore)
├─ Tint: ColorRect               # 满屏；color 初始透明 (a=0)；mouse_filter = 2
└─ Notice: Label                 # 顶部居中的「今日天气」提示；初始 visible=false
```

- `Tint` 铺满、`mouse_filter=IGNORE`，不要挡输入。
- `Notice` 摆在屏幕上方居中（例如 anchor 顶部居中、y 偏移 ~20px）。

### 2) `scripts/ui/weather_overlay.gd`

```gdscript
extends Control

const RAIN_TINT := Color(0.25, 0.35, 0.55, 0.18)
const SNOW_TINT := Color(0.75, 0.80, 0.90, 0.14)
const CLEAR_TINT := Color(0.0, 0.0, 0.0, 0.0)

@onready var tint: ColorRect = $Tint
@onready var notice: Label = $Notice

var _particles: CPUParticles2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_particles = CPUParticles2D.new()
	_particles.emitting = false
	add_child(_particles)
	notice.visible = false
	EventBus.weather_changed.connect(_on_weather_changed)
	# 主动拉一次当前天气（overlay 在 new_game/load 的 emit 之后才入场）
	_apply_weather(WeatherManager.current_weather, false)


# 注意：T24 的 weather_changed 是单参 (weather_id: StringName)，天气 ID 是 StringName 常量
# （WeatherManager.WEATHER_RAIN 等），显示名走 WeatherManager.get_weather_name()。
func _on_weather_changed(weather_id: StringName) -> void:
	_apply_weather(weather_id, true)


func _apply_weather(weather_id: StringName, announce: bool) -> void:
	match weather_id:
		WeatherManager.WEATHER_RAIN:
			tint.color = RAIN_TINT
			_setup_rain()
		WeatherManager.WEATHER_SNOW:
			tint.color = SNOW_TINT
			_setup_snow()
		WeatherManager.WEATHER_CLOUDY:
			tint.color = Color(0.1, 0.1, 0.12, 0.10)
			_particles.emitting = false
		_:  # WEATHER_SUNNY
			tint.color = CLEAR_TINT
			_particles.emitting = false
	if announce:
		_show_notice(WeatherManager.get_weather_name())


func _setup_rain() -> void:
	_particles.position = Vector2(160, -8)          # 屏幕上方中央（视口 320×180）
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(180, 4)
	_particles.amount = 80
	_particles.lifetime = 0.7
	_particles.direction = Vector2(0, 1)
	_particles.spread = 4.0
	_particles.gravity = Vector2(0, 300)
	_particles.initial_velocity_min = 180.0
	_particles.initial_velocity_max = 220.0
	_particles.scale_amount_min = 1.0
	_particles.scale_amount_max = 2.0
	_particles.color = Color(0.7, 0.8, 1.0, 0.7)
	_particles.emitting = true


func _setup_snow() -> void:
	_particles.position = Vector2(160, -8)
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(180, 4)
	_particles.amount = 50
	_particles.lifetime = 3.0
	_particles.direction = Vector2(0, 1)
	_particles.spread = 20.0
	_particles.gravity = Vector2(0, 20)
	_particles.initial_velocity_min = 15.0
	_particles.initial_velocity_max = 30.0
	_particles.scale_amount_min = 1.5
	_particles.scale_amount_max = 3.0
	_particles.color = Color(1, 1, 1, 0.85)
	_particles.emitting = true


func _show_notice(weather_name: String) -> void:
	notice.text = "今日天气：%s" % weather_name
	notice.visible = true
	await get_tree().create_timer(2.5).timeout
	notice.visible = false
```

> 注：`_show_notice` 用 `await` + 计时器，与 `hud.gd` 的季节提示同款。天气每天都变，季节边界那天会同时出现「进入 X 季」和「今日天气」两个提示——位置错开即可（季节提示在 HUD 的 `SeasonNotice`，本提示在 overlay 顶部），可接受。

### 3) `scenes/main/main.tscn`

在 `UI`(CanvasLayer) 下实例化 `WeatherOverlay`，且**排在 `HUD` 之前**（成为 UI 的第一个子节点，先绘制在底层）：

```
[ext_resource ... path="res://scenes/ui/weather_overlay.tscn" id="6_weather"]
...
[node name="WeatherOverlay" parent="UI" index="0" instance=ExtResource("6_weather")]
```

（用 `index="0"` 确保它在 HUD/Hotbar/... 之前。）

## 验收标准

- 遇到雨天：屏幕出现自上而下的占位雨线 + 轻微蓝色调；HUD 文字仍清晰可读、不被遮挡、可正常点按。
- 遇到雪天（冬季）：屏幕飘落白色占位雪点 + 轻微冷色调。
- 晴天：无粒子、无色调（干净）。
- 每次跨天天气变化时，屏幕上方短暂弹出「今日天气：X」后自动消失。
- 读档进入雨/雪天：overlay 立即反映当前天气（不必等下一次跨天）。
- overlay 不拦截鼠标（商店/背包/热键仍正常）。
- 无报错。

## Godot 测试步骤

1. F5 → 连睡到雨天，确认雨幕 + 色调 + 顶部提示；点开商店确认不被 overlay 挡。
2. 睡到冬季雪天，确认雪花效果。
3. 晴天确认屏幕干净。
4. 雨天存档 → 读档 → 确认 overlay 立即显示雨。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）加天气视觉 overlay + 今日天气提示。纯表现，不动数据/玩法。

1) 新建 scripts/ui/weather_overlay.gd —— 完整内容见 T26 任务卡实现要求第 2 节，原样照抄。
2) 新建 scenes/ui/weather_overlay.tscn：
   根 Control「WeatherOverlay」满屏(anchors 0,0,1,1)、mouse_filter=Ignore；
   子 ColorRect「Tint」满屏、初始透明、mouse_filter=Ignore；
   子 Label「Notice」屏幕上方居中、初始 visible=false。挂上脚本。
3) scenes/main/main.tscn：在 UI(CanvasLayer) 下实例化 weather_overlay.tscn，节点名 WeatherOverlay，
   放在 HUD 之前（index="0"，先绘制在最底层）。

视口是 320×180。overlay 只监听 EventBus.weather_changed（**单参 weather_id: StringName**），
_ready 里主动拉一次 WeatherManager.current_weather，显示名走 WeatherManager.get_weather_name()；
天气 ID 用 WeatherManager.WEATHER_RAIN/WEATHER_SNOW/WEATHER_CLOUDY 常量匹配。
不读写任何管理器状态、不搜别的节点。雨/雪用代码配置的 CPUParticles2D 当占位。

约束：不要改任何 autoload、数据类、其他 UI 脚本/场景、player.gd、world.tscn。
完成后：雨天有雨幕+蓝调、雪天有雪点+冷调、晴天干净、跨天弹「今日天气」提示、读档立即反映、
overlay 不挡输入与 HUD、无报错。
```
