# T79: Pause Menu And Fullscreen Escape

## Goal

Add an in-game menu opened with `Esc`, especially so fullscreen play has a clear way to exit fullscreen.

## Changes

- Add `scenes/ui/pause_menu.tscn`.
- Add `scripts/ui/pause_menu.gd`.
- Add the pause menu to `scenes/main/main.tscn`.
- `Esc` opens and closes the menu through Godot's built-in `ui_cancel` action.
- The menu pauses gameplay while staying interactive.

## Acceptance

- In fullscreen gameplay, pressing `Esc` opens the game menu.
- `继续游戏` closes the menu and resumes gameplay.
- `退出全屏` switches the window back to windowed mode.
- `返回主菜单` returns to the main menu and unpauses the game.
- `退出游戏` closes the game.
