# GameConfigPanel Refactor

## Goal

Extract the board + options portion of `game_select.tscn` into a reusable `GameConfigPanel`
subscene so that both the local game setup and the multiplayer lobby can share the same
board selection and game options UI without duplicating code.

## Background

`game_select.tscn` currently owns three panels in a single `HSplitContainer`:
- **PlayerPanel** — player list, color picker, Add Player button, Start button
- **BoardPanel** — board preview list
- **OptionsScroll** — expansions, house rules, victory points

The lobby scene needs an identical board + options UI. Rather than duplicating it,
we extract those two panels into a standalone subscene.

## What Moves Where

| Content | From | To |
|---|---|---|
| `BoardPanel` node tree | `game_select.tscn` | `game_config_panel.tscn` |
| `OptionsScroll` node tree | `game_select.tscn` | `game_config_panel.tscn` |
| `selected_board` var | `game_select.gd` | `game_config_panel.gd` |
| `_generate_board_previews()` | `game_select.gd` | `game_config_panel.gd` |
| `_create_board_preview()` | `game_select.gd` | `game_config_panel.gd` |
| `_generate_expansions()` | `game_select.gd` | `game_config_panel.gd` |
| `_generate_house_rules()` | `game_select.gd` | `game_config_panel.gd` |
| `_on_board_selected()` | `game_select.gd` | `game_config_panel.gd` |
| `victory_points_spinbox` ref | `game_select.gd` | `game_config_panel.gd` |
| Player management, color picker | `game_select.gd` | stays |
| Start / Add Player buttons | `game_select.tscn` | stays |

## New File: `game_config_panel.gd`

Path: `scripts/scenes/game_config_panel/game_config_panel.gd`

### Public interface

```gdscript
signal board_changed(board: SerializedBoard)  # emitted when selection changes (null if deselected)

var interactive: bool:                         # false = all controls disabled (non-host in lobby)
    set(value):
        interactive = value
        _set_controls_interactive(value)

var selected_board: SerializedBoard            # read by parent to validate Start button

func apply_to_config(config: GameConfig) -> void  # writes board, expansions, house rules, VP onto config
```

### Internal

- `_generate_board_previews()`, `_create_board_preview()` — same logic as current game_select.gd
- `_generate_expansions()`, `_generate_house_rules()` — same logic
- `_set_controls_interactive(value: bool)` — enables/disables board list buttons, checkboxes, spinbox
- `_on_board_selected(button)` — sets `selected_board`, emits `board_changed`

## New File: `game_config_panel.tscn`

Path: `scenes/game_config_panel.tscn`

```
GameConfigPanel (HSplitContainer)  ←  game_config_panel.gd
├── BoardPanel (VBoxContainer)
│   ├── BoardLabel
│   └── BoardScroll
│       └── BoardList
└── OptionsScroll (ScrollContainer)
    └── OptionsPanel (VBoxContainer)
        ├── ExpansionsLabel
        ├── ExpansionList
        ├── SepVP
        ├── VictoryPointsHeader
        ├── VictoryPointsRow
        │   ├── VPLabel
        │   └── VictoryPointsSpinBox
        ├── SepHR
        ├── HouseRulesLabel
        └── HouseRuleList
```

## Updated: `game_select.tscn`

- Remove `BoardPanel` and `OptionsScroll` from `Body` HSplitContainer
- Add instance of `game_config_panel.tscn` in their place
- `PlayerPanel` is untouched

## Updated: `game_select.gd`

- Add `@onready var config_panel: GameConfigPanel`
- Connect `config_panel.board_changed` → `_update_start_button()`
- `_update_start_button()` reads `config_panel.selected_board` instead of local var
- `_on_start_game_button_pressed()` calls `config_panel.apply_to_config(config)` instead of inline logic
- Remove all board/options methods (moved to config panel)

## Files Changed

| File | Status |
|---|---|
| `scripts/scenes/game_config_panel/game_config_panel.gd` | New |
| `scenes/game_config_panel.tscn` | New |
| `scenes/game_select.tscn` | Modified |
| `scripts/scenes/game_select/game_select.gd` | Modified |

## Out of Scope

- Lobby scene and lobby player panel (separate task)
- Any changes to local game flow — behavior stays identical from the outside
