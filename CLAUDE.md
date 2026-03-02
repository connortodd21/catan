# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A **Godot 4** project implementing a Catan board editor. The primary feature is an interactive tool to place terrain tiles and number tokens on a hex grid, with support for random board generation, save/load to JSON.

## Running the Project

Open the project in Godot 4 and run the main scene (`scenes/main.tscn`). There are no CLI build commands — everything is done through the Godot editor. The active board editor scene is `scenes/board_editor_v_2.tscn`.

> Note: `scenes/board_editor.tscn` and `scripts/board_editor/` are an older v1 implementation. The active codebase lives in `scripts/board_editor_v2/`.

## Architecture

### Hex Coordinate System

The project uses two coordinate systems:

- **Axial (q, r)** — primary internal coordinate system used throughout scripts, caches, and serialization. `Vector2i(q, r)`.
- **Offset (odd-r)** — used by Godot's `TileMapLayer`. Converted via `HexUtils.axial_to_offset()` / `offset_to_axial()`.

All hex math algorithms follow [redblobgames.com/grids/hexagons](https://www.redblobgames.com/grids/hexagons). Conversions live in `scripts/utils/hex_utils.gd`.

### EditorState Singleton (`scripts/singletons/editor_state.gd`)

The global state manager. All inter-component communication flows through this autoload singleton via signals:
- `board_generate_requested(config)`, `board_cleared`, `board_saved`, `board_load`
- `tile_selected(tile_id)`, `number_selected(number)`
- Tracks `SelectionType` enum (NONE / TERRAIN / NUMBER) and the currently selected tile/number.

### Board Editor V2 (`scripts/board_editor_v2/board_editor_v_2.gd`)

The root scene script. Manages two `TileMapLayer` nodes (terrain and numbers) and two `TypedCache` instances:
- `tile_metadata_cache: TypedCache` — keyed by axial `Vector2i`, values are `TileMetadata`
- `number_metadata_cache: TypedCache` — keyed by axial `Vector2i`, values are `NumberMetadata`

Input handling converts mouse position → offset coords → axial coords before calling `place_tile()` / `place_number()`.

### TypedCache (`scripts/cache/typed_cache.gd`)

A type-safe dictionary wrapper built on `BaseCache`. Enforces key type (Godot `Variant.Type`) and value class at get/set time. Used as the source of truth for board state.

### Board Generation (`scripts/board_editor_v2/board_generator/`)

`BoardGenerator` (static class) generates a `SerializedBoard` from a `GenerationConfig`:
1. `_generate_coords()` — produces axial coords for the chosen shape (CIRCLE, SQUARE, RECTANGLE, OVAL)
2. `_assign_tiles()` — fills coords with terrain types, validated by the active `RuleSet`
3. `_assign_numbers()` — recursive backtracking algorithm to assign numbers to non-desert tiles

`GenerationConfig` holds shape, radius/dimensions, seed, allowed tiles, and a `RuleSet`.

### Rule System (`scripts/board_editor_v2/rule_sets/`)

- `BoardRule` — base `Resource` class with `validate(coord, number, tile, tile_map, number_map) -> bool`
- `RuleSet` — holds an array of `BoardRule` resources, calls all rules in sequence
- `RuleRegistry` — registers available rules
- Concrete rules in `rules/`: `NoAdjacentSameNumbersRule`, `NoAdjacentSameTileRule`, `No2_12TouchingRule`, `No6_8TouchingRule`

To add a new rule: extend `BoardRule`, implement `validate()` and `get_rule_name()`, register it.

### Serialization (`resources/serialization/`, `scripts/board_editor_v2/board_serializer.gd`)

- `SerializedBoard` — holds `Array[TileEntry]` and `Array[NumberEntry]`, serializes to/from JSON dict
- `BoardSerializer` — converts the two `TypedCache` objects into a `SerializedBoard`; computes bounding rect to normalize coordinates
- `SaveManager` — wraps Godot's `FileDialog` for save/load of JSON (`.json`) and resource (`.tres`) formats

### Data Resources (`resources/`)

- `TerrainDatabaseResource` / `NumberDatabaseResource` — `Resource` classes holding arrays of `TerrainDataResource` / `NumberDataResource`, exported in the editor and injected into the board editor and panel via `@export`
- `terrain_database.tres` / `number_database.tres` — the actual data files with textures, atlas coords, and source IDs

### UI Panel (`scripts/board_editor_v2/editor_panel.gd`)

Generates terrain and number buttons dynamically from the database resources. Calls `EditorState` methods on button press. The "Generate Board" button opens `board_generation_window` (a `Window` node with `board_generation_window.gd`).

## Key Conventions

- Coordinates stored and passed as `Vector2i(q, r)` in axial space; convert to offset only when calling TileMapLayer methods.
- New terrain types must be added to `TerrainTypes.Type` enum and `tile_type_to_str` map.
- New board shapes must be added to `Shapes.Type` enum and handled in `BoardGenerator._generate_coords()`.
- `TypedCache` enforces types at runtime — mismatches push errors, not exceptions.
