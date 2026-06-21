# Multiplayer Architecture

## Overview

Listen server model over Steam networking. One player (the host) runs both server
logic and a client. All other players run clients only. Steam SDR handles NAT
traversal — no port forwarding or Tailscale required. Works across the internet.

## Infrastructure

### Steam SDR (Steam Datagram Relay)
Valve's global relay network routes multiplayer traffic between peers. Handles NAT
punchthrough automatically. All players need Steam running in the background.

### Steam CDN (distribution)
Game binary hosted and distributed via Steam. Friends install through their Steam
library using a key you generate. Store page stays Private — invisible to the public.
Keys grant access regardless of store visibility.

### Development vs Production
- **Local dev**: Run from Godot editor, App ID 480 (Valve's Spacewar test app), no binary needed
- **Friends testing**: Register on Steamworks ($100 one-time), real App ID, export binary, distribute keys
- **Never required**: Public store page, public release

## Network Topology

```
Host Machine (runs game logic + renders for self)
├── GameServer  — owns all authority, validates actions, mutates state
└── GameClient  — renders board, handles input, displays HUD

Remote Client (renders only)
└── GameClient  — renders board, handles input, displays HUD
```

All peers communicate through Steam SDR. Even the host routes its own client
requests through RPCs to the server — no special-casing the host anywhere.

## Scene Structure

```
Game (root node)  ←  game.gd  [thin coordinator, ~30-40 lines]
├── GameServer    ←  game_server.gd  [dormant on non-host peers]
└── GameClient    ←  game_client.gd  [active on all peers]
```

`game.gd` responsibilities:
- Receives session config from lobby (board choice, player list)
- Activates GameServer if this peer is the host
- Always activates GameClient
- Handles top-level transitions (game over → return to lobby)
- No game logic

## State Ownership

| State | Owner | Notes |
|---|---|---|
| `board_state` | Server | Changes broadcast as events, never sent wholesale |
| `player_states` | Server | Each client only receives their own resource hand |
| `turn_manager` | Server | Clients are told whose turn it is |
| `card_manager` (deck) | Server | Clients never see deck contents |
| `game_stats` | Server | Broadcast on turn change |
| `board_renderer` | Client | Purely visual |
| `player_hud` | Client | Reads from locally synced state |
| `hand_manager` | Client | Only receives local player's hand |
| `activity_log` | Server generates entries, all clients display |
| `GameSignals` | Local on every machine | Emitted after state change (server) or after RPC received (client) |

**Resource privacy**: Server sends hand updates only to the owning peer via
`rpc_id(peer_id, ...)`. Other players receive card counts only — not types.

## RPC Pattern

Two directions only.

### Client → Server: requests (intent)
Clients express what they want to do. Server decides if it happens.

```
request_build_settlement(pos)
request_build_road(pos)
request_build_city(pos)
request_buy_development_card()
request_play_card(card_type, metadata)
request_roll_dice()
request_move_robber(hex_pos, victim_peer_id)
request_bank_trade(offered, requested)
request_end_turn()
```

### Server → All clients: notifications (outcome)
Server broadcasts what actually happened. Clients never assume their request succeeded.

```
notify_piece_placed(player_index, piece_type, pos)
notify_dice_rolled(player_index, total)
notify_resources_updated(peer_id, hand)        # sent to one peer only
notify_hand_size_updated(player_index, count)  # sent to all (count only, not types)
notify_card_drawn(player_index)                # no card type revealed
notify_card_played(player_index, card_type)
notify_resource_stolen(thief_index, victim_index, resource)  # resource sent to thief only
notify_turn_changed(player_index)
notify_score_changed(player_index, score)
notify_title_changed(title, new_holder_index, prev_holder_index)
notify_activity_entry(bbcode)                  # pre-rendered on server, sent as string
notify_game_over(winner_index)
```

## Host-as-Player Flow

The host goes through the same RPC path as any remote client:

```
Host input
  → GameClient.request_build_settlement(pos)   [rpc_id(1, ...)]
  → GameServer validates, mutates board_state
  → GameServer.notify_piece_placed(...)         [rpc to all, call_local]
  → All GameClients update display
  → All GameClients emit local GameSignals
```

One code path for everyone. No `if is_server` branches inside game logic.

## Player Identity

```
Steam ID  →  peer_id (Godot multiplayer)  →  player_index (0–3)
```

Server maintains this mapping. On every incoming request:

```gdscript
var sender := multiplayer.get_remote_sender_id()
var player_index := network_manager.peer_to_player_index(sender)
if player_index != turn_manager.current_player_index:
    return  # not your turn, ignore
```

## Lobby Flow

```
Main Menu
└── Multiplayer
    ├── Host Game
    │   ├── Create Steam lobby
    │   ├── Lobby screen: players join, pick color/name
    │   └── Start Game (host only, min 2 players)
    └── Join Game
		├── Steam overlay shows friend's lobby
		└── Lobby screen: see players, pick color/name, wait for host
```

On "Start Game":
1. Server sends `notify_game_start(board_config, player_assignments)` to all clients
2. All machines transition to game scene
3. Server initializes board state
4. Server sends each client their initial hand via `notify_resources_updated`
5. Server sends board layout to all via `notify_board_layout`

## Disconnection Handling

For now: any peer disconnect ends the session. Server broadcasts `notify_game_over`
with no winner and shows a "player disconnected" message on all clients.

Host migration (transfer authority if host leaves) is explicitly out of scope.

## New Files

| File | Purpose |
|---|---|
| `scripts/network/lobby_manager.gd` | Steam lobby creation, joining, peer management |
| `scripts/network/network_manager.gd` | peer↔player_index mapping, connection state |
| `scripts/scenes/lobby/lobby.gd` | Lobby UI logic |
| `scenes/lobby.tscn` | Lobby scene |
| `scenes/multiplayer_menu.tscn` | Host / Join choice screen |

## Modified Files

| File | Change |
|---|---|
| `game.gd` | Becomes thin coordinator, delegates to GameServer/GameClient |
| `game_server.gd` | New — split from game.gd, all authority logic |
| `game_client.gd` | New — split from game.gd, all display/input logic |
| `action_panel.gd` | Sends RPC requests instead of calling game directly |
| `scenes/game.tscn` | Adds GameServer and GameClient child nodes |
| `scenes/main_menu.tscn` | Adds Multiplayer button |

## Unchanged

Everything below the game layer is network-unaware and stays as-is:

- `board_state.gd`, `board_renderer.gd`
- `player_state.gd`, `player_hud.gd`
- `turn_manager.gd`, `card_manager.gd`
- `activity_log.gd`, `activity_entry.gd`
- `game_stats.gd`, all stat classes
- `GameSignals` singleton
- All models, utilities, renderers

## Implementation Order

1. GodotSteam install + basic Steam connection (two instances see each other)
2. Lobby screen (player list, color/name, start button)
3. Game scene init over network (board layout, player assignments)
4. Turn flow (roll dice, end turn, turn change notification)
5. Building (settlements, roads, cities)
6. Resources (collection, hand privacy, bank trades)
7. Dev cards (buy, play each type)
8. Robber (move, steal with resource privacy)
9. Win condition (game over broadcast)
10. Disconnection handling
