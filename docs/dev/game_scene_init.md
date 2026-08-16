# Game Scene Network Init — Design Doc

## Overview

This document covers **Step 3** from `multiplayer_architecture.md`: transitioning all peers from the lobby into the game scene and initializing shared game state over the network.

The primary work is splitting the current monolithic `game.gd` into two cooperating nodes:
- **`GameServer`** — authority, runs on host only. Owns all game state and logic.
- **`GameClient`** — rendering + input, runs on all peers including host.

All in-game communication follows a strict request/notify RPC pattern. Local games continue to work via Godot's offline multiplayer mode — no Steam peer needed, RPCs execute as local calls.

---

## Connection Setup

When the host clicks **Start Game**:

1. Host calls `NetworkManager.start_multiplayer_session()` — creates a `SteamMultiplayerPeer` as host, assigns to `multiplayer.multiplayer_peer`
2. Host sets `game_starting=true` in Steam lobby metadata — all clients receive `lobby_data_update`
3. Each client's `NetworkSignals.game_starting` fires → calls `NetworkManager.join_multiplayer_session(host_steam_id)` — creates `SteamMultiplayerPeer` as client
4. Clients connect → host's `peer_connected` fires per client
5. Once all expected peers are connected, host calls `notify_game_start` RPC → all peers transition to game scene

For **local games**: no `SteamMultiplayerPeer` is created. Godot offline mode means all RPCs execute as local function calls — no special-casing needed.

---

## Player Identity

```
Steam ID → peer_id (Godot) → player_index (0–3)
```

Mapping is established during `notify_game_start`:
- Host is always peer_id 1 → player_index 0
- Other clients get peer_ids assigned by `SteamMultiplayerPeer` on connect, assigned player_index in lobby join order

`NetworkManager` gains:
- `local_player_index: int`
- `peer_to_player_index(peer_id: int) -> int`
- `player_index_to_peer_id(player_index: int) -> int`

---

## Scene Structure

**Before:**
```
Game (root)  ← game.gd  [855 lines, everything]
```

**After:**
```
Game (root)        ← game.gd  [~40 lines, thin coordinator]
├── GameServer     ← game_server.gd  [authority logic, dormant if not host]
└── GameClient     ← game_client.gd  [rendering + input, active on all peers]
```

`game.gd` responsibilities after refactor:
- Receives `game_config` from lobby
- On `_ready()`: activates `GameServer` if host, always activates `GameClient`
- Handles top-level scene transition (game over → return to lobby)

---

## GameServer Responsibilities

Owns all authority and state:
- `board_state`, `turn_manager`, `card_manager`, `setup_manager`
- `player_states` (all players' full hands, scores, army sizes, road lengths, etc.)
- `_draw_piles` (dev card deck)
- All game logic: `_distribute_resources`, piece placement validation, title checks, card handlers

Dormant on non-hosts:
```gdscript
func _ready() -> void:
	if not multiplayer.is_server():
		return
	_initialize()
```

Receives `@rpc("any_peer")` requests from clients → validates → mutates state → broadcasts `notify_*` RPCs to all peers.

---

## GameClient Responsibilities

Owns all display and input:
- `board_renderer` and all rendering methods
- All UI nodes: `action_panel`, `hand_manager`, `player_hud`, all popups
- `_unhandled_input` (board clicks → sends request RPCs to server)
- Knows its own `local_player_index` via `NetworkManager.local_player_index`

Receives `@rpc("authority")` notifications from server → updates display → emits local `GameSignals`.

**`local_player` change:** Currently `local_player = player_states[0]` assumes player 0 is always local. After refactor, `GameClient` reads `NetworkManager.local_player_index` on game start and holds a fixed reference for the whole game.

---

## How Syncing Works

**Two directions only:**

### Client → Server (requests)

```gdscript
# In GameServer — receives requests
@rpc("any_peer", "reliable")
func request_roll_dice() -> void:
	var sender_index := NetworkManager.peer_to_player_index(multiplayer.get_remote_sender_id())
	if not _is_valid_action(sender_index):
		return
	var result := _roll_dice()
	notify_dice_rolled.rpc(sender_index, result.d1, result.d2)

# Client sends:
game_server.request_roll_dice.rpc_id(1)  # peer_id 1 = host always
```

### Server → Clients (notifications)

```gdscript
# In GameServer — broadcasts outcome
@rpc("authority", "reliable", "call_local")
func notify_dice_rolled(player_index: int, d1: int, d2: int) -> void:
	pass  # implementation in GameClient

# call_local = also runs on host's GameClient automatically
```

### Private data (one peer only)

Resource distributions sent to one peer only:
```gdscript
notify_hand_updated.rpc_id(target_peer_id, hand_dict)
```

### Local game

Same code paths. With no `multiplayer.multiplayer_peer` set, Godot's offline mode routes all RPCs as local calls. No special-casing.

---

## Request / Notify Pairs

| Client Request | Server Notify |
|---|---|
| `request_roll_dice` | `notify_dice_rolled(player_index, d1, d2)` |
| `request_resolve_dice` | `notify_turn_changed(new_player_index, phase)` |
| `request_place_settlement(vertex_key)` | `notify_settlement_placed(player_index, vertex_key)` |
| `request_place_road(edge_key)` | `notify_road_placed(player_index, edge_key)` |
| `request_place_city(vertex_key)` | `notify_city_placed(player_index, vertex_key)` |
| `request_buy_dev_card` | `notify_dev_card_bought(player_index)` + private `notify_card_drawn(card_type)` |
| `request_play_dev_card(card_type, args)` | `notify_dev_card_played(player_index, card_type)` |
| `request_end_turn` | `notify_turn_changed(new_player_index, phase)` |
| `request_trade_bank(offer, want)` | `notify_trade_completed(player_index)` + private `notify_hand_updated(hand_dict)` |

### Roll dice — two-phase flow

Rolling is split into two RPCs to ensure animation completes before resources are distributed:

1. `request_roll_dice` — server rolls d1/d2, stores result, broadcasts `notify_dice_rolled` to all peers. Phase does not advance yet.
2. All clients animate via `await dice_roller.play_result(d1, d2)`. Only the rolling player's client then sends `request_resolve_dice`.
3. `request_resolve_dice` — server distributes resources (non-7), advances phase, broadcasts `notify_turn_changed`.

**7 rolled — DISCARD phase (Feature I, not yet implemented):**
When a 7 is rolled, `request_resolve_dice` must check if any player holds >7 cards. If so, the server enters a DISCARD phase and waits for all affected players to submit `request_discard` before entering the ROBBER phase. Feature B stubs this as a direct `enter_robber_phase()` call; the full discard gate will be added when Feature I is implemented.

Init (host → all, no client request):
- `notify_game_start(player_assignments, board_json)` — all peers transition to game scene
- `notify_hand_updated(hand_dict)` — sent privately to each player after setup phase

---

## Files Added

| File | Purpose |
|---|---|
| `scripts/scenes/game/game_server.gd` | All authority logic, receives requests, sends notifications |
| `scripts/scenes/game/game_client.gd` | Rendering, UI, input handling, receives notifications |

---

## Files Modified

| File | Change |
|---|---|
| `scripts/scenes/game/game.gd` | Gutted to thin coordinator (~40 lines) |
| `scenes/game.tscn` | Add `GameServer` and `GameClient` child nodes |
| `scripts/networking/network_manager.gd` | Add `SteamMultiplayerPeer` setup + peer↔player_index mapping |
| `scripts/singletons/network_signals.gd` | Add `game_starting` signal |
| `scripts/scenes/multiplayer_game_lobby/multiplayer_game_lobby.gd` | Wire Start button → `NetworkManager.start_multiplayer_session()` |
| `scripts/scenes/main/main.gd` | Listen for `NetworkSignals.game_starting` on client side |

---

## Task Plan

### Connection & Scene Transition

1. Add `game_starting` signal to `NetworkSignals`
2. Add `start_multiplayer_session()` and `join_multiplayer_session(host_steam_id)` to `NetworkManager` — create `SteamMultiplayerPeer` as host / client
3. Add peer↔player_index mapping to `NetworkManager`: `local_player_index`, `peer_to_player_index()`, `player_index_to_peer_id()`
4. Wire Start button in `multiplayer_game_lobby.gd` — `_on_start_button_pressed()` calls `NetworkManager.start_multiplayer_session()`, sets lobby metadata `game_starting=true`
5. Listen for `game_starting` lobby metadata in `lobby_manager.gd` → emit `NetworkSignals.game_starting`
6. Client-side in `main.gd`: connect `NetworkSignals.game_starting` → call `NetworkManager.join_multiplayer_session()` → transition to game scene once connected
7. Add `notify_game_start` RPC to `GameServer` — host sends board config + player assignments to all peers; all transition to game scene
8. **MANUAL TEST (single machine):** Host clicks Start → game scene loads with correct config. Verify no errors. Verify `local_player_index = 0` on host.

### GameServer / GameClient Split

9. Add `GameServer` and `GameClient` as child nodes in `game.tscn`
10. Create `game_client.gd` skeleton — move all `@onready` UI nodes, `board_renderer`, `_unhandled_input`, and rendering methods from `game.gd`
11. Create `game_server.gd` skeleton — move `board_state`, `player_states`, `turn_manager`, `card_manager`, `setup_manager`, `_draw_piles`, and all game logic methods from `game.gd`
12. Refactor `game.gd` to thin coordinator — `_ready()` activates server if host, always activates client; handles game-over transition
13. **MANUAL TEST (local game):** Play a full local game through the new GameServer/GameClient structure. Verify board renders, turns work, resources distribute, win condition fires.

### RPC Wiring

14. Add `@rpc("any_peer")` request methods to `GameServer` — one per client action (roll dice, place piece, etc.)
15. Add `@rpc("authority", "call_local")` notify methods to `GameServer` — one per server outcome
16. Wire each request → validate → mutate → notify round-trip
17. Update `GameClient` to call `game_server.request_*.rpc_id(1)` instead of calling game logic directly
18. **MANUAL TEST (local game):** Full game via RPC round-trips in Godot offline mode. Verify all actions still work correctly.
19. **MANUAL TEST (two machines):** Full multiplayer game — host + clients land in game scene, turns rotate, hands are private, building works, win condition ends game for all peers.
